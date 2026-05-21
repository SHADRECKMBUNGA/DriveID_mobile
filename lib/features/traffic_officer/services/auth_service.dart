import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_user.dart';

class AuthService {
  static const String _defaultAndroidHost = String.fromEnvironment(
    'ESIGNET_HOST',
    defaultValue: '10.0.2.2',
  );

  static String get localHost {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return _defaultAndroidHost;
    return 'localhost';
  }

  static String get backendBaseUrl => 'http://$localHost:4000';
  static String get authorizationEndpoint => '$backendBaseUrl/login';
  static String get meEndpoint => '$backendBaseUrl/me';
  static String get driverLicenseEndpoint => '$backendBaseUrl/driver/license';
  static String get driverOffensesEndpoint => '$backendBaseUrl/driver/offenses';
  static String get verifyLicenseEndpoint => '$backendBaseUrl/verify/license';

  static String get redirectUri => 'myapp://callback';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _appTokenKey = 'app_jwt_token';
  static const Duration _httpTimeout = Duration(seconds: 8);

  static Uri getLoginUri() => Uri.parse(authorizationEndpoint);

  static Future<http.Response> _backendGet(Uri uri, {required String? token}) async {
    return http
        .get(
          uri,
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        )
        .timeout(_httpTimeout);
  }

  static Future<AppUser?> processBackendSessionToken(String token) async {
    final existingToken = await _storage.read(key: _appTokenKey);
    final incomingIat = _jwtIssuedAt(token);
    final existingIat = existingToken == null ? null : _jwtIssuedAt(existingToken);
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final incomingAgeSeconds =
        incomingIat == null ? null : (nowSeconds - incomingIat).abs();

    // Ignore stale callback intents when we already have an active session.
    // Fresh login callbacks are expected to be very recent.
    if (existingToken != null &&
        incomingAgeSeconds != null &&
        incomingAgeSeconds > 120) {
      debugPrint(
        '[AuthService] Ignoring old callback token age=${incomingAgeSeconds}s',
      );
      return refreshProfileFromBackend();
    }

    // Guard against stale deep links overriding a newer session token.
    if (existingIat != null && incomingIat != null && incomingIat < existingIat) {
      debugPrint(
        '[AuthService] Ignoring stale token incomingIat=$incomingIat existingIat=$existingIat',
      );
      return refreshProfileFromBackend();
    }

    await _storage.write(key: _appTokenKey, value: token);
    return refreshProfileFromBackend();
  }

  static Future<AppUser?> refreshProfileFromBackend() async {
    final token = await _storage.read(key: _appTokenKey);
    if (token == null) {
      debugPrint('[AuthService] No backend token in storage');
      return null;
    }

    try {
      final res = await _backendGet(Uri.parse(meEndpoint), token: token);
      debugPrint('[AuthService] /me status=${res.statusCode}');

      if (res.statusCode == 401 || res.statusCode == 403) {
        debugPrint('[AuthService] /me unauthorized – clearing session');
        await _storage.delete(key: _appTokenKey);
        await _clearStoredUser();
        return null;
      }

      if (res.statusCode != 200) {
        debugPrint('[AuthService] /me body=${res.body}');
        return null;
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      final user = AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
      await _store(user);
      return user;
    } on TimeoutException {
      debugPrint('[AuthService] /me timed out after ${_httpTimeout.inSeconds}s');
      return null;
    } on SocketException catch (e) {
      debugPrint('[AuthService] /me network error: $e');
      return null;
    } catch (e) {
      debugPrint('[AuthService] /me failed: $e');
      return null;
    }
  }

  static Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.user == null) return null;

