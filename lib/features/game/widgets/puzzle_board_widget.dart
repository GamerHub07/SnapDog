import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/clay_cross_marker.dart';
import '../../../shared/widgets/cute_dog_character.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../../shared/widgets/sparkle_effect.dart';
import '../models/puzzle.dart';
import '../providers/game_provider.dart';

/// Highly optimized 10x10 puzzle board widget.
///
/// Features:
/// - Rebuilds only affected cells on state updates (via per-cell visual state selection).
/// - Pre-caches dog image assets in GPU texture cache.
/// - Does not rebuild on timer ticks.
class PuzzleBoardWidget extends ConsumerStatefulWidget {
  const PuzzleBoardWidget({super.key});

  @override
  ConsumerState<PuzzleBoardWidget> createState() => _PuzzleBoardWidgetState();
}

class _PuzzleBoardWidgetState extends ConsumerState<PuzzleBoardWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache dog image assets in GPU texture cache to avoid decoding lag
    precacheImage(const AssetImage(AppAssets.corgiNeutral), context);
    precacheImage(const AssetImage(AppAssets.corgiSad), context);
    precacheImage(const AssetImage(AppAssets.corgiThinking), context);
  }

  @override
  Widget build(BuildContext context) {
    // Watch only the puzzle instance so the board container does not rebuild on timer or cell changes
    final puzzle = ref.watch(puzzleGameProvider.select((s) => s.puzzle));

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

                  // Determine thick borders between different color regions (static per puzzle)
                  final isTopDiff = row > 0 && puzzle.getRegionAt(row - 1, col) != regionId;
                  final isBottomDiff = row < 9 && puzzle.getRegionAt(row + 1, col) != regionId;
                  final isLeftDiff = col > 0 && puzzle.getRegionAt(row, col - 1) != regionId;
                  final isRightDiff = col < 9 && puzzle.getRegionAt(row, col + 1) != regionId;

                  return _PuzzleCellWidget(
                    key: ValueKey('cell_${row}_$col'),
                    row: row,
                    col: col,
                    regionId: regionId,
                    puzzle: puzzle,
                    isTopDiff: isTopDiff,
                    isBottomDiff: isBottomDiff,
                    isLeftDiff: isLeftDiff,
                    isRightDiff: isRightDiff,
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

/// Immutable snapshot of the visual properties of a single cell.
///
/// Riverpod uses operator == to avoid rebuilding the cell if none of its
/// visual properties have changed.
@immutable
class _CellVisualState {
  final bool hasDog;
  final bool hasCross;
  final bool isSelected;
  final bool isHighlighted;
  final bool isHint;
  final bool isConflicting;
  final bool isWrongPlacement;

  const _CellVisualState({
    required this.hasDog,
    required this.hasCross,
    required this.isSelected,
    required this.isHighlighted,
    required this.isHint,
    required this.isConflicting,
    required this.isWrongPlacement,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CellVisualState &&
          other.hasDog == hasDog &&
          other.hasCross == hasCross &&
          other.isSelected == isSelected &&
          other.isHighlighted == isHighlighted &&
          other.isHint == isHint &&
          other.isConflicting == isConflicting &&
          other.isWrongPlacement == isWrongPlacement;

  @override
  int get hashCode => Object.hash(
        hasDog,
        hasCross,
        isSelected,
        isHighlighted,
        isHint,
        isConflicting,
        isWrongPlacement,
      );
}

/// Individual board cell widget that rebuilds only when its own visual state changes.
class _PuzzleCellWidget extends ConsumerWidget {
  final int row;
  final int col;
  final int regionId;
  final Puzzle puzzle;
  final bool isTopDiff;
  final bool isBottomDiff;
  final bool isLeftDiff;
  final bool isRightDiff;

  const _PuzzleCellWidget({
    super.key,
    required this.row,
    required this.col,
    required this.regionId,
    required this.puzzle,
    required this.isTopDiff,
    required this.isBottomDiff,
    required this.isLeftDiff,
    required this.isRightDiff,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Select ONLY this cell's specific visual state to prevent unnecessary rebuilds
    final cellState = ref.watch(
      puzzleGameProvider.select((state) {
        final selected = state.selectedCell;
        final isSelected = selected != null && selected.x == row && selected.y == col;
        final selectedRegion = selected != null ? puzzle.getRegionAt(selected.x, selected.y) : null;
        final isSameRow = selected != null && selected.x == row;
        final isSameCol = selected != null && selected.y == col;
        final isSameRegion = selectedRegion != null && regionId == selectedRegion;
        final isHighlighted = !isSelected && (isSameRow || isSameCol || isSameRegion);

        return _CellVisualState(
          hasDog: state.hasDogAt(row, col),
          hasCross: state.hasCrossAt(row, col),
          isSelected: isSelected,
          isHighlighted: isHighlighted,
          isHint: state.isHintCellAt(row, col),
          isConflicting: state.isConflictingAt(row, col),
          isWrongPlacement: state.isWrongPlacementAt(row, col),
        );
      }),
    );

    final semanticLabel = 'Row ${row + 1}, Column ${col + 1}'
        '${cellState.hasDog ? ", Puppy placed (locked)" : cellState.hasCross ? ", Marked empty" : ""}'
        '${cellState.isHint ? ", Hint suggested" : ""}'
        '${cellState.isWrongPlacement ? ", Wrong spot" : ""}'
        '${cellState.isConflicting ? ", Conflict" : ""}';

    return _CellGestureDetector(
      semanticLabel: semanticLabel,
      onTap: () {
        ref.read(puzzleGameProvider.notifier).singleTapCell(row, col);
      },
      onDoubleTap: () {
        ref.read(puzzleGameProvider.notifier).doubleTapCell(row, col);
      },
      builder: (context, isPressed) {
        return _CellView(
          row: row,
          col: col,
          regionId: regionId,
          cellState: cellState,
          isPressed: isPressed,
          isTopDiff: isTopDiff,
          isBottomDiff: isBottomDiff,
          isLeftDiff: isLeftDiff,
          isRightDiff: isRightDiff,
        );
      },
    );
  }
}

/// Gesture detector with immediate pressed-state feedback and 220ms double-tap window.
class _CellGestureDetector extends StatefulWidget {
  final Widget Function(BuildContext context, bool isPressed) builder;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final String semanticLabel;

  const _CellGestureDetector({
    required this.builder,
    required this.onTap,
    required this.onDoubleTap,
    required this.semanticLabel,
  });

  @override
  State<_CellGestureDetector> createState() => _CellGestureDetectorState();
}

class _CellGestureDetectorState extends State<_CellGestureDetector> {
  bool _isPressed = false;
  Timer? _singleTapTimer;
  bool _justDoubleTapped = false;

  // Optimized double-tap recognition interval (220ms target within 200–250ms range)
  static const Duration _doubleTapTimeout = Duration(milliseconds: 220);

  @override
  void dispose() {
    _singleTapTimer?.cancel();
    _singleTapTimer = null;
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!mounted) return;
    setState(() {
      _isPressed = true;
    });

    // If a first tap is already pending within the double-tap recognition window,
    // this incoming tap is the second tap of a double-tap!
    if (_singleTapTimer != null) {
      _singleTapTimer?.cancel();
      _singleTapTimer = null;
      _justDoubleTapped = true;
      widget.onDoubleTap();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!mounted) return;
    setState(() {
      _isPressed = false;
    });

    // If this was the second tap of a double tap, reset flag and do not schedule a single tap
    if (_justDoubleTapped) {
      _justDoubleTapped = false;
      return;
    }

    // Schedule single tap callback after the double-tap interval expires
    _singleTapTimer ??= Timer(_doubleTapTimeout, () {
      if (!mounted) return;
      _singleTapTimer = null;
      widget.onTap();
    });
  }

  void _handleTapCancel() {
    if (!mounted) return;
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedScale(
          scale: _isPressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 60),
          curve: Curves.easeOutQuad,
          child: widget.builder(context, _isPressed),
        ),
      ),
    );
  }
}

/// Visual representation of the cell with borders, background tint, and content.
class _CellView extends StatelessWidget {
  final int row;
  final int col;
  final int regionId;
  final _CellVisualState cellState;
  final bool isPressed;
  final bool isTopDiff;
  final bool isBottomDiff;
  final bool isLeftDiff;
  final bool isRightDiff;

  const _CellView({
    required this.row,
    required this.col,
    required this.regionId,
    required this.cellState,
    required this.isPressed,
    required this.isTopDiff,
    required this.isBottomDiff,
    required this.isLeftDiff,
    required this.isRightDiff,
  });

  @override
  Widget build(BuildContext context) {
    final regionColor = AppColors.regionColors[regionId % AppColors.regionColors.length];

    // Subtle, friendly cell background tints
    Color cellBg = regionColor;
    if (cellState.isWrongPlacement) {
      cellBg = Color.lerp(regionColor, const Color(0xFFFFB4A2), 0.75)!;
    } else if (cellState.isConflicting && cellState.hasDog) {
      cellBg = Color.lerp(regionColor, const Color(0xFFFFB4A2), 0.65)!;
    } else if (cellState.isHint && !cellState.hasDog) {
      cellBg = Color.lerp(regionColor, const Color(0xFFFFF4D0), 0.70)!;
    } else if (cellState.isSelected) {
      cellBg = Color.lerp(regionColor, Colors.white, 0.45)!;
    } else if (cellState.isHighlighted) {
      cellBg = Color.lerp(regionColor, Colors.white, 0.28)!;
    }

    // Immediate tactile feedback on touch down
    if (isPressed) {
      cellBg = Color.lerp(cellBg, Colors.black, 0.08)!;
    }

    // Border styling: Thick for region boundaries, clean thin for internal cells
    const thickBorder = BorderSide(color: AppColors.regionBorderThick, width: 2.2);
    const thinBorder = BorderSide(color: AppColors.gridLineThin, width: 0.6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
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
          if (cellState.isSelected)
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
          if (cellState.isHint && !cellState.hasDog)
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
          if (cellState.isConflicting && cellState.hasDog)
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
          if (cellState.isWrongPlacement)
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
          _buildCellContent(),
        ],
      ),
    );
  }

  Widget _buildCellContent() {
    Widget content;

    if (cellState.hasDog) {
      content = SparkleOverlay(
        key: const ValueKey('cell_dog'),
        trigger: !cellState.isConflicting,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.35, end: 1.0),
          duration: const Duration(milliseconds: 180),
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
                hasClash: cellState.isConflicting,
              ),
            ),
          ),
        ),
      );
    } else if (cellState.hasCross) {
      // Short, snappy pop animation for confirmed single-tap cross (110ms)
      content = TweenAnimationBuilder<double>(
        key: const ValueKey('cell_cross'),
        tween: Tween<double>(begin: 0.35, end: 1.0),
        duration: const Duration(milliseconds: 110),
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
    } else if (cellState.isHint) {
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
      duration: const Duration(milliseconds: 100),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: content,
    );

    // Shake animation on wrong placement
    if (cellState.isWrongPlacement || (cellState.isConflicting && cellState.hasDog)) {
      return TweenAnimationBuilder<double>(
        key: ValueKey('shake_${row}_$col'),
        tween: Tween<double>(begin: 1.0, end: 0.0),
        duration: const Duration(milliseconds: 300),
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
