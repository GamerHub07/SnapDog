import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/clay_cross_marker.dart';
import '../../../shared/widgets/cute_dog_character.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../../shared/widgets/sparkle_effect.dart';
import '../providers/game_provider.dart';

class PuzzleBoardWidget extends ConsumerWidget {
  const PuzzleBoardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(puzzleGameProvider);
    final puzzle = gameState.puzzle;
    final selected = gameState.selectedCell;
    final selectedRegion = selected != null ? puzzle.getRegionAt(selected.x, selected.y) : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardSize = min(constraints.maxWidth, constraints.maxHeight);

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.regionBorderThick, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowWarm,
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: 100,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                ),
                itemBuilder: (context, index) {
                  final row = index ~/ 10;
                  final col = index % 10;
                  final regionId = puzzle.getRegionAt(row, col);

                  final isSelected = selected != null && selected.x == row && selected.y == col;
                  final isSameRow = selected != null && selected.x == row;
                  final isSameCol = selected != null && selected.y == col;
                  final isSameRegion = selectedRegion != null && regionId == selectedRegion;

                  final isHighlighted = !isSelected && (isSameRow || isSameCol || isSameRegion);
                  final hasDog = gameState.hasDogAt(row, col);
                  final isConflicting = gameState.isConflictingAt(row, col);
                  final isHint = gameState.isHintCellAt(row, col);
                  final hasCross = gameState.hasCrossAt(row, col);
                  final isWrongPlacement = gameState.isWrongPlacementAt(row, col);

                  // Determine thick borders between different color regions
                  final isTopDiff = row > 0 && puzzle.getRegionAt(row - 1, col) != regionId;
                  final isBottomDiff = row < 9 && puzzle.getRegionAt(row + 1, col) != regionId;
                  final isLeftDiff = col > 0 && puzzle.getRegionAt(row, col - 1) != regionId;
                  final isRightDiff = col < 9 && puzzle.getRegionAt(row, col + 1) != regionId;

                  return _PuzzleCellWidget(
                    key: ValueKey('cell_${row}_$col'),
                    row: row,
                    col: col,
                    regionId: regionId,
                    hasDog: hasDog,
                    isConflicting: isConflicting,
                    isHint: isHint,
                    hasCross: hasCross,
                    isWrongPlacement: isWrongPlacement,
                    isSelected: isSelected,
                    isHighlighted: isHighlighted,
                    isTopDiff: isTopDiff,
                    isBottomDiff: isBottomDiff,
                    isLeftDiff: isLeftDiff,
                    isRightDiff: isRightDiff,
                    onTap: () {
                      ref.read(puzzleGameProvider.notifier).singleTapCell(row, col);
                    },
                    onDoubleTap: () {
                      ref.read(puzzleGameProvider.notifier).doubleTapCell(row, col);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PuzzleCellWidget extends StatelessWidget {
  final int row;
  final int col;
  final int regionId;
  final bool hasDog;
  final bool isConflicting;
  final bool isHint;
  final bool hasCross;
  final bool isWrongPlacement;
  final bool isSelected;
  final bool isHighlighted;
  final bool isTopDiff;
  final bool isBottomDiff;
  final bool isLeftDiff;
  final bool isRightDiff;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const _PuzzleCellWidget({
    super.key,
    required this.row,
    required this.col,
    required this.regionId,
    required this.hasDog,
    required this.isConflicting,
    required this.isHint,
    required this.hasCross,
    required this.isWrongPlacement,
    required this.isSelected,
    required this.isHighlighted,
    required this.isTopDiff,
    required this.isBottomDiff,
    required this.isLeftDiff,
    required this.isRightDiff,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final regionColor = AppColors.regionColors[regionId % AppColors.regionColors.length];

    // Subtle, friendly cell background tints
    Color cellBg = regionColor;
    if (isWrongPlacement) {
      cellBg = Color.lerp(regionColor, const Color(0xFFFFB4A2), 0.75)!;
    } else if (isConflicting && hasDog) {
      cellBg = Color.lerp(regionColor, const Color(0xFFFFB4A2), 0.65)!;
    } else if (isHint && !hasDog) {
      cellBg = Color.lerp(regionColor, const Color(0xFFFFF4D0), 0.70)!;
    } else if (isSelected) {
      cellBg = Color.lerp(regionColor, Colors.white, 0.45)!;
    } else if (isHighlighted) {
      cellBg = Color.lerp(regionColor, Colors.white, 0.28)!;
    }

    // Border styling: Thick for region boundaries, clean thin for internal cells
    const thickBorder = BorderSide(color: AppColors.regionBorderThick, width: 2.2);
    const thinBorder = BorderSide(color: AppColors.gridLineThin, width: 0.6);

    final semanticLabel = 'Row ${row + 1}, Column ${col + 1}'
        '${hasDog ? ", Puppy placed (locked)" : hasCross ? ", Marked empty" : ""}'
        '${isHint ? ", Hint suggested" : ""}'
        '${isWrongPlacement ? ", Wrong spot" : ""}'
        '${isConflicting ? ", Conflict" : ""}';

    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: cellBg,
            border: Border(
              top: isTopDiff ? thickBorder : thinBorder,
              bottom: isBottomDiff ? thickBorder : thinBorder,
              left: isLeftDiff ? thickBorder : thinBorder,
              right: isRightDiff ? thickBorder : thinBorder,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Selected cell prominent indicator ring
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryDark, width: 2.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

              // Hint highlight indicator
              if (isHint && !hasDog)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gold, width: 2.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

              // Conflicting dog indicator ring
              if (isConflicting && hasDog)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.clashRed, width: 2.0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

              // Wrong placement feedback ring & icon
              if (isWrongPlacement)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.clashRed, width: 2.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: AppColors.clashRed,
                      ),
                    ),
                  ),
                ),

              // Cell content with animated bounce, sparkle, shake, and shrink-out
              _buildAnimatedCellContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCellContent() {
    Widget content;

    if (hasDog) {
      content = SparkleOverlay(
        key: const ValueKey('cell_dog'),
        trigger: !isConflicting,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.25, end: 1.0),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(0.5),
            child: FittedBox(
              fit: BoxFit.contain,
              child: CuteDogCharacter(
                size: 38,
                hasClash: isConflicting,
              ),
            ),
          ),
        ),
      );
    } else if (hasCross) {
      content = TweenAnimationBuilder<double>(
        key: const ValueKey('cell_cross'),
        tween: Tween<double>(begin: 0.25, end: 1.0),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: const ClayCrossMarker(
          size: 22,
        ),
      );
    } else if (isHint) {
      content = const PawIcon(
        key: ValueKey('cell_hint'),
        size: 18,
        color: AppColors.gold,
      );
    } else {
      content = const SizedBox.shrink(key: ValueKey('cell_empty'));
    }

    // Shrink-out animation on undo or removal via AnimatedSwitcher
    final animatedContent = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: content,
    );

    // Shake animation on wrong placement
    if (isWrongPlacement || (isConflicting && hasDog)) {
      return TweenAnimationBuilder<double>(
        key: ValueKey('shake_${row}_$col'),
        tween: Tween<double>(begin: 1.0, end: 0.0),
        duration: const Duration(milliseconds: 320),
        builder: (context, val, child) {
          final offset = sin(val * pi * 4) * 3.5;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: animatedContent,
      );
    }

    return animatedContent;
  }
}
