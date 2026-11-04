import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A 3D clay-style rounded X cross marker in warm dark brown / terracotta.
///
/// Designed with rounded pill strokes, tactile clay shading, and highlights
/// for high contrast against pastel board regions.
class ClayCrossMarker extends StatelessWidget {
  final double size;
  final Color clayColor;
  final Color shadowColor;

  const ClayCrossMarker({
    super.key,
    this.size = 22,
    this.clayColor = AppColors.text,
    this.shadowColor = const Color(0xFF2C1E18),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Underlying Icon widget for accessibility & widget tests
          Icon(
            Icons.close_rounded,
            size: size,
            color: clayColor,
          ),
          // 3D tactile clay cross overlay with rounded strokes, highlight, and drop shadow
          CustomPaint(
            size: Size(size, size),
            painter: _ClayCrossPainter(
              clayColor: clayColor,
              shadowColor: shadowColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClayCrossPainter extends CustomPainter {
  final Color clayColor;
  final Color shadowColor;

  const _ClayCrossPainter({
    required this.clayColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokeWidth = w * 0.22;
    final inset = w * 0.18;

    // 1. Soft clay drop shadow
    final shadowPaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.45)
      ..strokeWidth = strokeWidth * 1.05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const shadowOffset = Offset(0.7, 1.2);
    canvas.drawLine(
      Offset(inset, inset) + shadowOffset,
      Offset(w - inset, h - inset) + shadowOffset,
      shadowPaint,
    );
    canvas.drawLine(
      Offset(w - inset, inset) + shadowOffset,
      Offset(inset, h - inset) + shadowOffset,
      shadowPaint,
    );

    // 2. Main dark brown / terracotta clay body
    final bodyPaint = Paint()
      ..color = clayColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(inset, inset),
      Offset(w - inset, h - inset),
      bodyPaint,
    );
    canvas.drawLine(
      Offset(w - inset, inset),
      Offset(inset, h - inset),
      bodyPaint,
    );

    // 3. Tactile top-left clay highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..strokeWidth = strokeWidth * 0.40
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const highlightOffset = Offset(-0.5, -0.5);
    canvas.drawLine(
      Offset(inset + strokeWidth * 0.2, inset + strokeWidth * 0.2) + highlightOffset,
      Offset(w - inset - strokeWidth * 0.2, h - inset - strokeWidth * 0.2) + highlightOffset,
      highlightPaint,
    );
    canvas.drawLine(
      Offset(w - inset - strokeWidth * 0.2, inset + strokeWidth * 0.2) + highlightOffset,
      Offset(inset + strokeWidth * 0.2, h - inset - strokeWidth * 0.2) + highlightOffset,
      highlightPaint,
    );

    // 4. Center clay smoosh indentation
    final centerPaint = Paint()
      ..color = clayColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), strokeWidth * 0.52, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _ClayCrossPainter oldDelegate) =>
      oldDelegate.clayColor != clayColor || oldDelegate.shadowColor != shadowColor;
}
