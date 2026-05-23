// lib/features/traffic_officer/screens/login_screen.dart
import 'dart:ui';

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
  bool _isLoading = false;
  bool _isHovered = false;
  bool _isPressed = false;

  static const Color _goldPrimary = AppTheme.gold;
  static const Color _goldLight = AppTheme.goldLight;
  static const Color _goldDark = Color(0xFF9F7428);
  static const Color _ink = Color(0xFF08111F);

  bool get _isActive => _isHovered || _isPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF172B52), AppTheme.background, Color(0xFF06101C)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: _BackgroundAccents()),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _brandHeader(),
                        const SizedBox(height: 34),
                        _authPanel(),
                        const SizedBox(height: 22),
                        _footerNote(),
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

  Widget _brandHeader() {
    return Column(
      children: [
        Container(
          width: 126,
          height: 126,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: _goldPrimary.withValues(alpha: 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _goldPrimary.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 1,
              ),
              const BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.34),
                blurRadius: 18,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: const _LicenceMark(),
        ),
        const SizedBox(height: 20),
        Text(
          'DriveID',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
            shadows: [
              Shadow(
                color: _goldPrimary.withValues(alpha: 0.2),
                offset: const Offset(0, 3),
                blurRadius: 16,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Driver & Officer Portal',
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 3,
          width: 86,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [
                Colors.transparent,
                _goldPrimary,
                _goldLight,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _authPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.075),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.28),
                blurRadius: 28,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _goldPrimary.withValues(alpha: 0.22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _goldPrimary.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/branding/esignet_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure eSignet sign-in',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verified access for drivers and officers',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.94,
                            ),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _trustPill(
                      Icons.verified_user_outlined,
                      'Licence verified',
                      AppTheme.secondaryTeal,
                      isProminent: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _trustPill(
                      Icons.lock_outline_rounded,
                      'Secure access',
                      _goldPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _loginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trustPill(
    IconData icon,
    String label,
    Color color, {
    bool isProminent = false,
  }) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isProminent ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isProminent ? 0.26 : 0.14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: color.withValues(alpha: 0.95)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textPrimary.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
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
            borderRadius: BorderRadius.circular(16),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              scale: _isPressed ? 0.985 : (_isHovered ? 1.01 : 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        _isActive
                            ? const [_goldLight, _goldPrimary, _goldDark]
                            : const [_goldPrimary, _goldLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _goldPrimary.withValues(
                        alpha: _isActive ? 0.42 : 0.25,
                      ),
                      blurRadius: _isActive ? 24 : 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(_ink),
                            ),
                          )
                          : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login_rounded, size: 18, color: _ink),
                              SizedBox(width: 12),
                              Text(
                                'Continue with eSignet',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: _ink,
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footerNote() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.badge_outlined,
                size: 14,
                color: _goldPrimary.withValues(alpha: 0.82),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Digital driving licence access',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'National Traffic Authority - Powered by eSignet',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.42),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _esignet() async {
    setState(() => _isLoading = true);

    try {
      final url = AuthService.getLoginUri();
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      _show('eSignet error: Unable to start authentication', AppTheme.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _show(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _LicenceMark extends StatelessWidget {
  const _LicenceMark();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -0.08,
          child: Container(
            width: 82,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8FBFF), Color(0xFFE7EDF6)],
              ),
              border: Border.all(
                color: AppTheme.gold.withValues(alpha: 0.72),
                width: 1.1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.18),
                  blurRadius: 16,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryDeepBlue.withValues(
                            alpha: 0.9,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LicenceLine(widthFactor: 1),
                            const SizedBox(height: 4),
                            _LicenceLine(widthFactor: 0.62),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car_filled_rounded,
                        color: AppTheme.primaryDeepBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 10,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.secondaryTeal,
              border: Border.all(color: const Color(0xFFF8FBFF), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
        ),
      ],
    );
  }
}

class _LicenceLine extends StatelessWidget {
  const _LicenceLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.primaryDeepBlue.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _BackgroundAccents extends StatelessWidget {
  const _BackgroundAccents();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: -92,
          top: -86,
          child: _GlowCircle(
            size: 260,
            color: AppTheme.gold.withValues(alpha: 0.11),
          ),
        ),
        Positioned(
          right: -116,
          bottom: -106,
          child: _GlowCircle(
            size: 300,
            color: AppTheme.secondaryTeal.withValues(alpha: 0.09),
          ),
        ),
        Positioned(
          right: 28,
          top: 58,
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.055),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
