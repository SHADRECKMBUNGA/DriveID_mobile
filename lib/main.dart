import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'core/config/supabase_config.dart';
import 'core/models/app_user.dart';
import 'core/utils/browser_location_stub.dart'
    if (dart.library.html) 'core/utils/browser_location.dart' as browser_location;
import 'core/theme/app_theme.dart';
import 'features/driver/driver_dashboard.dart';
import 'features/traffic_officer/screens/dashboard_screen.dart';
import 'features/traffic_officer/screens/login_screen.dart';
import 'features/traffic_officer/services/auth_service.dart';

import 'core/services/local_database_service.dart';
import 'features/traffic_officer/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabaseService.initialize();
  await SupabaseConfig.initialize();
  await SyncService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  late StreamSubscription<Uri> _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLink();
  }

  @override
  void dispose() {
    _linkSubscription.cancel();
    super.dispose();
  }

  void _initDeepLink() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      await _handleDeepLink(uri);
    });

    // Handle initial URL on web for OAuth redirect
    if (kIsWeb) {
      final uri = Uri.parse(browser_location.getBrowserLocationHref());
      if (uri.queryParameters.containsKey('code') && uri.queryParameters.containsKey('state')) {
        _handleDeepLink(uri);
      }
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final isMobileCallback = uri.scheme == 'myapp' && uri.host == 'callback';
    final isWebCallback = uri.scheme == 'http' && uri.host == 'localhost' && uri.path == '/callback' &&
                         (uri.queryParameters.containsKey('code') || uri.queryParameters.containsKey('uin'));
    
    if (isMobileCallback || isWebCallback) {
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final uin = uri.queryParameters['uin'] ?? uri.queryParameters['identity'] ?? uri.queryParameters['identity_id'];
      
      if (code != null && state != null) {
        try {
          // Validate callback parameters locally before sending the authorization code to backend.
          final isValid = await AuthService.validateCallbackParams(state, code);
          if (!isValid) {
            _showError('Invalid authentication parameters');
            return;
          }

          final user = await AuthService.processEsignetCallback(
            code: code,
            state: state,
            redirectUri: AuthService.redirectUri,
          );

          if (user == null) {
            _showError('Failed to verify eSignet user');
            return;
          }

          if (!user.canAccessMobile) {
            await AuthService.logout();
            _showError('This account is not allowed on mobile.');
            return;
          }

          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
          }
        } catch (e) {
          _showError('Error during authentication: $e');
        }
      } else if (uin != null && uin.isNotEmpty) {
        try {
          final user = await AuthService.verifyUin(uin);
          if (user == null) {
            _showError('User not registered');
            return;
          }
          if (!user.canAccessMobile) {
            await AuthService.logout();
            _showError('This account is not allowed on mobile.');
            return;
          }
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
          }
        } catch (e) {
          _showError('Error during authentication: $e');
        }
      } else {
        _showError('Authorization code, state or UIN not found');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DriveID',
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/callback': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/traffic-dashboard': (context) => const DashboardScreen(),
        '/driver-dashboard': (context) => DriverDashboard(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  AppUser? _user;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final user = await AuthService.currentUser;
      if (user != null && !user.canAccessMobile) {
        await AuthService.logout();
        if (!mounted) return;
        setState(() {
          _user = null;
          _isChecking = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _user = user;
        _isChecking = false;
      });
    } catch (_) {
      try {
        await AuthService.logout();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _user = null;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user?.isDriver == true) {
      return const DriverDashboard();
    }
    if (_user?.isTrafficOfficer == true) {
      return const DashboardScreen();
    }
    return const LoginScreen();
  }
}