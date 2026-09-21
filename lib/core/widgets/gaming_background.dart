import 'package:flutter/material.dart';

class GamingBackground extends StatelessWidget {
  final Widget child;

  const GamingBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Base Dark Color
        Container(color: const Color(0xFF090A10)),

        // 2. Glowing Orbs (Gradients)
        Positioned(
          top: -200,
          right: -100,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF4F3BE0).withValues(alpha: 0.15),
                  const Color(0xFF4F3BE0).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFE03B8B).withValues(alpha: 0.1),
                  const Color(0xFFE03B8B).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // 3. Subtle Dot Matrix Overlay
        Positioned.fill(
          child: CustomPaint(
            painter: _DotMatrixPainter(),
          ),
        ),

        // 4. Actual Content
        SafeArea(child: child),
      ],
    );
  }
}

class _DotMatrixPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    const double spacing = 24.0;
    const double radius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
