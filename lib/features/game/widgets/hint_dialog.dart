import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/sound_haptic_helper.dart';
import '../../../shared/widgets/snap_dog_button.dart';

/// A polished, custom animated dialog displayed when a player requests a hint.
class HintDialog extends StatelessWidget {
  final int hintsUsed;
  final String? message;
  final VoidCallback? onDismissed;

  const HintDialog({
    super.key,
    required this.hintsUsed,
    this.message,
    this.onDismissed,
  });

  /// Displays the hint dialog as an overlay above the screen.
  /// Never modifies or shifts the gameplay board layout.
  static Future<void> show(
    BuildContext context, {
    required int hintsUsed,
    String? message,
    VoidCallback? onDismissed,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Hint',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, anim, secondaryAnim) {
        return HintDialog(
          hintsUsed: hintsUsed,
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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          onDismissed?.call();
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
                // Thinking Corgi illustration
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    AppAssets.corgiThinking,
                    width: 85,
                    height: 85,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.lightbulb_rounded,
                      size: 64,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Heading
                const Text(
                  'Puppy Hint',
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
                  message ?? 'A little pup belongs here! Look for the highlighted spot on your board.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Hint counter badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lightbulb_rounded, size: 16, color: AppColors.gold),
                      const SizedBox(width: 6),
                      Text(
                        'Hints used: $hintsUsed',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8D6E14),
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
                    onDismissed?.call();
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
