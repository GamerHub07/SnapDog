import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Cheerful confetti particle overlay for victory / puzzle completion screens.
class ConfettiCelebration extends StatefulWidget {
  final Widget child;

  const ConfettiCelebration({
    super.key,
    required this.child,
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward();

    final rng = math.Random(42);
    final colors = [
      AppColors.primary,
      AppColors.primaryDark,
      AppColors.gold,
      const Color(0xFF64B5F6),
      const Color(0xFF81C784),
      const Color(0xFFFF8A65),
      const Color(0xFFBA68C8),
    ];

    _particles = List.generate(45, (i) {
      return _ConfettiParticle(
        startX: rng.nextDouble(),
        startY: -0.1 - rng.nextDouble() * 0.4,
        speedY: 0.6 + rng.nextDouble() * 0.7,
        driftX: (rng.nextDouble() - 0.5) * 0.35,
        rotationSpeed: (rng.nextDouble() - 0.5) * 8.0,
        size: 7.0 + rng.nextDouble() * 6.0,
        color: colors[rng.nextInt(colors.length)],
        isCircle: rng.nextBool(),
      );
    });
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
        return Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _controller.value,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _ConfettiParticle {
  final double startX;
  final double startY;
  final double speedY;
  final double driftX;
  final double rotationSpeed;
  final double size;
  final Color color;
  final bool isCircle;

  _ConfettiParticle({
    required this.startX,
    required this.startY,
    required this.speedY,
    required this.driftX,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    for (final p in particles) {
      final y = (p.startY + p.speedY * progress) * h;
      final x = (p.startX + p.driftX * progress + math.sin(progress * math.pi * 3 + p.startX * 10) * 0.05) * w;

      if (y < 0 || y > h || x < 0 || x > w) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: (1.0 - progress * 0.3).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotationSpeed);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size * 0.45, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
