import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/dog_mascot.dart';
import '../../../shared/widgets/snap_dog_button.dart';

class PauseDialog extends StatelessWidget {
  final int timerSeconds;
  final String difficultyLabel;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  const PauseDialog({
    super.key,
    required this.timerSeconds,
    required this.difficultyLabel,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Center(
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.cardBorder, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowDark,
                offset: Offset(0, 10),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DogMascot(size: 90, mood: DogMascotMood.thinking),
              const SizedBox(height: 12),
              const Text(
                'Game Paused',
                style: AppTextStyles.displayMedium,
              ),
              const SizedBox(height: 6),
              Text(
                '$difficultyLabel • Time: ${_formatTime(timerSeconds)}',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),
              SnapDogButton(
                label: 'Resume Game',
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                onPressed: onResume,
                width: double.infinity,
              ),
              const SizedBox(height: 12),
              SnapDogButton(
                label: 'Restart Puzzle',
                icon: const Icon(Icons.refresh_rounded, color: AppColors.text),
                variant: SnapDogButtonVariant.secondary,
                onPressed: onRestart,
                width: double.infinity,
              ),
              const SizedBox(height: 12),
              SnapDogButton(
                label: 'Quit to Home',
                icon: const Icon(Icons.home_rounded, color: AppColors.text),
                variant: SnapDogButtonVariant.outline,
                onPressed: onQuit,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
