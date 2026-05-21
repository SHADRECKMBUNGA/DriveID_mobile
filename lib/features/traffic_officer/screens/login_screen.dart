// lib/features/traffic_officer/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _uinController = TextEditingController();
  bool _isLoading = false;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void dispose() {
    _uinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative soft shapes
              Positioned(
                left: -60,
                top: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color.fromRGBO(26, 58, 111, 0.28), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -80,
                bottom: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color.fromRGBO(13, 148, 136, 0.18), Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -14),
                          child: Image.asset(
                            'assets/branding/driveid_icon.png',
                            width: 110,
                            height: 110,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'DriveID',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            shadows: const [
                              Shadow(
                                color: Color.fromRGBO(0, 0, 0, 0.35),
                                offset: Offset(0, 2),
                                blurRadius: 6,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Traffic Enforcement',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Card container (now without the button)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 255, 255, 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Single sign-on via eSignet',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _uinController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: AppTheme.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'National ID (UIN)',
                                  hintText: 'e.g. 2143058301 — required for test accounts',
                                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                                  hintStyle: TextStyle(
                                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppTheme.cardBorder),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: AppTheme.secondaryTeal),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Button moved outside the card and lowered
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) => setState(() => _isHovered = true),
                            onExit: (_) => setState(() => _isHovered = false),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isLoading ? null : _esignet,
                                onTapDown: (_) => setState(() => _isPressed = true),
                                onTapCancel: () => setState(() => _isPressed = false),
                                onTapUp: (_) => setState(() => _isPressed = false),
                                borderRadius: BorderRadius.circular(14),
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  scale: _isHovered || _isPressed ? 1.02 : 1.0,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOut,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color.fromRGBO(0, 0, 0, _isHovered || _isPressed ? 0.28 : 0.18),
                                          blurRadius: _isHovered || _isPressed ? 22 : 14,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF8F9FA),
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            child: Image.asset('assets/branding/esignet_logo.png'),
                                          ),
                                          const SizedBox(width: 14),
                                          Text(
                                            'Login with eSignet',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _esignet() async {
    setState(() => _isLoading = true);

    try {
      final uin = _uinController.text.trim();
      if (uin.isEmpty) {
        _show('Enter your National ID (UIN) from TEST_ACCOUNTS.md', AppTheme.error);
        return;
      }
      final url = AuthService.getLoginUri(uin: uin);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      _show('eSignet error', AppTheme.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _show(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}
