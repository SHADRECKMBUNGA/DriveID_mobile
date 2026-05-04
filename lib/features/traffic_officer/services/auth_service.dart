import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../../../core/models/app_user.dart';


class AuthService {
  static String get localHost {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  static String get baseUrl => 'http://$localHost:8088';
  static const String clientId =
      "IIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhNWtJ";
  static const String scope = "openid profile";

  static String get redirectUri {
    if (kIsWeb) {
      return 'http://localhost:3000/callback';
    }
    if (Platform.isAndroid) {
      return 'myapp://callback';
    }
    return 'myapp://callback';
  }

  static String get authorizationEndpoint => 'http://$localHost:3000/authorize';

  static String get backendVerifyUrl {
    if (kIsWeb) {
      return 'http://localhost:54321/functions/v1/esignet-login';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:54321/functions/v1/esignet-login';
    }
    return 'http://localhost:54321/functions/v1/esignet-login';
  }

  // Generate random state and nonce for each authentication request
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  static String generateState() => _generateRandomString(16);
  static String generateNonce() => _generateRandomString(16);
  static String generateCodeVerifier() => _generateRandomString(64); // 64 chars for PKCE

  static String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static String get tokenEndpoint => '$baseUrl/v1/esignet/oauth/v2/token';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Supabase client
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== SUPABASE AUTH (EMAIL/PASSWORD) ====================
  
  // Sign in with email and password (for Drivers and Traffic Officers)
  static Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in with Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Invalid email or password');
      }
      
      // 2. Get user role and profile from users table
      final appUser = await _getUserWithRole(response.user!);
      
      if (appUser == null) {
        await _supabase.auth.signOut();
        throw Exception('User role not found. Please contact your administrator.');
      }
      
      // 3. Store user info locally
      await _storeUserInfo(appUser);
      
