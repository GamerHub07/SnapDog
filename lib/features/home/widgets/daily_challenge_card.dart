import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../daily_challenge/providers/daily_challenge_provider.dart';
import '../../daily_challenge/screens/daily_challenge_screen.dart';
import '../../daily_challenge/services/daily_puzzle_scheduler.dart';

class DailyChallengeCard extends ConsumerWidget {
  final VoidCallback? onPlay;

  const DailyChallengeCard({
    super.key,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(clockProvider)();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final dailyState = ref.watch(dailyChallengeProvider);
    final isCompleted = dailyState.isCompletedOn(todayNormalized);
    final streak = dailyState.getEffectiveStreak(todayNormalized);
    final dailyPuzzle = DailyPuzzleScheduler.getPuzzleForDate(todayNormalized);

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${months[today.month - 1]} ${today.day}';

    void handleTap() {
      if (onPlay != null) {
        onPlay!();
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const DailyChallengeScreen(),
          ),
        );
      }
    }

    return InkWell(
      onTap: handleTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFF2DF),
              Color(0xFFFDE7D1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCompleted ? AppColors.success.withValues(alpha: 0.5) : AppColors.secondary,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowWarm,
              offset: Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Badge / Calendar Icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowWarm,
                    offset: Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PawIcon(size: 22, color: AppColors.primaryDark),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Middle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCompleted ? AppColors.success : AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isCompleted ? 'COMPLETED' : 'DAILY PUZZLE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (streak > 0) ...[
                        Text(
                          '🔥 $streak',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dailyPuzzle.title,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCompleted
                        ? 'Tap to view details or replay!'
                        : '${dailyPuzzle.difficultyLabel} • Place 10 dogs with no touching',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),

            // Play / view button
            IconButton(
              onPressed: handleTap,
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.success : AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowWarm,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
