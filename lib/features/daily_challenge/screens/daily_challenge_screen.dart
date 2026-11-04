import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../../shared/widgets/snap_dog_button.dart';
import '../../game/models/puzzle.dart';
import '../../game/providers/game_provider.dart';
import '../../game/screens/game_screen.dart';
import '../../game/services/puzzle_repository.dart';
import '../models/daily_challenge_record.dart';
import '../providers/daily_challenge_provider.dart';
import '../services/daily_puzzle_scheduler.dart';
import '../services/daily_share_helper.dart';
import '../widgets/daily_calendar_view.dart';

class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  void _startDailyPuzzle(BuildContext context, WidgetRef ref, Puzzle puzzle, DateTime date) {
    final puzzleIndex = PuzzleRepository.getPuzzleIndex(puzzle);
    final targetIndex = puzzleIndex >= 0 ? puzzleIndex : 0;

    ref.read(puzzleGameProvider.notifier).loadPuzzle(targetIndex);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          puzzleIndex: targetIndex,
          isDailyChallenge: true,
          dailyDate: date,
        ),
      ),
    );
  }

  void _showPastResultDialog(BuildContext context, DateTime date, DailyChallengeRecord record) {
    final dateStr = DailyShareHelper.formatDate(date);
    final timeStr = DailyShareHelper.formatTime(record.timeSeconds);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const PawIcon(size: 20, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text(dateStr, style: AppTextStyles.titleMedium),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(
                    icon: Icons.timer_outlined,
                    iconColor: AppColors.primary,
                    value: timeStr,
                    label: 'Time',
                  ),
                  _StatColumn(
                    icon: Icons.lightbulb_outline_rounded,
                    iconColor: AppColors.gold,
                    value: '${record.hintsUsed}',
                    label: 'Hints',
                  ),
                  if (record.mistakes > 0)
                    _StatColumn(
                      icon: Icons.close_rounded,
                      iconColor: AppColors.clashRed,
                      value: '${record.mistakes}',
                      label: 'Mistakes',
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyState = ref.watch(dailyChallengeProvider);
    final today = ref.watch(clockProvider)();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    final dailyPuzzle = DailyPuzzleScheduler.getPuzzleForDate(todayNormalized);
    final isCompletedToday = dailyState.isCompletedOn(todayNormalized);
    final effectiveStreak = dailyState.getEffectiveStreak(todayNormalized);
    final longestStreak = dailyState.longestStreak;

    final dateStr = DailyShareHelper.formatDate(todayNormalized);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            PawIcon(size: 20, color: AppColors.primaryDark),
            SizedBox(width: 8),
            Text('Daily Challenge', style: AppTextStyles.titleLarge),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Card: Today's Challenge
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7ED), Color(0xFFFDECDA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.secondary, width: 1.5),
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
                    // Date & Status Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryDark),
                            const SizedBox(width: 6),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompletedToday
                                ? AppColors.success.withValues(alpha: 0.18)
                                : AppColors.gold.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompletedToday ? Icons.check_circle_rounded : Icons.pending_rounded,
                                size: 14,
                                color: isCompletedToday ? AppColors.success : AppColors.primaryDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCompletedToday ? 'Completed' : 'Not Started',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isCompletedToday ? AppColors.success : AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Puzzle title & Difficulty Badge
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dailyPuzzle.title,
                                style: AppTextStyles.titleLarge.copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'A unique challenge hand-picked for today!',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            dailyPuzzle.difficultyLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Streaks summary inside hero card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$effectiveStreak Days',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const Text('Streak', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                                ],
                              ),
                            ],
                          ),
                          Container(width: 1, height: 26, color: AppColors.cardBorder),
                          Row(
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$longestStreak Days',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const Text('Best', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Play / Replay Button
                    SnapDogButton(
                      label: isCompletedToday ? 'Replay Challenge' : 'Play Today\'s Challenge',
                      icon: Icon(
                        isCompletedToday ? Icons.replay_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _startDailyPuzzle(context, ref, dailyPuzzle, todayNormalized),
                      width: double.infinity,
                      height: 50,
                      variant: isCompletedToday ? SnapDogButtonVariant.secondary : SnapDogButtonVariant.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Calendar Preview Card
              Text(
                'Challenge Calendar',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              DailyCalendarView(
                today: todayNormalized,
                state: dailyState,
                onSelectCompletedDate: (date, record) {
                  _showPastResultDialog(context, date, record);
                },
              ),
              const SizedBox(height: 20),

              // Rewards & Achievements
              Text(
                'Streak Rewards',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...DailyMilestones.allRewards.map((reward) {
                final isEarned = dailyState.isRewardEarned(reward.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isEarned ? AppColors.gold : AppColors.cardBorder,
                      width: isEarned ? 1.5 : 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowWarm,
                        offset: Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isEarned
                              ? AppColors.gold.withValues(alpha: 0.2)
                              : AppColors.surfaceElevated,
                          shape: BoxShape.circle,
                        ),
                        child: Text(reward.iconEmoji, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reward.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isEarned ? AppColors.text : AppColors.textLight,
                              ),
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
                          color: isEarned
                              ? AppColors.success.withValues(alpha: 0.15)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isEarned ? 'Unlocked' : '${reward.streakDays}d Streak',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isEarned ? AppColors.success : AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatColumn({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
