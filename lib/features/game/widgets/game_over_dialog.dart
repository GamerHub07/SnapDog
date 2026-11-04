import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/dog_mascot.dart';
import '../../../shared/widgets/snap_dog_button.dart';

class GameOverDialog extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onHome;

  const GameOverDialog({
    super.key,
    required this.onRetry,
    required this.onHome,
  });

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
              const DogMascot(size: 90, mood: DogMascotMood.sad, animate: false),
              const SizedBox(height: 12),
              const Text(
                'Game Over',
                style: AppTextStyles.displayMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                "Don't worry, every puppy stumbles! Give it another try.",
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.clashRed.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, size: 18, color: AppColors.clashRed),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Mistakes used: 3/3',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.clashRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SnapDogButton(
                label: 'Retry',
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: onRetry,
                width: double.infinity,
              ),
              const SizedBox(height: 12),
              SnapDogButton(
                label: 'Home',
                icon: const Icon(Icons.home_rounded, color: AppColors.text),
                variant: SnapDogButtonVariant.outline,
                onPressed: onHome,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
