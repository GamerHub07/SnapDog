import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/sound_haptic_helper.dart';
import '../../../shared/widgets/snap_dog_button.dart';

/// A polished, custom animated dialog displayed when a player makes a mistake.
class MistakeDialog extends StatefulWidget {
  final int mistakes;
  final String? message;
  final VoidCallback? onDismissed;

  const MistakeDialog({
    super.key,
    required this.mistakes,
    this.message,
    this.onDismissed,
  });

  /// Displays the mistake dialog as an overlay above the screen.
  /// Never modifies or shifts the gameplay board layout.
  static Future<void> show(
    BuildContext context, {
    required int mistakes,
    String? message,
    VoidCallback? onDismissed,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Mistake',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, anim, secondaryAnim) {
        return MistakeDialog(
          mistakes: mistakes,
          message: message,
          onDismissed: onDismissed,
        );
      },
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<MistakeDialog> createState() => _MistakeDialogState();
}

class _MistakeDialogState extends State<MistakeDialog> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          widget.onDismissed?.call();
        }
      },
      child: Center(
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.cardBorder, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowDark,
                offset: Offset(0, 10),
                blurRadius: 24,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated shaking / bouncing sad Corgi
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    final t = _shakeController.value;
                    // Gentle decaying horizontal shake and cute bounce
                    final decay = (1.0 - t);
                    final shakeX = math.sin(t * math.pi * 6) * 5.0 * decay;
                    final bounceY = -math.sin(t * math.pi * 2).abs() * 3.0 * decay;
                    return Transform.translate(
                      offset: Offset(shakeX, bounceY),
                      child: child,
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppAssets.corgiSad,
                      width: 85,
                      height: 85,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.pets_rounded,
                        size: 64,
                        color: AppColors.clashRed,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Heading
                const Text(
                  'Oops! Wrong Spot',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),

                // Message
                Text(
                  widget.message ?? "That isn't the right place for this puppy.",
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Mistake counter badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.clashRed.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.close_rounded, size: 16, color: AppColors.clashRed),
                      const SizedBox(width: 6),
                      Text(
                        'Mistakes: ${widget.mistakes}/3',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.clashRed,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // One "Got it" button
                SnapDogButton(
                  label: 'Got it',
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    SoundHapticHelper.buttonClick();
                    Navigator.of(context).pop();
                    widget.onDismissed?.call();
                  },
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
