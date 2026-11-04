import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../game/providers/game_provider.dart';

class HomeStatsPreview extends ConsumerWidget {
  const HomeStatsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return statsAsync.when(
      data: (stats) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowWarm,
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: const PawIcon(size: 20, color: AppColors.primary),
                value: '${stats.gamesPlayed}',
                label: 'Games Played',
              ),
              Container(width: 1, height: 36, color: AppColors.cardBorder),
              _buildStatItem(
                icon: const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 22),
                value: '${stats.gamesWon}',
                label: 'Completed',
              ),
              Container(width: 1, height: 36, color: AppColors.cardBorder),
              _buildStatItem(
                icon: const Icon(Icons.local_fire_department_rounded, color: AppColors.primaryDark, size: 22),
                value: '${stats.currentStreak}',
                label: 'Day Streak',
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 30,
          width: 30,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatItem({
    required Widget icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}
