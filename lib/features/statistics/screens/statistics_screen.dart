import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../game/services/puzzle_repository.dart';
import '../../game/providers/game_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  String _formatTime(int? totalSeconds) {
    if (totalSeconds == null) return '--:--';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Puppy Statistics'),
      ),
      body: SafeArea(
        child: statsAsync.when(
          data: (stats) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Highlight Card
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
                              'Overview',
                              style: AppTextStyles.titleMedium.copyWith(color: AppColors.text),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildOverviewTile(
                              title: 'Played',
                              value: '${stats.gamesPlayed}',
                              icon: Icons.games_outlined,
                              color: AppColors.primary,
                            ),
                            _buildOverviewTile(
                              title: 'Completed',
                              value: '${stats.gamesWon}',
                              icon: Icons.emoji_events_outlined,
                              color: AppColors.gold,
                            ),
                            _buildOverviewTile(
                              title: 'Win Rate',
                              value: '${stats.winRate.toStringAsFixed(0)}%',
                              icon: Icons.pie_chart_outline_rounded,
                              color: AppColors.success,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Streaks Card
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
                            Text('Streaks', style: AppTextStyles.titleMedium.copyWith(color: AppColors.text)),
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

                  // Best Times Card
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
                            const Icon(Icons.timer_outlined, color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Text('Best Completion Times', style: AppTextStyles.titleMedium.copyWith(color: AppColors.text)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...PuzzleRepository.puzzles.map((puzzle) {
                          final bestTime = stats.bestTimeSeconds[puzzle.id];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const PawIcon(size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text('${puzzle.title} (${puzzle.difficultyLabel})',
                                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Text(
                                    _formatTime(bestTime),
                                    style: AppTextStyles.titleSmall.copyWith(
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
        ),
      ],
    );
  }
}
