import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../features/game/models/dog_breed.dart';

/// 3D Clay Dog character widget for board cells, preview rows, and badges.
///
/// Supports all 6 SnapDog breeds:
/// - [DogBreed.corgi] (uses official 3D clay Corgi assets)
/// - [DogBreed.shibaInu] (clay vector placeholder)
/// - [DogBreed.pug] (clay vector placeholder)
/// - [DogBreed.husky] (clay vector placeholder)
/// - [DogBreed.goldenRetriever] (clay vector placeholder)
/// - [DogBreed.beagle] (clay vector placeholder)
class CuteDogCharacter extends StatelessWidget {
  final double size;
  final DogBreed breed;
  final bool hasClash;
  final String? customAsset;
  final bool isSilhouette;

  const CuteDogCharacter({
    super.key,
    this.size = 36,
    this.breed = DogBreed.corgi,
    this.hasClash = false,
    this.customAsset,
    this.isSilhouette = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSilhouette) {
      return SizedBox(
        width: size,
        height: size,
        child: Opacity(
          opacity: 0.35,
          child: CustomPaint(
            size: Size(size, size),
            painter: _ClayBreedPainter(breed: breed, hasClash: false, isSilhouette: true),
          ),
        ),
      );
    }

    // For Corgi, use official supplied raster asset if customAsset is provided or default
    if (breed == DogBreed.corgi) {
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
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) {
            // Robust fallback painter for headless tests
            return CustomPaint(
              size: Size(size, size),
              painter: _ClayBreedPainter(breed: DogBreed.corgi, hasClash: hasClash),
            );
          },
        ),
      );
    }

    // High quality vector 3D clay painter for other breeds
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _ClayBreedPainter(
          breed: breed,
          hasClash: hasClash,
        ),
      ),
    );
  }
}

/// Unified 3D clay vector painter for all dog breeds.
///
/// Designed with rounded shapes, subtle depth, high contrast,
/// and distinctive breed facial characteristics.
class _ClayBreedPainter extends CustomPainter {
  final DogBreed breed;
  final bool hasClash;
  final bool isSilhouette;

