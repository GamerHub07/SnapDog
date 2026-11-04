import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A cute vector-rendered dog paw print widget.
class PawIcon extends StatelessWidget {
  final double size;
  final Color color;

  const PawIcon({
    super.key,
    this.size = 24.0,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PawPainter(color: color),
      ),
    );
  }
}

class _PawPainter extends CustomPainter {
  final Color color;

  _PawPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Main pad (large heart/rounded triangle shape)
    final mainPadPath = Path();
    mainPadPath.moveTo(w * 0.5, h * 0.48);
    mainPadPath.cubicTo(
      w * 0.15, h * 0.52,
      w * 0.12, h * 0.90,
      w * 0.5, h * 0.92,
    );
    mainPadPath.cubicTo(
      w * 0.88, h * 0.90,
      w * 0.85, h * 0.52,
      w * 0.5, h * 0.48,
    );
    canvas.drawPath(mainPadPath, paint);

    // 4 Toe pads
    // Far Left Toe
    canvas.save();
    canvas.translate(w * 0.22, h * 0.38);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.22, height: h * 0.28),
      paint,
    );
    canvas.restore();

    // Center Left Toe
    canvas.save();
    canvas.translate(w * 0.40, h * 0.22);
    canvas.rotate(-0.1);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.22, height: h * 0.30),
      paint,
    );
    canvas.restore();

    // Center Right Toe
    canvas.save();
    canvas.translate(w * 0.60, h * 0.22);
    canvas.rotate(0.1);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.22, height: h * 0.30),
      paint,
    );
    canvas.restore();

    // Far Right Toe
    canvas.save();
    canvas.translate(w * 0.78, h * 0.38);
    canvas.rotate(0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.22, height: h * 0.28),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PawPainter oldDelegate) =>
      oldDelegate.color != color;
}
