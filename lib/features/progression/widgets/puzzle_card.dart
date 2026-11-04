import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../game/models/puzzle.dart';
import '../models/puzzle_progress.dart';

class PuzzleCard extends StatelessWidget {
  final Puzzle puzzle;
  final PuzzleProgress? progress;
  final bool isUnlocked;
  final bool isCurrentAvailable;
  final VoidCallback onTap;
  final VoidCallback onLockedTap;

  const PuzzleCard({
    super.key,
    required this.puzzle,
    required this.progress,
    required this.isUnlocked,
    required this.isCurrentAvailable,
    required this.onTap,
    required this.onLockedTap,
  });

  String _formatTime(int? totalSeconds) {
    if (totalSeconds == null) return '--:--';
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress?.isCompleted ?? false;
    final bestTime = progress?.bestTimeSeconds;

    // Card background & border styling
    Color cardBg = AppColors.card;
    Color borderColor = AppColors.cardBorder;
    if (isCurrentAvailable) {
      borderColor = AppColors.primary;
      cardBg = AppColors.surfaceElevated;
    } else if (isCompleted) {
      borderColor = AppColors.success.withValues(alpha: 0.5);
    } else if (!isUnlocked) {
      cardBg = AppColors.background.withValues(alpha: 0.6);
      borderColor = AppColors.cardBorder.withValues(alpha: 0.6);
    }

    return GestureDetector(
      onTap: isUnlocked ? onTap : onLockedTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isCurrentAvailable ? 2.2 : 1.5,
          ),
          boxShadow: isUnlocked
              ? const [
                  BoxShadow(
                    color: AppColors.shadowWarm,
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: Level badge + Status icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? AppColors.primaryLight.withValues(alpha: 0.6)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Level ${puzzle.levelNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isUnlocked ? AppColors.text : AppColors.textMuted,
                    ),
                  ),
                ),
                _buildStatusIcon(isCompleted),
              ],
            ),

            const SizedBox(height: 10),

            // Puzzle Title
            Text(
              puzzle.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isUnlocked ? AppColors.text : AppColors.textMuted,
              ),
            ),

            const SizedBox(height: 8),

            // Bottom info: Best time or Status indicator
            Row(
              children: [
                if (isCompleted && bestTime != null) ...[
                  const Icon(Icons.timer_outlined, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    'Best: ${_formatTime(bestTime)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLight,
                    ),
                  ),
                ] else if (isCurrentAvailable) ...[
                  const PawIcon(size: 14, color: AppColors.primaryDark),
                  const SizedBox(width: 4),
                  const Text(
                    'Next Up',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ] else if (!isUnlocked) ...[
                  const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  const Text(
                    'Locked',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Ready',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(bool isCompleted) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 14,
          color: Colors.white,
        ),
      );
    }

    if (!isUnlocked) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock_rounded,
          size: 14,
          color: AppColors.textMuted,
        ),
      );
    }

    if (isCurrentAvailable) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          size: 14,
          color: Colors.white,
        ),
      );
    }

    return const SizedBox(width: 22, height: 22);
  }
}
