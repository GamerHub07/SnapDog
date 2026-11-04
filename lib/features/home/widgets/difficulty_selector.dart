import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../game/services/puzzle_repository.dart';

class DifficultySelector extends StatelessWidget {
  final int selectedPuzzleIndex;
  final ValueChanged<int> onSelected;

  const DifficultySelector({
    super.key,
    required this.selectedPuzzleIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final puzzles = PuzzleRepository.puzzles;

    return Container(
      padding: const EdgeInsets.all(5),
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
        children: List.generate(puzzles.length, (index) {
          final puzzle = puzzles[index];
          final isSelected = index == selectedPuzzleIndex;
          final pawCount = index + 1;

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: AppColors.shadowWarm,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      puzzle.difficultyLabel,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.textLight,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pawCount,
                        (_) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: PawIcon(
                            size: 11,
                            color: isSelected ? Colors.white70 : AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
