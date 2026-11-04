import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../daily_challenge/models/daily_challenge_state.dart';
import '../../daily_challenge/providers/daily_challenge_provider.dart';
import '../../daily_challenge/screens/daily_challenge_screen.dart';
import '../../daily_challenge/services/daily_puzzle_scheduler.dart';

/// Card showing the latest completed daily challenge on the home screen.
///
/// Features:
/// - Displays the latest completed challenge date, puzzle title, completion time, and streak badge
/// - Tap to view daily challenge details or replay
/// - Hides cleanly if no daily challenge has ever been completed yet
class LatestCompletedChallengeCard extends ConsumerWidget {
  const LatestCompletedChallengeCard({super.key});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyState = ref.watch(dailyChallengeProvider);
    final lastKey = dailyState.lastCompletedDateKey;

    if (lastKey == null || !dailyState.history.containsKey(lastKey)) {
      return const SizedBox.shrink();
    }

    final record = dailyState.history[lastKey]!;
    final completedDate = DailyChallengeState.parseDateKey(lastKey);
    final puzzle = DailyPuzzleScheduler.getPuzzleForDate(completedDate);

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${months[completedDate.month - 1]} ${completedDate.day}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowWarm,
            offset: Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Latest Completed Challenge',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      puzzle.title,
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Solved in ${_formatTime(record.timeSeconds)} • ${record.hintsUsed} hints • ${record.mistakes} mistakes',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DailyChallengeScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      PawIcon(size: 14, color: AppColors.primaryDark),
                      SizedBox(width: 4),
                      Text(
                        'View',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
