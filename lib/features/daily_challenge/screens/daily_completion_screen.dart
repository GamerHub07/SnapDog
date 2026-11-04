import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/confetti_celebration.dart';
import '../../../shared/widgets/dog_avatar.dart';
import '../../../shared/widgets/dog_mascot.dart';
import '../../../shared/widgets/snap_dog_button.dart';
import '../../game/models/dog_breed.dart';
import '../models/daily_challenge_record.dart';
import '../services/daily_share_helper.dart';

class DailyCompletionScreen extends StatefulWidget {
  final DateTime date;
  final int timeSeconds;
  final int hintsUsed;
  final int mistakes;
  final int currentStreak;
  final int longestStreak;
  final List<DailyReward> newlyUnlockedRewards;
  final VoidCallback onHome;

  const DailyCompletionScreen({
    super.key,
    required this.date,
    required this.timeSeconds,
    required this.hintsUsed,
    this.mistakes = 0,
    required this.currentStreak,
    required this.longestStreak,
    this.newlyUnlockedRewards = const [],
    required this.onHome,
  });

  @override
  State<DailyCompletionScreen> createState() => _DailyCompletionScreenState();
}

class _DailyCompletionScreenState extends State<DailyCompletionScreen> {
  bool _copied = false;

  String _formatTime(int totalSeconds) {
    return DailyShareHelper.formatTime(totalSeconds);
  }

  String _getMotivationalMessage() {
    if (widget.currentStreak >= 30) {
      return 'Legendary Master Hound! 30+ Day Streak! 🌟';
    } else if (widget.currentStreak >= 7) {
      return 'Unstoppable Paw Power! 7+ Day Streak! 🔥';
    } else if (widget.currentStreak >= 3) {
      return 'Bark-tastic work! 3+ Day Streak rolling! 🐶';
    } else if (widget.currentStreak > 1) {
      return 'Great job! Streak is alive and kicking! 🐾';
    } else {
      return 'Pawsome! Today\'s challenge conquered! 🎉';
    }
  }

  Future<void> _share() async {
    final success = await DailyShareHelper.shareResult(
      date: widget.date,
      timeSeconds: widget.timeSeconds,
      hintsUsed: widget.hintsUsed,
      streakDays: widget.currentStreak,
    );

    if (mounted) {
      setState(() => _copied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Result shared & copied to clipboard!' : 'Result copied to clipboard!',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.primaryDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DailyShareHelper.formatDate(widget.date);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ConfettiCelebration(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Celebratory Puppy Mascot
                  const DogMascot(
                    size: 150,
                    mood: DogMascotMood.excited,
                  ),
                const SizedBox(height: 16),

                // Victory Title
                const Text(
                  'Daily Challenge Solved!',
                  style: AppTextStyles.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _getMotivationalMessage(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Daily Challenge • $dateStr',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Celebratory 3D Dog Avatars
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: DogBreed.values.map((breed) {
                    return DogAvatar.circularBadge(
                      breed: breed,
                      size: 34,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Newly Unlocked Milestone Banner
                if (widget.newlyUnlockedRewards.isNotEmpty) ...[
                  ...widget.newlyUnlockedRewards.map(
                    (reward) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowWarm,
                            offset: Offset(0, 3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(reward.iconEmoji, style: const TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'NEW BADGE UNLOCKED!',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.gold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  reward.title,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  reward.description,
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Streak Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF4E6), Color(0xFFFFEAD1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.secondary, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.currentStreak}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          const Text('Current Streak', style: AppTextStyles.bodySmall),
                        ],
                      ),
                      Container(height: 36, width: 1, color: AppColors.cardBorder),
                      Column(
                        children: [
                          Row(
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.longestStreak}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          const Text('Best Streak', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Card (Time, Hints, Mistakes)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowWarm,
                        offset: Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.timer_outlined, color: AppColors.primary, size: 26),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(widget.timeSeconds),
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          const Text('Time', style: AppTextStyles.bodySmall),
                        ],
                      ),
                      Container(height: 40, width: 1, color: AppColors.cardBorder),
                      Column(
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.gold, size: 26),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.hintsUsed}',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const Text('Hints', style: AppTextStyles.bodySmall),
                        ],
                      ),
                      Container(height: 40, width: 1, color: AppColors.cardBorder),
                      Column(
                        children: [
                          Icon(
                            widget.mistakes == 0 ? Icons.check_circle_outline_rounded : Icons.close_rounded,
                            color: widget.mistakes == 0 ? AppColors.success : AppColors.clashRed,
                            size: 26,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.mistakes}',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: widget.mistakes == 0 ? AppColors.primaryDark : AppColors.clashRed,
                            ),
                          ),
                          const Text('Mistakes', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Share Result Button
                SnapDogButton(
                  label: _copied ? 'Result Shared!' : 'Share Result',
                  icon: const Icon(Icons.share_rounded, size: 20, color: Colors.white),
                  onPressed: _share,
                  width: double.infinity,
                ),
                const SizedBox(height: 12),

                // Back to Home Button
                SnapDogButton(
                  label: 'Back to Home',
                  icon: const Icon(Icons.home_rounded, color: AppColors.text),
                  variant: SnapDogButtonVariant.secondary,
                  onPressed: widget.onHome,
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