      return appUser;
    } on SocketException {
      throw Exception(
        'Unable to reach Supabase. Check your internet connection or DNS settings and try again.',
      );
    } catch (e) {
      final message = e.toString();
      if (message.contains('Failed host lookup') ||
          message.contains('AuthRetryableFetchException')) {
        throw Exception(
          'Unable to reach Supabase. Check your internet connection or DNS settings and try again.',
        );
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }
  
  // NO SIGN UP FOR DRIVERS - Removed intentionally
  // Drivers must be created by Licensing Officers in the Desktop App

  // ==================== OAUTH PARAMETER MANAGEMENT ====================
  
  static Future<String?> getStoredState() async {
    return await _storage.read(key: 'oauth_state');
  }
  
  static Future<String?> getStoredNonce() async {
    return await _storage.read(key: 'oauth_nonce');
  }
  
  static Future<String?> getStoredCodeVerifier() async {
    return await _storage.read(key: 'oauth_code_verifier');
  }
  
  static Future<void> clearOAuthParams() async {
    await _storage.delete(key: 'oauth_state');
    await _storage.delete(key: 'oauth_nonce');
    await _storage.delete(key: 'oauth_code_verifier');
  }
  
  static Future<bool> validateState(String receivedState) async {
    final storedState = await getStoredState();
    return storedState != null && storedState == receivedState;
  }
  
  static Future<bool> validateCallbackParams(String receivedState, String receivedCode) async {
    // Validate state parameter
    if (!await validateState(receivedState)) {
      return false;
    }
    
    // Additional validation can be added here (e.g., code format validation)
    return receivedCode.isNotEmpty;
  }
  
  static Future<Map<String, String>> getAuthorizationUrlWithParams() async {
    final state = generateState();
    final nonce = generateNonce();
    final codeVerifier = generateCodeVerifier();
    final codeChallenge = generateCodeChallenge(codeVerifier);
    
    // Store state, nonce, and code_verifier for validation during callback
    await _storage.write(key: 'oauth_state', value: state);
    await _storage.write(key: 'oauth_nonce', value: nonce);
    await _storage.write(key: 'oauth_code_verifier', value: codeVerifier);
    
    final url = Uri.parse(authorizationEndpoint).replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scope,
        'state': state,
        'nonce': nonce,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'acr_values': 'mosip:idp:acr:generated-code',
        'ui_locales': 'en',
        'claims_locales': 'en',
      },
    ).toString();
    
    return {
      'url': url,
      'state': state,
      'nonce': nonce,
    };
  }
  
  // Legacy method for backward compatibility
  static String getAuthorizationUrl() {
    // This method is deprecated - use getAuthorizationUrlWithParams() instead
    return Uri.parse(authorizationEndpoint).replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scope,
        'state': generateState(),
        'nonce': generateNonce(),
        'acr_values': 'mosip:idp:acr:generated-code',
        'ui_locales': 'en',
        'claims_locales': 'en',
      },
    ).toString();
  }

  static Future<Map<String, dynamic>?> exchangeCodeForToken(String code, String state) async {
    try {
      // Validate the state parameter
      if (!await validateState(state)) {
        throw Exception('Invalid state parameter - possible CSRF attack');
      }

      final response = await http.post(
        Uri.parse(backendVerifyUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'code': code,
          'state': state,
          'redirect_uri': redirectUri,
        }),
      );

      if (response.statusCode != 200) {
        final result = json.decode(response.body);
        throw Exception(result['error'] ?? 'Failed to verify eSignet callback');
      }

      final result = json.decode(response.body) as Map<String, dynamic>;
      final userData = result['user'] as Map<String, dynamic>?;
      if (userData == null) {
        throw Exception('Invalid response from backend');
      }

      final appUser = AppUser.fromJson(userData);
      await _storeUserInfo(appUser);
      await clearOAuthParams();
      return {'user': appUser.toJson()};
    } catch (e) {
      await clearOAuthParams();
      throw Exception('Network error: $e');
    }
  }

  static Future<AppUser?> processEsignetCallback({
    required String code,
    required String state,
    required String redirectUri,
  }) async {
    if (!await validateCallbackParams(state, code)) {
      throw Exception('Invalid authentication parameters');
    }

    final response = await http.post(
      Uri.parse(backendVerifyUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'code': code,
        'state': state,
        'redirect_uri': redirectUri,
      }),
    );

    if (response.statusCode != 200) {
      final payload = json.decode(response.body);
      throw Exception(payload['error'] ?? 'Authentication failed');
    }

    final payload = json.decode(response.body) as Map<String, dynamic>;
    final userMap = payload['user'] as Map<String, dynamic>?;
    if (userMap == null) {
      throw Exception('Invalid response from backend');
    }

    final appUser = AppUser.fromJson(userMap);
    await _storeUserInfo(appUser);
    return appUser;
  }

  static Future<AppUser?> verifyUin(String uin) async {
    final response = await http.post(
      Uri.parse(backendVerifyUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'uin': uin}),
    );

    if (response.statusCode != 200) {
      final payload = json.decode(response.body);
      throw Exception(payload['error'] ?? 'User verification failed');
    }

    final payload = json.decode(response.body) as Map<String, dynamic>;
    final userMap = payload['user'] as Map<String, dynamic>?;
    if (userMap == null) {
      throw Exception('Invalid response from backend');
    }

    final appUser = AppUser.fromJson(userMap);
    await _storeUserInfo(appUser);
    return appUser;
  }
  
  static Future<AppUser?> _syncESignetUser(Map<String, dynamic> userInfo) async {
    try {
      final uin = userInfo['uin']?.toString() ??
          userInfo['UIN']?.toString() ??
          userInfo['unique_id']?.toString() ??
          userInfo['identity_number']?.toString() ??
          userInfo['sub']?.toString();

      if (uin == null || uin.isEmpty) {
        throw Exception('UIN not provided by eSignet');
      }

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('uin', uin)
          .maybeSingle();

      if (profile == null) {
        throw Exception('User not registered');
      }

      final authUserId = profile['id']?.toString();
      if (authUserId == null || authUserId.isEmpty) {
        throw Exception('Invalid user mapping');
      }

      final driver = await _supabase
          .from('drivers')
          .select()
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      if (driver != null) {
        final license = await _supabase
            .from('licenses')
            .select()
            .eq('driver_id', driver['id'])
            .maybeSingle();

        return AppUser(
          id: authUserId,
          email: driver['email']?.toString() ?? '',
          role: 'driver',
          userData: driver,
          license: license,
        );
      }

      final officer = await _supabase
          .from('officers')
          .select()
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      if (officer != null) {
        return AppUser(
          id: authUserId,
          email: officer['email']?.toString() ?? '',
          role: officer['role']?.toString() ?? 'traffic_officer',
          userData: officer,
        );
      }

      throw Exception('User is not linked to a supported role');
    } catch (e) {
      throw Exception('Failed to sync eSignet user: $e');
    }
  }

  // ==================== USER ROLE & PROFILE ====================
  
  static Future<AppUser?> _getUserWithRole(User authUser) async {
    final role = await _getRoleFromUsersTable(authUser);
    if (role != null) {
      return _buildRoleBasedUser(authUser: authUser, role: role);
    }

    // Fallback for legacy schema where role is inferred from role tables.
    return _getUserWithRoleFromLegacyTables(authUser);
  }

  static Future<String?> _getRoleFromUsersTable(User authUser) async {
    Map<String, dynamic>? userRow;

    try {
      userRow = await _supabase
          .from('users')
          .select('role')
          .eq('id', authUser.id)
          .maybeSingle();
    } catch (_) {
      userRow = null;
    }

    try {
      userRow ??= await _supabase
          .from('users')
          .select('role')
          .eq('auth_user_id', authUser.id)
          .maybeSingle();
    } catch (_) {
      userRow = userRow;
    }

    if (userRow == null) return null;
    final role = userRow['role']?.toString();
    if (role == null || role.isEmpty) return null;
    return role;
  }

  static Future<AppUser?> _buildRoleBasedUser({
    required User authUser,
    required String role,
  }) async {
    if (role == 'driver') {
      final driver = await _supabase
          .from('drivers')
          .select()
          .eq('auth_user_id', authUser.id)
          .maybeSingle();

      final license = driver != null
          ? await _supabase
                .from('licenses')
                .select()
                .eq('driver_id', driver['id'])
                .maybeSingle()
          : null;

      return AppUser(
        id: authUser.id,
        email: authUser.email ?? '',
        role: role,
        userData: driver,
        license: license,
      );
    }

    if (role == 'traffic_officer' || role == 'licensing_officer' || role == 'admin') {
      final officer = await _supabase
          .from('officers')
          .select()
          .eq('auth_user_id', authUser.id)
          .maybeSingle();

      return AppUser(
        id: authUser.id,
        email: authUser.email ?? '',
        role: role,
        userData: officer,
      );
    }

    return AppUser(
      id: authUser.id,
      email: authUser.email ?? '',
      role: role,
    );
  }

  static Future<AppUser?> _getUserWithRoleFromLegacyTables(User authUser) async {
    final driver = await _supabase
        .from('drivers')
        .select()
        .eq('auth_user_id', authUser.id)
        .maybeSingle();

    if (driver != null) {
      final license = await _supabase
          .from('licenses')
          .select()
          .eq('driver_id', driver['id'])
          .maybeSingle();

      return AppUser(
        id: authUser.id,
        email: authUser.email ?? '',
        role: 'driver',
        userData: driver,
        license: license,
      );
    }

    final officer = await _supabase
        .from('officers')
        .select()
        .eq('auth_user_id', authUser.id)
        .maybeSingle();

    if (officer != null) {
      return AppUser(
        id: authUser.id,
        email: authUser.email ?? '',
        role: officer['role'] ?? 'licensing_officer',
        userData: officer,
      );
    }

    return null;
  }
  
  static Future<void> _storeUserInfo(AppUser user) async {
    await _storage.write(key: 'user_id', value: user.id);
    await _storage.write(key: 'user_email', value: user.email);
    await _storage.write(key: 'user_role', value: user.role);
    if (user.userData != null) {
      await _storage.write(key: 'user_data', value: json.encode(user.userData));
    }
    if (user.license != null) {
      await _storage.write(key: 'user_license', value: json.encode(user.license));
    }
  }
  
  static Future<AppUser?> getStoredUser() async {
    final userId = await _storage.read(key: 'user_id');
    final userEmail = await _storage.read(key: 'user_email');
    final userRole = await _storage.read(key: 'user_role');
    final userDataStr = await _storage.read(key: 'user_data');
    final userLicenseStr = await _storage.read(key: 'user_license');
    
    if (userId != null && userEmail != null && userRole != null) {
      return AppUser(
        id: userId,
        email: userEmail,
        role: userRole,
        userData: userDataStr != null ? json.decode(userDataStr) : null,
        license: userLicenseStr != null ? json.decode(userLicenseStr) : null,
      );
    }
    return null;
  }
  
  // Get current user (from Supabase session)
  static Future<AppUser?> get currentUser async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      try {
        final user = await _getUserWithRole(session.user);
        if (user != null) return user;
      } catch (e) {
        // Fallback to stored user if offline or network error
      }
      return await getStoredUser();
    }
    return await getStoredUser();
  }
  
  // Stream of auth changes
  static Stream<AppUser?> get userStream {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      final session = event.session;
      if (session != null) {
        return await _getUserWithRole(session.user);
      }
      return null;
    });
  }

  // ==================== TOKEN MANAGEMENT ====================
  
  static Future<void> storeTokens(String accessToken, String idToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'id_token', value: idToken);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<String?> getIdToken() async {
    return await _storage.read(key: 'id_token');
  }

  static Future<Map<String, dynamic>?> getUserInfo() async {
    final idToken = await getIdToken();
    if (idToken != null) {
      return JwtDecoder.decode(idToken);
    }
    return null;
  }

  // ==================== LOGOUT ====================
  
  static Future<void> logout() async {
    // Sign out from Supabase (ignore errors if offline)
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    
    // Clear secure storage
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'id_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_data');
    await _storage.delete(key: 'user_license');
  }

  static Future<bool> isLoggedIn() async {
    // Check Supabase session first
    final session = _supabase.auth.currentSession;
    if (session != null) return true;
    
    // Fallback to token check
    final token = await getAccessToken();
    return token != null && !JwtDecoder.isExpired(token);
  }
  
  // ==================== ROLE HELPERS ====================
  
  static Future<String?> getUserRole() async {
    final user = await currentUser;
    return user?.role;
  }
  
  static Future<bool> isDriver() async {
    final role = await getUserRole();
    return role == 'driver';
  }
  
  static Future<bool> isTrafficOfficer() async {
    final role = await getUserRole();
    return role == 'traffic_officer';
  }
  
  static Future<bool> isLicensingOfficer() async {
    final role = await getUserRole();
    return role == 'licensing_officer';
  }
}
