import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/game_provider.dart';

class GameControls extends ConsumerWidget {
  const GameControls({super.key});

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
              child: const Text('Reset', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Undo Button
          _ControlButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            isEnabled: !gameState.isGameOver && gameState.undoStack.isNotEmpty,
            onTap: notifier.undo,
          ),

          // Reset Puzzle Button (with confirmation)
          _ControlButton(
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
          _ControlButton(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Hint',
            badgeText: gameState.hintsUsed > 0 ? '${gameState.hintsUsed}' : null,
            badgeColor: AppColors.gold,
            isEnabled: !gameState.isGameOver && gameState.dogCount < 10,
            onTap: notifier.useHint,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isEnabled;
  final String? badgeText;
  final Color? badgeColor;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isEnabled = true,
    this.badgeText,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isEnabled ? AppColors.text : AppColors.textMuted.withValues(alpha: 0.5);

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cardBorder,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowWarm,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: effectiveColor, size: 24),
                ),
                if (badgeText != null)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor ?? AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowWarm,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        badgeText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: effectiveColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
