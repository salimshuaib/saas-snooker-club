import 'package:flutter/material.dart';

class GamingBackground extends StatelessWidget {
  final Widget child;

  const GamingBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Base Dark Color (Deeper Blue/Black)
        Container(color: const Color(0xFF050614)),

        // 2. Bold Neon Glowing Orbs
        // Top Right: Cyberpunk Neon Cyan/Blue
        Positioned(
          top: -300,
          right: -200,
          child: Container(
            width: 800,
            height: 800,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  const Color(0xFF00E5FF).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Bottom Left: Hot Neon Pink
        Positioned(
          bottom: -200,
          left: -200,
          child: Container(
            width: 700,
            height: 700,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF007F).withValues(alpha: 0.25),
                  const Color(0xFFFF007F).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Center: Subtle Purple
        Positioned(
          top: MediaQuery.sizeOf(context).height * 0.3,
          left: MediaQuery.sizeOf(context).width * 0.3,
          child: Container(
            width: 1000,
            height: 1000,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF8A2BE2).withValues(alpha: 0.15),
                  const Color(0xFF8A2BE2).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // 3. Tech Grid Overlay
        Positioned.fill(
          child: CustomPaint(
            painter: _TechGridPainter(),
          ),
        ),

        // 4. Actual Content (Removed SafeArea to allow Sidebar to flush left)
        child,
      ],
    );
  }
}

class _TechGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double spacing = 40.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Add glowing intersections
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
      
    for (double x = 0; x < size.width; x += spacing * 2) {
      for (double y = 0; y < size.height; y += spacing * 2) {
        canvas.drawCircle(Offset(x, y), 2.0, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
