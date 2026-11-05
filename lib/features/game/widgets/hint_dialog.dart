import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/sound_haptic_helper.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../../shared/widgets/snap_dog_button.dart';
import '../models/progressive_hint.dart';
import '../providers/game_provider.dart';

/// A polished, custom animated dialog displayed when a player requests a hint.
/// Supports SnapDog's Step 3 three-stage progressive hints:
/// - Stage 1: Constraint Guidance
/// - Stage 2: Logical Elimination
/// - Stage 3: Exact Placement
class HintDialog extends ConsumerWidget {
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

  Color _stageColor(HintStage stage) {
    switch (stage) {
      case HintStage.guidance:
        return const Color(0xFFE67E22);
      case HintStage.elimination:
        return const Color(0xFFD32F2F);
      case HintStage.placement:
        return const Color(0xFF2E7D32);
    }
  }

  String _stageBadgeText(HintStage stage) {
    switch (stage) {
      case HintStage.guidance:
        return 'Clue 1 of 3: Guidance';
      case HintStage.elimination:
        return 'Clue 2 of 3: Elimination';
      case HintStage.placement:
        return 'Clue 3 of 3: Placement';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(puzzleGameProvider);
    final hint = gameState.activeHint;
    final currentHintsUsed = gameState.hintsUsed > 0 ? gameState.hintsUsed : hintsUsed;
    final currentExplanation = hint?.message ?? message ?? 'A little pup belongs here! Look for the highlighted spot on your board.';

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
                    width: 76,
                    height: 76,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.lightbulb_rounded,
                      size: 56,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Heading
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PawIcon(
                      key: ValueKey('cell_hint'),
                      size: 18,
                      color: AppColors.gold,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Puppy Hint',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Contextual subtitle
                const Text(
                  'A little pup belongs here!',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Progressive stage badge
                if (hint != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: _stageColor(hint.stage).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _stageColor(hint.stage).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _stageBadgeText(hint.stage),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _stageColor(hint.stage),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hint.title,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),

                // Detailed explanation message
                Text(
                  currentExplanation,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textLight,
                    fontSize: 13.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Hint counter badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                      const Icon(Icons.lightbulb_rounded, size: 15, color: AppColors.gold),
                      const SizedBox(width: 6),
                      Text(
                        'Hints used: $currentHintsUsed',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8D6E14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Primary Got it button
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

                // Optional Next Clue button
                if (hint != null && hint.stage != HintStage.placement && !hint.isSolved) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      SoundHapticHelper.buttonClick();
                      ref.read(puzzleGameProvider.notifier).requestNextHintStage();
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                    label: const Text(
                      'Next Clue',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
