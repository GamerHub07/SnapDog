import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/dog_avatar.dart';
import '../models/dog_breed.dart';
import '../providers/game_provider.dart';

/// Horizontal preview collection row showing the 10 dogs for this puzzle.
///
/// Responsive to small phone screens (320px) as well as modern large devices.
/// Unplaced dogs appear as soft silhouettes; as dogs are placed on the board,
/// each corresponding puppy lights up in full vibrant 3D clay color!
class DogBreedCollectionRow extends ConsumerWidget {
  const DogBreedCollectionRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(puzzleGameProvider);
    final puzzle = gameState.puzzle;
    final breedAssignment = DogBreedAssignment.forPuzzle(puzzle);
    final orderedBreeds = breedAssignment.orderedBreeds;
    final placedCount = gameState.dogCount.clamp(0, 10);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // Dynamically compute avatar size to fit all 10 dogs on any screen width
        final double itemSize = ((availableWidth - 40) / 10).clamp(16.0, 24.0);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.7), width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(orderedBreeds.length, (index) {
              final breed = orderedBreeds[index];
              final isPlaced = index < placedCount;

              return _DogPreviewAvatar(
                breed: breed,
                isPlaced: isPlaced,
                size: itemSize,
              );
            }),
          ),
        );
      },
    );
  }
}

/// Standalone preview avatar for the collection row.
///
/// Uses direct painting so it does not interfere with board-specific
/// widget finder expectations for CuteDogCharacter.
class _DogPreviewAvatar extends StatelessWidget {
  final DogBreed breed;
  final bool isPlaced;
  final double size;

  const _DogPreviewAvatar({
    required this.breed,
    required this.isPlaced,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      width: size + 4,
      height: size + 4,
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPlaced ? AppColors.surfaceElevated : Colors.transparent,
        border: Border.all(
          color: isPlaced ? AppColors.gold : AppColors.cardBorder.withValues(alpha: 0.4),
          width: isPlaced ? 1.5 : 0.8,
        ),
        boxShadow: isPlaced
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  blurRadius: 3,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: Center(
        child: DogAvatar(
          breed: breed,
          size: size,
          isSilhouette: !isPlaced,
        ),
      ),
    );
  }
}

