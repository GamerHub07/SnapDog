import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/confetti_celebration.dart';
import '../../../shared/widgets/dog_mascot.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../../shared/widgets/snap_dog_button.dart';

class GameCompletionScreen extends StatelessWidget {
  final int timeSeconds;
  final int hintsUsed;
  final int mistakes;
  final int? bestTimeSeconds;
  final bool isNewBestTime;
  final String puzzleTitle;
  final VoidCallback onNextPuzzle;
  final VoidCallback? onReplay;
  final VoidCallback onHome;

  const GameCompletionScreen({
    super.key,
    required this.timeSeconds,
    required this.hintsUsed,
    this.mistakes = 0,
    this.bestTimeSeconds,
    this.isNewBestTime = false,
    required this.puzzleTitle,
    required this.onNextPuzzle,
    this.onReplay,
    required this.onHome,
  });

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ConfettiCelebration(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Celebratory Puppy Mascot Animation
                  const DogMascot(
                    size: 160,
                    mood: DogMascotMood.excited,
                  ),
                const SizedBox(height: 16),

                // Victory Title
                Text(
                  'Pawsome Victory!',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: isDark ? const Color(0xFFFFF4EC) : AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'All 10 dogs placed happily in $puzzleTitle!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? const Color(0xFF9E8B7F) : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Best Time Celebration Badge if new best time
                if (isNewBestTime) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.gold, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'New Personal Best Time!',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isDark ? const Color(0xFFFFD54F) : AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Stats Card (Time, Best Time, Hints Used, Mistakes)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? (isDark ? const Color(0xFF2A221E) : AppColors.card),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3F332C) : AppColors.cardBorder,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black26 : AppColors.shadowWarm,
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Time Stat
                      Column(
                        children: [
                          const Icon(Icons.timer_outlined, color: AppColors.primary, size: 26),
                          const SizedBox(height: 6),
                          Text(
                            _formatTime(timeSeconds),
                            style: AppTextStyles.displayMedium.copyWith(
                              fontSize: 20,
                              color: isDark ? const Color(0xFFFFF4EC) : AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text('Time', style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? const Color(0xFF9E8B7F) : AppColors.textMuted,
                          )),
                        ],
                      ),
                      // Best Time Stat (if available and not already identical to current time when not isNewBestTime)
                      if (bestTimeSeconds != null) ...[
                        Container(height: 44, width: 1, color: isDark ? const Color(0xFF3F332C) : AppColors.cardBorder),
                        Column(
                          children: [
                            const Icon(Icons.emoji_events_outlined, color: AppColors.gold, size: 26),
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(bestTimeSeconds!),
                              style: AppTextStyles.displayMedium.copyWith(
                                fontSize: 20,
                                color: isDark ? const Color(0xFFFFD54F) : AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('Best', style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? const Color(0xFF9E8B7F) : AppColors.textMuted,
                            )),
                          ],
                        ),
                      ],
                      Container(height: 44, width: 1, color: isDark ? const Color(0xFF3F332C) : AppColors.cardBorder),
                      // Hints Used Stat
                      Column(
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.gold, size: 26),
                          const SizedBox(height: 6),
                          Text(
                            '$hintsUsed',
                            style: AppTextStyles.displayMedium.copyWith(
                              fontSize: 20,
                              color: isDark ? const Color(0xFFFFF4EC) : AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text('Hints', style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? const Color(0xFF9E8B7F) : AppColors.textMuted,
                          )),
                        ],
                      ),
                      if (mistakes > 0) ...[
                        Container(height: 44, width: 1, color: isDark ? const Color(0xFF3F332C) : AppColors.cardBorder),
                        // Mistakes Stat
                        Column(
                          children: [
                            const Icon(Icons.close_rounded, color: AppColors.clashRed, size: 26),
                            const SizedBox(height: 6),
                            Text(
                              '$mistakes',
                              style: AppTextStyles.displayMedium.copyWith(
                                fontSize: 20,
                                color: AppColors.clashRed,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('Mistakes', style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? const Color(0xFF9E8B7F) : AppColors.textMuted,
                            )),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Next Puzzle Button
                SnapDogButton(
                  label: 'Next Puzzle',
                  icon: const PawIcon(size: 20, color: Colors.white),
                  onPressed: onNextPuzzle,
                  width: double.infinity,
                ),
                if (onReplay != null) ...[
                  const SizedBox(height: 12),
                  // Replay Puzzle Button
                  SnapDogButton(
                    label: 'Replay Puzzle',
                    icon: Icon(Icons.replay_rounded, color: isDark ? const Color(0xFFFFF4EC) : AppColors.primaryDark),
                    variant: SnapDogButtonVariant.secondary,
                    onPressed: onReplay,
                    width: double.infinity,
                  ),
                ],
                const SizedBox(height: 12),

                // Home Button
                SnapDogButton(
                  label: 'Back to Home',
                  icon: Icon(Icons.home_rounded, color: isDark ? const Color(0xFFFFF4EC) : AppColors.text),
                  variant: SnapDogButtonVariant.outline,
                  onPressed: onHome,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
