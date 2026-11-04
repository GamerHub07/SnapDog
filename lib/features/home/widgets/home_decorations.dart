import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Subtle decorative background elements for the SnapDog home screen.
///
/// Features:
/// - Soft pastel green grass patches near the bottom corners
/// - Cute 3D clay-style dog bones near the bottom edges
/// - Gentle semi-transparent paw-print accents
/// - Non-intrusive, sits behind content without obstructing interactive elements
class HomeBackgroundDecorations extends StatelessWidget {
  const HomeBackgroundDecorations({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: const [
          // Bottom-left corner decoration: grass patch, small clay bone, and paw accent
          Positioned(
            left: 10,
            bottom: 8,
            child: _BottomLeftDecoration(),
          ),

          // Bottom-right corner decoration: grass patch, small clay bone, and paw accent
          Positioned(
            right: 12,
            bottom: 8,
            child: _BottomRightDecoration(),
          ),
        ],
      ),
    );
  }
}

class _BottomLeftDecoration extends StatelessWidget {
  const _BottomLeftDecoration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomLeft,
        children: [
          // Faint paw-print accent
          Positioned(
            left: 56,
            bottom: 30,
            child: Transform.rotate(
              angle: -0.3,
              child: const _SubtlePawAccent(size: 16),
            ),
          ),

          // Small green grass patch
          const Positioned(
            left: 2,
            bottom: 0,
            child: _GrassPatch(width: 58, height: 38),
          ),

          // Cute 3D clay-style dog bone resting near the grass
          Positioned(
            left: 36,
            bottom: 4,
            child: Transform.rotate(
              angle: -0.22, // ~ -13 degrees
              child: const _ClayBone(width: 28, height: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomRightDecoration extends StatelessWidget {
  const _BottomRightDecoration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 95,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          // Faint paw-print accent
          Positioned(
            right: 52,
            bottom: 28,
            child: Transform.rotate(
              angle: 0.25,
              child: const _SubtlePawAccent(size: 15),
            ),
          ),

          // Small green grass patch
          const Positioned(
            right: 2,
            bottom: 0,
            child: _GrassPatch(width: 52, height: 34, isFlipped: true),
          ),

          // Cute 3D clay-style dog bone resting near the grass
          Positioned(
            right: 32,
            bottom: 4,
            child: Transform.rotate(
              angle: 0.18, // ~ 10 degrees
              child: const _ClayBone(width: 25, height: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering a soft pastel green grass patch with gentle shadows.
class _GrassPatch extends StatelessWidget {
  final double width;
  final double height;
  final bool isFlipped;

  const _GrassPatch({
    required this.width,
    required this.height,
    this.isFlipped = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget patch = CustomPaint(
      size: Size(width, height),
      painter: _GrassPainter(),
    );

    if (isFlipped) {
      patch = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(pi),
        child: patch,
      );
    }

    return patch;
  }
}

class _GrassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gentle base shadow
    final shadowPaint = Paint()
      ..color = AppColors.shadowWarm.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.45, h * 0.94),
        width: w * 0.85,
        height: h * 0.22,
      ),
      shadowPaint,
    );

    // Subtle soft mound under grass
    final moundPaint = Paint()
      ..color = const Color(0xFFCBEBC4).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.45, h * 0.92),
        width: w * 0.75,
        height: h * 0.18,
      ),
      moundPaint,
    );

    // Background darker blade (for soft depth)
    final backBladePaint = Paint()
      ..color = const Color(0xFF81B29A) // Soft sage green
      ..style = PaintingStyle.fill;

    final backPath = Path()
      ..moveTo(w * 0.32, h * 0.90)
      ..quadraticBezierTo(w * 0.38, h * 0.35, w * 0.44, h * 0.12)
      ..quadraticBezierTo(w * 0.48, h * 0.38, w * 0.50, h * 0.90)
      ..close();
    canvas.drawPath(backPath, backBladePaint);

    // Left curved blade (medium pastel green)
    final mainBladePaint = Paint()
      ..color = const Color(0xFF98D4A8)
      ..style = PaintingStyle.fill;

    final leftPath = Path()
      ..moveTo(w * 0.15, h * 0.92)
      ..quadraticBezierTo(w * 0.16, h * 0.45, w * 0.08, h * 0.22)
      ..quadraticBezierTo(w * 0.25, h * 0.42, w * 0.35, h * 0.92)
      ..close();
    canvas.drawPath(leftPath, mainBladePaint);

    // Center tall blade (fresh pastel mint)
    final centerBladePaint = Paint()
      ..color = const Color(0xFFA8DEB6)
      ..style = PaintingStyle.fill;

    final centerPath = Path()
      ..moveTo(w * 0.24, h * 0.92)
      ..quadraticBezierTo(w * 0.28, h * 0.30, w * 0.28, h * 0.05)
      ..quadraticBezierTo(w * 0.36, h * 0.32, w * 0.44, h * 0.92)
      ..close();
    canvas.drawPath(centerPath, centerBladePaint);

    // Right curved blade (soft light green)
    final rightPath = Path()
      ..moveTo(w * 0.42, h * 0.92)
      ..quadraticBezierTo(w * 0.55, h * 0.48, w * 0.70, h * 0.28)
      ..quadraticBezierTo(w * 0.58, h * 0.55, w * 0.56, h * 0.92)
      ..close();
    canvas.drawPath(rightPath, mainBladePaint);

    // Extra little side sprout
    final sproutPath = Path()
      ..moveTo(w * 0.52, h * 0.92)
      ..quadraticBezierTo(w * 0.68, h * 0.65, w * 0.82, h * 0.52)
      ..quadraticBezierTo(w * 0.68, h * 0.72, w * 0.62, h * 0.92)
      ..close();
    canvas.drawPath(sproutPath, centerBladePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom-painted 3D clay-style dog bone.
class _ClayBone extends StatelessWidget {
  final double width;
  final double height;

  const _ClayBone({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _ClayBonePainter(),
    );
  }
}

class _ClayBonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Drop shadow under bone
    final shadowPaint = Paint()..color = AppColors.shadowWarm.withValues(alpha: 0.22);
    final shadowShaft = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.58),
      width: w * 0.58,
      height: h * 0.42,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(shadowShaft, Radius.circular(h * 0.2)), shadowPaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.40), h * 0.28, shadowPaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.76), h * 0.28, shadowPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.40), h * 0.28, shadowPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.76), h * 0.28, shadowPaint);

    // 3D Clay Base (Warm cream/ivory)
    const boneColor = Color(0xFFFFF7ED); // Soft warm cream
    const rimColor = Color(0xFFEEDCC7); // Subtle clay shading
    final bonePaint = Paint()..color = boneColor;
    final rimPaint = Paint()..color = rimColor;

    // Bone base rim
    final rimShaft = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.53),
      width: w * 0.58,
      height: h * 0.42,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(rimShaft, Radius.circular(h * 0.2)), rimPaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.35), h * 0.28, rimPaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.71), h * 0.28, rimPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.35), h * 0.28, rimPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.71), h * 0.28, rimPaint);

    // Bone main surface
    final shaftRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.5),
      width: w * 0.56,
      height: h * 0.40,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(shaftRect, Radius.circular(h * 0.2)), bonePaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.32), h * 0.27, bonePaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.68), h * 0.27, bonePaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.32), h * 0.27, bonePaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.68), h * 0.27, bonePaint);

    // Clay specular highlight dots
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.75);
    canvas.drawCircle(Offset(w * 0.25, h * 0.28), h * 0.10, highlightPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.42), h * 0.08, highlightPaint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.28), h * 0.10, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Very subtle decorative pastel paw-print accent.
class _SubtlePawAccent extends StatelessWidget {
  final double size;

  const _SubtlePawAccent({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SubtlePawPainter(),
    );
  }
}

class _SubtlePawPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final pawPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Main palm pad
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.65),
        width: w * 0.54,
        height: h * 0.44,
      ),
      pawPaint,
    );

    // 4 toe pads
    final toeRadius = w * 0.11;
    canvas.drawCircle(Offset(w * 0.20, h * 0.34), toeRadius, pawPaint);
    canvas.drawCircle(Offset(w * 0.39, h * 0.18), toeRadius * 1.1, pawPaint);
    canvas.drawCircle(Offset(w * 0.61, h * 0.18), toeRadius * 1.1, pawPaint);
    canvas.drawCircle(Offset(w * 0.80, h * 0.34), toeRadius, pawPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
