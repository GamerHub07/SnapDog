import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../daily_challenge/models/daily_challenge_record.dart';
import '../../daily_challenge/providers/daily_challenge_provider.dart';
import '../../game/providers/game_provider.dart';
import '../../game/services/puzzle_repository.dart';
import '../../progression/providers/progression_provider.dart';

/// Progress and statistics screen for SnapDog.
///
/// Displays:
/// - Games Played
/// - Levels Completed
/// - Current Day Streak & Best Streak
/// - Milestones & Achievements
/// - Detailed Completion History & Best Times
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  String _formatTime(int? totalSeconds) {
    if (totalSeconds == null) return '--:--';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final progression = ref.watch(progressionProvider);
    final dailyState = ref.watch(dailyChallengeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            PawIcon(size: 20, color: AppColors.primaryDark),
            SizedBox(width: 8),
            Text('Puppy Progress'),
          ],
        ),
      ),
      body: SafeArea(
        child: statsAsync.when(
          data: (stats) {
            final completedCount = progression.completedPuzzlesCount;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Overview Highlight Card (Games Played, Levels Completed, Day Streak, Win Rate)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.cardBorder, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowWarm,
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const PawIcon(size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Progress & Stats Overview',
                              style: AppTextStyles.titleMedium.copyWith(color: AppColors.text),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildOverviewTile(
                              title: 'Games Played',
                              value: '${stats.gamesPlayed}',
                              icon: Icons.sports_esports_rounded,
                              color: AppColors.primary,
                            ),
                            _buildOverviewTile(
                              title: 'Levels Completed',
                              value: '$completedCount',
                              icon: Icons.emoji_events_rounded,
                              color: AppColors.gold,
                            ),
                            _buildOverviewTile(
                              title: 'Day Streak',
                              value: '${stats.currentStreak}',
                              icon: Icons.local_fire_department_rounded,
                              color: AppColors.primaryDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Streaks Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.cardBorder, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowWarm,
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded, color: AppColors.primaryDark, size: 22),
                            const SizedBox(width: 8),
                            Text('Streak Stats', style: AppTextStyles.titleMedium.copyWith(color: AppColors.text)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Current Streak', style: AppTextStyles.bodySmall),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${stats.currentStreak} Days',
                                      style: AppTextStyles.displayMedium.copyWith(
                                        fontSize: 22,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF2DF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Best Streak', style: AppTextStyles.bodySmall),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${stats.bestStreak} Days',
                                      style: AppTextStyles.displayMedium.copyWith(
                                        fontSize: 22,
                                        color: AppColors.text,
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
                  ),
                  const SizedBox(height: 20),

                  // 3. Milestones & Achievements Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.cardBorder, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowWarm,
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.military_tech_rounded, color: AppColors.gold, size: 22),
                            const SizedBox(width: 8),
                            Text('Milestone Achievements', style: AppTextStyles.titleMedium.copyWith(color: AppColors.text)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ...DailyMilestones.allRewards.map((reward) {
                          final isEarned = dailyState.isRewardEarned(reward.id);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isEarned ? const Color(0xFFFFF9E6) : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isEarned ? AppColors.gold : AppColors.cardBorder,
                                width: isEarned ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(reward.iconEmoji, style: const TextStyle(fontSize: 26)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reward.title,
                                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        reward.description,
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isEarned ? AppColors.gold : const Color(0xFFE2D6CB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isEarned ? 'Unlocked' : '${reward.streakDays}d Streak',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isEarned ? Colors.white : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Detailed Completion History & Best Times Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.cardBorder, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowWarm,
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.history_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Text('Level Completion History', style: AppTextStyles.titleMedium.copyWith(color: AppColors.text)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...PuzzleRepository.puzzles.map((puzzle) {
                          final prog = progression.getProgress(puzzle.id);
                          final bestTime = stats.bestTimeSeconds[puzzle.id] ?? prog?.bestTimeSeconds;
                          final isDone = prog?.isCompleted ?? false;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDone ? AppColors.success.withValues(alpha: 0.3) : AppColors.cardBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      size: 18,
                                      color: isDone ? AppColors.success : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${puzzle.title} (${puzzle.difficultyLabel})',
                                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                        if (isDone && prog?.completedAt != null)
                                          Text(
                                            'Completed ${_formatDate(prog!.completedAt!)} • ${prog.hintsUsed} hints',
                                            style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDone ? AppColors.card : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Text(
                                    _formatTime(bestTime),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: bestTime != null ? AppColors.text : AppColors.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildOverviewTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