  _ClayBreedPainter({
    required this.breed,
    required this.hasClash,
    this.isSilhouette = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (isSilhouette) {
      final silPaint = Paint()..color = const Color(0xFF6B584E);
      _drawHeadShape(canvas, w, h, silPaint);
      _drawEars(canvas, w, h, silPaint);
      return;
    }

    switch (breed) {
      case DogBreed.corgi:
        _paintCorgi(canvas, w, h);
        break;
      case DogBreed.shibaInu:
        _paintShiba(canvas, w, h);
        break;
      case DogBreed.pug:
        _paintPug(canvas, w, h);
        break;
      case DogBreed.husky:
        _paintHusky(canvas, w, h);
        break;
      case DogBreed.goldenRetriever:
        _paintGolden(canvas, w, h);
        break;
      case DogBreed.beagle:
        _paintBeagle(canvas, w, h);
        break;
    }
  }

  void _drawHeadShape(Canvas canvas, double w, double h, Paint paint) {
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.52),
      width: w * 0.72,
      height: h * 0.64,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.32)),
      paint,
    );
  }

  void _drawEars(Canvas canvas, double w, double h, Paint paint) {
    canvas.drawCircle(Offset(w * 0.22, h * 0.26), w * 0.16, paint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.26), w * 0.16, paint);
  }

  // --- Corgi ---
  void _paintCorgi(Canvas canvas, double w, double h) {
    final furColor = hasClash ? const Color(0xFFF79A7A) : const Color(0xFFF4A261);
    final earColor = hasClash ? const Color(0xFFE26D5C) : const Color(0xFFE76F51);
    const muzzleColor = Color(0xFFFFF1E0);

    // Ears (Large upright)
    final leftEar = Path()
      ..moveTo(w * 0.28, h * 0.32)
      ..cubicTo(w * 0.05, h * 0.12, w * 0.02, h * 0.65, w * 0.20, h * 0.60);
    canvas.drawPath(leftEar, Paint()..color = earColor);

    final rightEar = Path()
      ..moveTo(w * 0.72, h * 0.32)
      ..cubicTo(w * 0.95, h * 0.12, w * 0.98, h * 0.65, w * 0.80, h * 0.60);
    canvas.drawPath(rightEar, Paint()..color = earColor);

    // Head
    _drawHeadShape(canvas, w, h, Paint()..color = furColor);

    // White blaze & Muzzle
    final blaze = Path()
      ..moveTo(w * 0.45, h * 0.24)
      ..lineTo(w * 0.55, h * 0.24)
      ..lineTo(w * 0.58, h * 0.55)
      ..lineTo(w * 0.42, h * 0.55)
      ..close();
    canvas.drawPath(blaze, Paint()..color = muzzleColor);

    final muzzleRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.64),
      width: w * 0.46,
      height: h * 0.32,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(muzzleRect, Radius.circular(w * 0.16)),
      Paint()..color = muzzleColor,
    );

    _drawFaceFeatures(canvas, w, h, hasBlush: true);
  }

  // --- Shiba Inu ---
  void _paintShiba(Canvas canvas, double w, double h) {
    final furColor = hasClash ? const Color(0xFFE27B58) : const Color(0xFFE07A5F);
    final earColor = hasClash ? const Color(0xFFC85A32) : const Color(0xFFBF4E30);
    const whiteColor = Color(0xFFFFF7ED);

    // Pointed triangular prick ears
    final leftEar = Path()
      ..moveTo(w * 0.18, h * 0.36)
      ..lineTo(w * 0.22, h * 0.12)
      ..lineTo(w * 0.40, h * 0.28)
      ..close();
    canvas.drawPath(leftEar, Paint()..color = earColor);

    final rightEar = Path()
      ..moveTo(w * 0.82, h * 0.36)
      ..lineTo(w * 0.78, h * 0.12)
      ..lineTo(w * 0.60, h * 0.28)
      ..close();
    canvas.drawPath(rightEar, Paint()..color = earColor);

    // Inner ear cream highlight
    final innerLeft = Path()
      ..moveTo(w * 0.22, h * 0.32)
      ..lineTo(w * 0.24, h * 0.17)
      ..lineTo(w * 0.34, h * 0.28)
      ..close();
    canvas.drawPath(innerLeft, Paint()..color = whiteColor);

    final innerRight = Path()
      ..moveTo(w * 0.78, h * 0.32)
      ..lineTo(w * 0.76, h * 0.17)
      ..lineTo(w * 0.66, h * 0.28)
      ..close();
    canvas.drawPath(innerRight, Paint()..color = whiteColor);

    // Head
    _drawHeadShape(canvas, w, h, Paint()..color = furColor);

    // Urajiro cheeks (white bottom half)
    final urajiro = Path()
      ..moveTo(w * 0.18, h * 0.54)
      ..quadraticBezierTo(w * 0.30, h * 0.42, w * 0.50, h * 0.50)
      ..quadraticBezierTo(w * 0.70, h * 0.42, w * 0.82, h * 0.54)
      ..quadraticBezierTo(w * 0.82, h * 0.78, w * 0.50, h * 0.82)
      ..quadraticBezierTo(w * 0.18, h * 0.78, w * 0.18, h * 0.54)
      ..close();
    canvas.drawPath(urajiro, Paint()..color = whiteColor);

    // Eyebrow cream dots
    canvas.drawCircle(Offset(w * 0.34, h * 0.38), w * 0.045, Paint()..color = whiteColor);
    canvas.drawCircle(Offset(w * 0.66, h * 0.38), w * 0.045, Paint()..color = whiteColor);

    _drawFaceFeatures(canvas, w, h, hasBlush: true);
  }

  // --- Pug ---
  void _paintPug(Canvas canvas, double w, double h) {
    final furColor = hasClash ? const Color(0xFFD6A068) : const Color(0xFFE5B988);
    const maskColor = Color(0xFF382319);
    final earColor = maskColor;

    // Folded button ears
    final leftEar = Path()
      ..moveTo(w * 0.14, h * 0.26)
      ..quadraticBezierTo(w * 0.10, h * 0.44, w * 0.24, h * 0.46)
      ..lineTo(w * 0.28, h * 0.28)
      ..close();
    canvas.drawPath(leftEar, Paint()..color = earColor);

    final rightEar = Path()
      ..moveTo(w * 0.86, h * 0.26)
      ..quadraticBezierTo(w * 0.90, h * 0.44, w * 0.76, h * 0.46)
      ..lineTo(w * 0.72, h * 0.28)
      ..close();
    canvas.drawPath(rightEar, Paint()..color = earColor);

    // Head
    _drawHeadShape(canvas, w, h, Paint()..color = furColor);

    // Forehead clay wrinkle lines
    final wrinklePaint = Paint()
      ..color = const Color(0xFF8B5E3C).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.42, h * 0.30), Offset(w * 0.58, h * 0.30), wrinklePaint);
    canvas.drawLine(Offset(w * 0.40, h * 0.36), Offset(w * 0.60, h * 0.36), wrinklePaint);

    // Signature black mask
    final maskRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.62),
      width: w * 0.54,
      height: h * 0.36,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(maskRect, Radius.circular(w * 0.16)),
      Paint()..color = maskColor,
    );

    _drawFaceFeatures(canvas, w, h, hasBlush: false, eyeColor: Colors.white);
  }

  // --- Husky ---
  void _paintHusky(Canvas canvas, double w, double h) {
    final furColor = hasClash ? const Color(0xFF78909C) : const Color(0xFF90A4AE);
    final darkFur = const Color(0xFF37474F);
    const whiteColor = Color(0xFFFFFFFF);

    // Upright triangular wolf ears
    final leftEar = Path()
      ..moveTo(w * 0.16, h * 0.34)
      ..lineTo(w * 0.22, h * 0.10)
      ..lineTo(w * 0.38, h * 0.26)
      ..close();
    canvas.drawPath(leftEar, Paint()..color = darkFur);

    final rightEar = Path()
      ..moveTo(w * 0.84, h * 0.34)
      ..lineTo(w * 0.78, h * 0.10)
      ..lineTo(w * 0.62, h * 0.26)
      ..close();
    canvas.drawPath(rightEar, Paint()..color = darkFur);

    // Inner ear
    final innerEarPaint = Paint()..color = const Color(0xFFFFCCBC);
    canvas.drawCircle(Offset(w * 0.25, h * 0.23), w * 0.05, innerEarPaint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.23), w * 0.05, innerEarPaint);

    // Head
    _drawHeadShape(canvas, w, h, Paint()..color = furColor);

    // Husky striking facial mask (white goggles & muzzle)
    final maskPath = Path()
      ..moveTo(w * 0.50, h * 0.32)
      ..lineTo(w * 0.34, h * 0.40)
      ..quadraticBezierTo(w * 0.18, h * 0.46, w * 0.22, h * 0.70)
      ..quadraticBezierTo(w * 0.35, h * 0.82, w * 0.50, h * 0.82)
      ..quadraticBezierTo(w * 0.65, h * 0.82, w * 0.78, h * 0.70)
      ..quadraticBezierTo(w * 0.82, h * 0.46, w * 0.66, h * 0.40)
      ..close();
    canvas.drawPath(maskPath, Paint()..color = whiteColor);

    // Central forehead blaze
    final blaze = Path()
      ..moveTo(w * 0.48, h * 0.22)
      ..lineTo(w * 0.52, h * 0.22)
      ..lineTo(w * 0.50, h * 0.40)
      ..close();
    canvas.drawPath(blaze, Paint()..color = whiteColor);

    _drawFaceFeatures(canvas, w, h, hasBlush: false, irisColor: const Color(0xFF4FC3F7));
  }

  // --- Golden Retriever ---
  void _paintGolden(Canvas canvas, double w, double h) {
    final furColor = hasClash ? const Color(0xFFE5A835) : const Color(0xFFEEBA4C);
    final earColor = hasClash ? const Color(0xFFC78316) : const Color(0xFFDF9B2A);
    const creamMuzzle = Color(0xFFFFF3D6);

    // Large floppy hanging ears
    final leftEar = Path()
      ..moveTo(w * 0.18, h * 0.32)
      ..quadraticBezierTo(w * 0.06, h * 0.54, w * 0.16, h * 0.72)
      ..quadraticBezierTo(w * 0.26, h * 0.72, w * 0.28, h * 0.48)
      ..close();
    canvas.drawPath(leftEar, Paint()..color = earColor);

    final rightEar = Path()
      ..moveTo(w * 0.82, h * 0.32)
      ..quadraticBezierTo(w * 0.94, h * 0.54, w * 0.84, h * 0.72)
      ..quadraticBezierTo(w * 0.74, h * 0.72, w * 0.72, h * 0.48)
      ..close();
    canvas.drawPath(rightEar, Paint()..color = earColor);

    // Head
    _drawHeadShape(canvas, w, h, Paint()..color = furColor);

    // Soft muzzle
    final muzzleRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.64),
      width: w * 0.50,
      height: h * 0.34,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(muzzleRect, Radius.circular(w * 0.17)),
      Paint()..color = creamMuzzle,
    );

    _drawFaceFeatures(canvas, w, h, hasBlush: true);
  }

  // --- Beagle ---
  void _paintBeagle(Canvas canvas, double w, double h) {
    const whiteColor = Color(0xFFFFFFFF);
    final tanColor = hasClash ? const Color(0xFFB57032) : const Color(0xFFC87D3E);
    const darkPatch = Color(0xFF2C1E18);

    // Long drooping hound ears (tan)
    final leftEar = Path()
      ..moveTo(w * 0.18, h * 0.32)
      ..quadraticBezierTo(w * 0.04, h * 0.58, w * 0.15, h * 0.78)
      ..quadraticBezierTo(w * 0.26, h * 0.78, w * 0.26, h * 0.50)
      ..close();
    canvas.drawPath(leftEar, Paint()..color = tanColor);

    final rightEar = Path()
      ..moveTo(w * 0.82, h * 0.32)
      ..quadraticBezierTo(w * 0.96, h * 0.58, w * 0.85, h * 0.78)
      ..quadraticBezierTo(w * 0.74, h * 0.78, w * 0.74, h * 0.50)
      ..close();
    canvas.drawPath(rightEar, Paint()..color = tanColor);

    // Base head (white)
    _drawHeadShape(canvas, w, h, Paint()..color = whiteColor);

    // Tan cheek/eye patches
    final leftPatch = Rect.fromCenter(
      center: Offset(w * 0.32, h * 0.46),
      width: w * 0.30,
      height: h * 0.32,
    );
    canvas.drawOval(leftPatch, Paint()..color = tanColor);

    final rightPatch = Rect.fromCenter(
      center: Offset(w * 0.68, h * 0.46),
      width: w * 0.30,
      height: h * 0.32,
    );
    canvas.drawOval(rightPatch, Paint()..color = tanColor);

    // Dark patch at top of head
    final crownPatch = Path()
      ..moveTo(w * 0.38, h * 0.20)
      ..quadraticBezierTo(w * 0.50, h * 0.28, w * 0.62, h * 0.20)
      ..lineTo(w * 0.58, h * 0.16)
      ..lineTo(w * 0.42, h * 0.16)
      ..close();
    canvas.drawPath(crownPatch, Paint()..color = darkPatch);

    // White blaze between eyes
    final blaze = Path()
      ..moveTo(w * 0.44, h * 0.22)
      ..lineTo(w * 0.56, h * 0.22)
      ..lineTo(w * 0.54, h * 0.60)
      ..lineTo(w * 0.46, h * 0.60)
      ..close();
    canvas.drawPath(blaze, Paint()..color = whiteColor);

    _drawFaceFeatures(canvas, w, h, hasBlush: true);
  }

  // --- Common facial features helper ---
  void _drawFaceFeatures(
    Canvas canvas,
    double w,
    double h, {
    required bool hasBlush,
    Color eyeColor = const Color(0xFF382319),
    Color? irisColor,
  }) {
    const darkFeature = Color(0xFF382319);
    final blushColor = const Color(0xFFF28482).withValues(alpha: 0.45);

    // Blush
    if (hasBlush) {
      canvas.drawCircle(Offset(w * 0.26, h * 0.56), w * 0.065, Paint()..color = blushColor);
      canvas.drawCircle(Offset(w * 0.74, h * 0.56), w * 0.065, Paint()..color = blushColor);
    }

    // Eyes
    final eyeRadius = w * 0.052;

    if (hasClash) {
      // Clashing / sad squinting eyes
      final eyeStroke = Paint()
        ..color = eyeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(w * 0.34, h * 0.44), Offset(w * 0.40, h * 0.47), eyeStroke);
      canvas.drawLine(Offset(w * 0.34, h * 0.50), Offset(w * 0.40, h * 0.47), eyeStroke);

      canvas.drawLine(Offset(w * 0.66, h * 0.44), Offset(w * 0.60, h * 0.47), eyeStroke);
      canvas.drawLine(Offset(w * 0.66, h * 0.50), Offset(w * 0.60, h * 0.47), eyeStroke);
    } else {
      // Friendly round eyes with shine
      if (irisColor != null) {
        canvas.drawCircle(Offset(w * 0.37, h * 0.46), eyeRadius * 1.15, Paint()..color = irisColor);
        canvas.drawCircle(Offset(w * 0.63, h * 0.46), eyeRadius * 1.15, Paint()..color = irisColor);
      }

      canvas.drawCircle(Offset(w * 0.37, h * 0.46), eyeRadius, Paint()..color = eyeColor);
      canvas.drawCircle(Offset(w * 0.63, h * 0.46), eyeRadius, Paint()..color = eyeColor);

      final shinePaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(w * 0.385, h * 0.44), eyeRadius * 0.42, shinePaint);
      canvas.drawCircle(Offset(w * 0.645, h * 0.44), eyeRadius * 0.42, shinePaint);
    }

    // Button nose
    final nosePath = Path()
      ..moveTo(w * 0.45, h * 0.58)
      ..lineTo(w * 0.55, h * 0.58)
      ..lineTo(w * 0.50, h * 0.65)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = darkFeature);

    // Mouth
    final mouthStroke = Paint()
      ..color = darkFeature
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.038
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(w * 0.44, h * 0.68)
      ..quadraticBezierTo(w * 0.50, h * 0.72, w * 0.56, h * 0.68);
    canvas.drawPath(mouthPath, mouthStroke);
  }

  @override
  bool shouldRepaint(covariant _ClayBreedPainter oldDelegate) =>
      oldDelegate.breed != breed ||
      oldDelegate.hasClash != hasClash ||
      oldDelegate.isSilhouette != isSilhouette;
}