    return await _getUser(res.user!);
  }

  static Future<AppUser?> get currentUser async {
    final stored = await getStoredUser();
    final token = await appToken;

    if (token != null) {
      final backendUser = await refreshProfileFromBackend();
      if (backendUser != null) {
        debugPrint(
          '[AuthService] currentUser from backend: ${backendUser.id} (${backendUser.role})',
        );
        return backendUser;
      }
      if (stored != null) {
        debugPrint('[AuthService] currentUser from cache (backend unavailable)');
        return stored;
      }
    }

    final session = _supabase.auth.currentSession;
    if (session != null) {
      debugPrint('[AuthService] currentUser from Supabase session: ${session.user.id}');
      return _getUser(session.user);
    }

    debugPrint('[AuthService] currentUser fallback to stored user');
    return getStoredUser();
  }

  static Future<String?> get appToken async {
    return _storage.read(key: _appTokenKey);
  }

  /// License + driver profile for eSignet (backend JWT) sessions.
  static Future<Map<String, dynamic>> fetchDriverLicenseFromBackend() async {
    final token = await appToken;
    if (token == null) {
      throw Exception('Not logged in');
    }

    final http.Response res;
    try {
      res = await _backendGet(Uri.parse(driverLicenseEndpoint), token: token);
    } on TimeoutException {
      throw Exception('Server did not respond. Check that the backend is running.');
    } on SocketException {
      throw Exception('Cannot reach server at $backendBaseUrl');
    }
    debugPrint('[AuthService] /driver/license status=${res.statusCode}');

    if (res.statusCode != 200) {
      debugPrint('[AuthService] /driver/license body=${res.body}');
      String message = 'Failed to load license from server';
      try {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final serverError = body['error']?.toString();
        if (serverError != null && serverError.isNotEmpty) {
          message = serverError;
        }
      } catch (_) {}
      throw Exception(message);
    }

    return json.decode(res.body) as Map<String, dynamic>;
  }

  /// Offenses and fine totals for the logged-in driver (backend JWT).
  static Future<Map<String, dynamic>?> fetchDriverOffensesFromBackend() async {
    final token = await appToken;
    if (token == null) return null;

    try {
      final res = await _backendGet(Uri.parse(driverOffensesEndpoint), token: token);
      debugPrint('[AuthService] /driver/offenses status=${res.statusCode}');

      if (res.statusCode != 200) {
        debugPrint('[AuthService] /driver/offenses body=${res.body}');
        return null;
      }

      return json.decode(res.body) as Map<String, dynamic>;
    } on TimeoutException {
      debugPrint('[AuthService] /driver/offenses timed out');
      return null;
    } on SocketException catch (e) {
      debugPrint('[AuthService] /driver/offenses network error: $e');
      return null;
    }
  }

  /// Lookup any license by number (traffic officer / admin, backend JWT).
  static Future<Map<String, dynamic>?> fetchLicenseForVerification(
    String licenseNumber,
  ) async {
    final token = await appToken;
    if (token == null) return null;

    final uri = Uri.parse(verifyLicenseEndpoint).replace(
      queryParameters: {'number': licenseNumber.trim()},
    );

    http.Response res;
    try {
      res = await _backendGet(uri, token: token);
    } on TimeoutException {
      debugPrint('[AuthService] /verify/license timed out');
      return null;
    } on SocketException catch (e) {
      debugPrint('[AuthService] /verify/license network error: $e');
      return null;
    }
    debugPrint('[AuthService] /verify/license status=${res.statusCode}');

    if (res.statusCode != 200) {
      debugPrint('[AuthService] /verify/license body=${res.body}');
      return null;
    }

    return json.decode(res.body) as Map<String, dynamic>;
  }

  static Stream<AppUser?> get userStream {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      return await _getUser(user);
    });
  }

  static Future<AppUser?> _getUser(User user) async {
    final driver = await _supabase
        .from('drivers')
        .select()
        .eq('auth_user_id', user.id)
        .maybeSingle();

    if (driver != null) {
      return AppUser(
        id: user.id,
        email: user.email ?? '',
        role: 'driver',
        userData: driver,
      );
    }

    final officer = await _supabase
        .from('officers')
        .select()
        .eq('auth_user_id', user.id)
        .maybeSingle();

    if (officer != null) {
      return AppUser(
        id: user.id,
        email: user.email ?? '',
        role: officer['role'] ?? 'traffic_officer',
        userData: officer,
      );
    }

    return getStoredUser();
  }

  static Future<void> _store(AppUser user) async {
    await _storage.write(key: 'user_id', value: user.id);
    await _storage.write(key: 'user_email', value: user.email);
    await _storage.write(key: 'user_role', value: user.role);
    await _storage.write(key: 'user_json', value: json.encode(user.toJson()));
  }

  static Future<AppUser?> getStoredUser() async {
    final userJson = await _storage.read(key: 'user_json');
    if (userJson != null) {
      final decoded = json.decode(userJson) as Map<String, dynamic>;
      return AppUser.fromJson(decoded);
    }

    final id = await _storage.read(key: 'user_id');
    if (id == null) return null;

    final email = await _storage.read(key: 'user_email');
    final role = await _storage.read(key: 'user_role');
    return AppUser(id: id, email: email ?? '', role: role ?? '');
  }

  static Future<void> _clearStoredUser() async {
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_json');
  }

  static Future<void> logout() async {
    await _supabase.auth.signOut();
    await _clearStoredUser();
    await _storage.delete(key: _appTokenKey);
  }

  static int? _jwtIssuedAt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final map = json.decode(payload) as Map<String, dynamic>;
      final iat = map['iat'];
      if (iat is int) return iat;
      if (iat is String) return int.tryParse(iat);
      return null;
    } catch (_) {
      return null;
    }
  }
}