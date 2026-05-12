import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.height < 720;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            const _AmbientBackdrop(),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        size.height -
                        MediaQuery.paddingOf(context).vertical -
                        52,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/branding/driveid_icon.png',
                                width: 42,
                                height: 42,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'DriveID',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isCompact ? 34 : 58),
                        Center(
                          child: _IdentityBadge(size: isCompact ? 172 : 218),
                        ),
                        SizedBox(height: isCompact ? 30 : 48),
                        const Text(
                          'Digital road identity, ready when it matters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 32,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Secure access for drivers and traffic officers in one trusted mobile workspace.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                () => Navigator.pushNamed(context, '/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.gold,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get started',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed:
                              () => Navigator.pushNamed(context, '/login'),
                          child: const Text('I already have access'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityBadge extends StatelessWidget {
  const _IdentityBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.gold.withAlpha(20),
              border: Border.all(color: AppTheme.gold.withAlpha(48)),
            ),
          ),
          Container(
            width: size * 0.76,
            height: size * 0.76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              color: AppTheme.cardDark,
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Image.asset('assets/branding/driveid_icon.png'),
            ),
          ),
          Positioned(
            right: size * 0.12,
            bottom: size * 0.18,
            child: Container(
              width: size * 0.24,
              height: size * 0.24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryTeal,
                border: Border.all(color: AppTheme.background, width: 4),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AmbientBackdropPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _AmbientBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = AppTheme.primaryDeepBlue.withAlpha(58);
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.16),
      120,
      paint,
    );

    paint.color = AppTheme.secondaryTeal.withAlpha(34);
    canvas.drawCircle(
      Offset(size.width * 0.96, size.height * 0.36),
      150,
      paint,
    );

    final road =
        Paint()
          ..color = Colors.white.withAlpha(13)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

    final path =
        Path()
          ..moveTo(size.width * 0.20, size.height)
          ..cubicTo(
            size.width * 0.40,
            size.height * 0.68,
            size.width * 0.56,
            size.height * 0.52,
            size.width * 0.76,
            0,
          );
    canvas.drawPath(path, road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
