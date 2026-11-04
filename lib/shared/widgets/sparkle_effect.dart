import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Lightweight sparkle particle overlay for correct dog placements.
class SparkleOverlay extends StatefulWidget {
  final Widget child;
  final bool trigger;

  const SparkleOverlay({
    super.key,
    required this.child,
    required this.trigger,
  });

  @override
  State<SparkleOverlay> createState() => _SparkleOverlayState();
}

class _SparkleOverlayState extends State<SparkleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.trigger) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant SparkleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final isSparkling = _controller.isAnimating && progress > 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            widget.child,
            if (isSparkling)
              IgnorePointer(
                child: CustomPaint(
                  size: const Size(36, 36),
                  painter: _SparklePainter(progress: progress),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double progress;

  _SparklePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);

    // 4 tiny star particles radiating outward
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final distance = (progress * w * 0.45);
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    const angles = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];

    for (final angle in angles) {
      final rad = angle + (progress * 0.5);
      final offset = center + Offset(math.cos(rad) * distance, math.sin(rad) * distance);
      final particleSize = (3.5 * (1.0 - progress * 0.7)).clamp(1.0, 4.0);

      // Draw diamond / star sparkle
      final path = Path();
      path.moveTo(offset.dx, offset.dy - particleSize);
      path.lineTo(offset.dx + particleSize * 0.5, offset.dy);
      path.lineTo(offset.dx, offset.dy + particleSize);
      path.lineTo(offset.dx - particleSize * 0.5, offset.dy);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
