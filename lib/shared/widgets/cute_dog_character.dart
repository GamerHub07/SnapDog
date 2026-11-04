import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';

/// 3D Clay Corgi character widget for board cells and compact displays.
///
/// Features the soft 3D clay Corgi puppy with rounded proportions,
/// large upright ears, and expressive eyes.
class CuteDogCharacter extends StatelessWidget {
  final double size;
  final bool hasClash;
  final String? customAsset;

  const CuteDogCharacter({
    super.key,
    this.size = 36,
    this.hasClash = false,
    this.customAsset,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = customAsset ??
        (hasClash ? AppAssets.corgiSad : AppAssets.corgiNeutral);

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          // Robust fallback for headless tests or environments without asset bundle
          return CustomPaint(
            size: Size(size, size),
            painter: _FallbackCuteDogPainter(hasClash: hasClash),
          );
        },
      ),
    );
  }
}

/// Fallback vector illustration for tests or offline asset recovery.
class _FallbackCuteDogPainter extends CustomPainter {
  final bool hasClash;

  _FallbackCuteDogPainter({required this.hasClash});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final furColor = hasClash ? const Color(0xFFF79A7A) : const Color(0xFFF4A261);
    final earColor = hasClash ? const Color(0xFFE26D5C) : const Color(0xFFE76F51);
    final muzzleColor = const Color(0xFFFFF1E0);
    const darkFeature = Color(0xFF382319);
    final blushColor = const Color(0xFFF28482).withValues(alpha: 0.45);

    // Left Ear
    final leftEarPath = Path();
    leftEarPath.moveTo(w * 0.28, h * 0.32);
    leftEarPath.cubicTo(w * 0.05, h * 0.15, w * 0.02, h * 0.65, w * 0.20, h * 0.60);
    canvas.drawPath(leftEarPath, Paint()..color = earColor);

    // Right Ear
    final rightEarPath = Path();
    rightEarPath.moveTo(w * 0.72, h * 0.32);
    rightEarPath.cubicTo(w * 0.95, h * 0.15, w * 0.98, h * 0.65, w * 0.80, h * 0.60);
    canvas.drawPath(rightEarPath, Paint()..color = earColor);

    // Head
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.50),
      width: w * 0.68,
      height: h * 0.64,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.30)),
      Paint()..color = furColor,
    );

    // Muzzle
    final muzzleRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.62),
      width: w * 0.44,
      height: h * 0.32,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(muzzleRect, Radius.circular(w * 0.16)),
      Paint()..color = muzzleColor,
    );

    // Blush
    canvas.drawCircle(Offset(w * 0.26, h * 0.55), w * 0.065, Paint()..color = blushColor);
    canvas.drawCircle(Offset(w * 0.74, h * 0.55), w * 0.065, Paint()..color = blushColor);

    // Eyes
    final eyePaint = Paint()..color = darkFeature;
    final eyeRadius = w * 0.048;

    if (hasClash) {
      final eyeStroke = Paint()
        ..color = darkFeature
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(w * 0.34, h * 0.44), Offset(w * 0.40, h * 0.47), eyeStroke);
      canvas.drawLine(Offset(w * 0.34, h * 0.50), Offset(w * 0.40, h * 0.47), eyeStroke);

      canvas.drawLine(Offset(w * 0.66, h * 0.44), Offset(w * 0.60, h * 0.47), eyeStroke);
      canvas.drawLine(Offset(w * 0.66, h * 0.50), Offset(w * 0.60, h * 0.47), eyeStroke);
    } else {
      canvas.drawCircle(Offset(w * 0.38, h * 0.46), eyeRadius, eyePaint);
      canvas.drawCircle(Offset(w * 0.62, h * 0.46), eyeRadius, eyePaint);

      final shinePaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(w * 0.395, h * 0.44), eyeRadius * 0.45, shinePaint);
      canvas.drawCircle(Offset(w * 0.635, h * 0.44), eyeRadius * 0.45, shinePaint);
    }

    // Little triangular nose
    final nosePath = Path();
    nosePath.moveTo(w * 0.45, h * 0.58);
    nosePath.lineTo(w * 0.55, h * 0.58);
    nosePath.lineTo(w * 0.50, h * 0.65);
    nosePath.close();
    canvas.drawPath(nosePath, eyePaint);

    // Tiny mouth
    final mouthStroke = Paint()
      ..color = darkFeature
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.038
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();
    mouthPath.moveTo(w * 0.44, h * 0.68);
    mouthPath.quadraticBezierTo(w * 0.50, h * 0.72, w * 0.56, h * 0.68);
    canvas.drawPath(mouthPath, mouthStroke);
  }

  @override
  bool shouldRepaint(covariant _FallbackCuteDogPainter oldDelegate) =>
      oldDelegate.hasClash != hasClash;
}
