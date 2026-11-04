import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
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
        child: SizedBox(
          width: size,
          height: size,
          child: Opacity(
            opacity: isPlaced ? 1.0 : 0.35,
            child: CustomPaint(
              size: Size(size, size),
              painter: _PreviewAvatarPainter(
                breed: breed,
                isSilhouette: !isPlaced,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewAvatarPainter extends CustomPainter {
  final DogBreed breed;
  final bool isSilhouette;

  const _PreviewAvatarPainter({
    required this.breed,
    required this.isSilhouette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final primaryColor = isSilhouette ? const Color(0xFF7A6456) : breed.primaryColor;
    final earColor = isSilhouette ? const Color(0xFF7A6456) : breed.accentColor;

    // Ears
    canvas.drawCircle(Offset(w * 0.22, h * 0.26), w * 0.16, Paint()..color = earColor);
    canvas.drawCircle(Offset(w * 0.78, h * 0.26), w * 0.16, Paint()..color = earColor);

    // Head
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.54),
      width: w * 0.72,
      height: h * 0.64,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.32)),
      Paint()..color = primaryColor,
    );

    if (!isSilhouette) {
      // White muzzle
      final muzzleRect = Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.64),
        width: w * 0.46,
        height: h * 0.30,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(muzzleRect, Radius.circular(w * 0.14)),
        Paint()..color = const Color(0xFFFFF7ED),
      );

      // Eyes & Nose
      const darkColor = Color(0xFF382319);
      final eyeRadius = w * 0.055;
      canvas.drawCircle(Offset(w * 0.36, h * 0.48), eyeRadius, Paint()..color = darkColor);
      canvas.drawCircle(Offset(w * 0.64, h * 0.48), eyeRadius, Paint()..color = darkColor);
      canvas.drawCircle(Offset(w * 0.50, h * 0.62), w * 0.045, Paint()..color = darkColor);
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewAvatarPainter oldDelegate) =>
      oldDelegate.breed != breed || oldDelegate.isSilhouette != isSilhouette;
}
