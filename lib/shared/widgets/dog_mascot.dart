import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';

enum DogMascotMood {
  neutral,
  happy,
  sad,
  excited,
  celebrating, // Alias for excited for backwards-compatibility
  thinking,
  sleeping,
}

/// 3D Clay Corgi mascot widget with gentle idle breathing, bobbing, and shadow.
class DogMascot extends StatefulWidget {
  final double size;
  final DogMascotMood mood;
  final bool animate;

  const DogMascot({
    super.key,
    this.size = 140,
    this.mood = DogMascotMood.happy,
    this.animate = true,
  });

  @override
  State<DogMascot> createState() => _DogMascotState();
}

class _DogMascotState extends State<DogMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final duration = widget.mood == DogMascotMood.sleeping
        ? const Duration(milliseconds: 3000)
        : widget.mood == DogMascotMood.excited || widget.mood == DogMascotMood.celebrating
            ? const Duration(milliseconds: 1400)
            : const Duration(milliseconds: 2200);

    _controller = AnimationController(
      vsync: this,
      duration: duration,
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant DogMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood != oldWidget.mood) {
      final duration = widget.mood == DogMascotMood.sleeping
          ? const Duration(milliseconds: 3000)
          : widget.mood == DogMascotMood.excited || widget.mood == DogMascotMood.celebrating
              ? const Duration(milliseconds: 1400)
              : const Duration(milliseconds: 2200);
      _controller.duration = duration;
    }

    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getAssetPath() {
    switch (widget.mood) {
      case DogMascotMood.neutral:
        return AppAssets.corgiNeutral;
      case DogMascotMood.happy:
        return AppAssets.corgiHappy;
      case DogMascotMood.sad:
        return AppAssets.corgiSad;
      case DogMascotMood.excited:
      case DogMascotMood.celebrating:
        return AppAssets.corgiExcited;
      case DogMascotMood.thinking:
        return AppAssets.corgiThinking;
      case DogMascotMood.sleeping:
        return AppAssets.corgiSleeping;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animVal = widget.animate ? _controller.value : 0.5;
        final isSleeping = widget.mood == DogMascotMood.sleeping;
        final isExcited = widget.mood == DogMascotMood.excited || widget.mood == DogMascotMood.celebrating;

        final bounce = isSleeping
            ? math.sin(animVal * math.pi) * 2.0
            : isExcited
                ? math.sin(animVal * math.pi) * 8.0
                : math.sin(animVal * math.pi) * 4.5;

        final shadowScale = isSleeping
            ? 1.0 - (bounce / 30.0)
            : 1.0 - (bounce / 20.0);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle soft ground shadow beneath the 3D clay puppy
              Positioned(
                bottom: widget.size * 0.04,
                child: Transform.scale(
                  scaleX: shadowScale,
                  scaleY: shadowScale * 0.9,
                  child: Container(
                    width: widget.size * 0.65,
                    height: widget.size * 0.12,
                    decoration: BoxDecoration(
                      color: AppColors.shadowWarm.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.all(
                        Radius.elliptical(widget.size * 0.35, widget.size * 0.08),
                      ),
                    ),
                  ),
                ),
              ),

              // Animated 3D Clay Puppy
              Transform.translate(
                offset: Offset(0, -bounce),
                child: SizedBox(
                  width: widget.size * 0.94,
                  height: widget.size * 0.94,
                  child: Image.asset(
                    _getAssetPath(),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return CustomPaint(
                        painter: _FallbackDogPainter(mood: widget.mood),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Fallback painter in case assets cannot be loaded in test harness
class _FallbackDogPainter extends CustomPainter {
  final DogMascotMood mood;

  _FallbackDogPainter({required this.mood});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const furBase = Color(0xFFF7B267);
    const snoutColor = Color(0xFFFFD199);
    const darkFeature = Color(0xFF332018);

    // Head
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.5),
      width: w * 0.65,
      height: h * 0.60,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.28)),
      Paint()..color = furBase,
    );

    // Snout
    final snoutRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.60),
      width: w * 0.42,
      height: h * 0.30,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(snoutRect, Radius.circular(w * 0.18)),
      Paint()..color = snoutColor,
    );

    // Eyes
    canvas.drawCircle(Offset(w * 0.38, h * 0.44), w * 0.05, Paint()..color = darkFeature);
    canvas.drawCircle(Offset(w * 0.62, h * 0.44), w * 0.05, Paint()..color = darkFeature);

    // Nose
    canvas.drawCircle(Offset(w * 0.5, h * 0.56), w * 0.04, Paint()..color = darkFeature);
  }

  @override
  bool shouldRepaint(covariant _FallbackDogPainter oldDelegate) =>
      oldDelegate.mood != mood;
}
