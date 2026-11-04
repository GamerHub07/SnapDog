import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/game_provider.dart';

/// Compact circular clay action controls matching Reference Image 2.
///
/// Features:
/// - Undo button (with badge indicating available undo actions)
/// - Reset button (with confirmation dialog)
/// - Hint button (with badge for hints used/available)
class GameControls extends ConsumerWidget {
  const GameControls({super.key});

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Reset Puzzle?', style: AppTextStyles.titleLarge),
          content: const Text(
            'Are you sure you want to restart this puzzle? Your dog placements, mistakes, and timer will be reset.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.primaryDark)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(puzzleGameProvider.notifier).resetPuzzle();
              },
              child: const Text(
                'Reset',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(puzzleGameProvider);
    final notifier = ref.read(puzzleGameProvider.notifier);

    final undoCount = gameState.undoStack.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Undo Button
          _CircularClayButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            badgeText: undoCount > 0 ? '$undoCount' : null,
            badgeColor: AppColors.error,
            isEnabled: !gameState.isGameOver && gameState.undoStack.isNotEmpty,
            onTap: notifier.undo,
          ),

          // Reset Puzzle Button (with confirmation)
          _CircularClayButton(
            icon: Icons.refresh_rounded,
            label: 'Reset',
            isEnabled: !gameState.isGameOver &&
                (gameState.placements.isNotEmpty ||
                    gameState.crosses.isNotEmpty ||
                    gameState.mistakes > 0 ||
                    gameState.hintsUsed > 0),
            onTap: () => _confirmReset(context, ref),
          ),

          // Hint Button
          _CircularClayButton(
            icon: Icons.lightbulb_rounded,
            label: 'Hint',
            badgeText: gameState.hintsUsed > 0 ? '${gameState.hintsUsed}' : null,
            badgeColor: AppColors.error,
            isEnabled: !gameState.isGameOver && gameState.dogCount < 10,
            onTap: notifier.useHint,
          ),
        ],
      ),
    );
  }
}

class _CircularClayButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isEnabled;
  final String? badgeText;
  final Color? badgeColor;

  const _CircularClayButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isEnabled = true,
    this.badgeText,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.42,
      child: Semantics(
        label: badgeText != null ? '$label ($badgeText)' : label,
        button: true,
        enabled: isEnabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isEnabled ? onTap : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.card,
                      border: Border.all(color: AppColors.cardBorder, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowWarm,
                          offset: Offset(0, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 26,
                        color: isEnabled ? AppColors.text : AppColors.textMuted,
                      ),
                    ),
                  ),

                  // Top-right notification badge (matching Reference Image 2 red pills)
                  if (badgeText != null && isEnabled)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor ?? AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowDark,
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        child: Center(
                          child: Text(
                            badgeText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isEnabled ? AppColors.text : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
