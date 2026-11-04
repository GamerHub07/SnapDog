import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/clay_cross_marker.dart';
import '../../../shared/widgets/cute_dog_character.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../../shared/widgets/sparkle_effect.dart';
import '../models/dog_breed.dart';
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
  final ValueNotifier<Point<int>?> _pressedCellNotifier = ValueNotifier<Point<int>?>(null);

  // Multi-cell drag & unified gesture coordination state
  int? _activePointerId;
  Offset? _downPosition;
  Point<int>? _downCell;
  Point<int>? _lastVisitedCell;
  bool _isDragGesture = false;

  // Double-tap & single-tap recognition
  Point<int>? _justDoubleTappedCell;
  final Map<Point<int>, Timer> _pendingTapTimers = {};

  static const double _touchSlop = 12.0;
  static const Duration _doubleTapTimeout = Duration(milliseconds: 220);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache dog image assets in GPU texture cache to avoid decoding lag
    precacheImage(const AssetImage(AppAssets.corgiNeutral), context);
    precacheImage(const AssetImage(AppAssets.corgiSad), context);
    precacheImage(const AssetImage(AppAssets.corgiThinking), context);
  }

  @override
  void dispose() {
    _cancelAllTapTimers();
    _pressedCellNotifier.dispose();
    super.dispose();
  }

  void _cancelAllTapTimers() {
    for (final timer in _pendingTapTimers.values) {
      timer.cancel();
    }
    _pendingTapTimers.clear();
  }

  void _handlePointerDown(PointerDownEvent event, double innerSize) {
    if (_activePointerId != null) return;
    _activePointerId = event.pointer;
    _downPosition = event.localPosition;
    _isDragGesture = false;

    final double cellSize = innerSize / 10.0;
    final int col = (event.localPosition.dx / cellSize).floor().clamp(0, 9);
    final int row = (event.localPosition.dy / cellSize).floor().clamp(0, 9);
    final cell = Point(row, col);

    _downCell = cell;
    _lastVisitedCell = cell;
    _pressedCellNotifier.value = cell;

    // If a first tap is already pending within the double-tap recognition window for this cell,
    // this incoming tap is the second tap of a double-tap!
    if (_pendingTapTimers.containsKey(cell)) {
      _pendingTapTimers[cell]?.cancel();
      _pendingTapTimers.remove(cell);
      _justDoubleTappedCell = cell;
      ref.read(puzzleGameProvider.notifier).doubleTapCell(cell.x, cell.y);
    }
  }

  void _handlePointerMove(PointerMoveEvent event, double innerSize) {
    if (event.pointer != _activePointerId || _downPosition == null || _downCell == null) {
      return;
    }

    final double cellSize = innerSize / 10.0;
    final int col = (event.localPosition.dx / cellSize).floor().clamp(0, 9);
    final int row = (event.localPosition.dy / cellSize).floor().clamp(0, 9);
    final currentCell = Point(row, col);

    final double distance = (event.localPosition - _downPosition!).distance;

    // Distinguish tapping from dragging using touch slop threshold (~12px)
    if (!_isDragGesture && distance > _touchSlop) {
      _isDragGesture = true;

      // Cancel pending tap timers because this is a drag, not a tap or double tap
      _cancelAllTapTimers();
      _justDoubleTappedCell = null;

      // Start drag at initial cell
      ref.read(puzzleGameProvider.notifier).startDragCross(_downCell!.x, _downCell!.y);
      _lastVisitedCell = _downCell;
    }

    if (_isDragGesture) {
      _pressedCellNotifier.value = currentCell;

      if (_lastVisitedCell != null && currentCell != _lastVisitedCell) {
        // Fast dragging interpolation using Bresenham's line algorithm
        // so NO cells are skipped even with rapid swipe gestures
        final lineCells = _getLineCells(_lastVisitedCell!, currentCell);
        final notifier = ref.read(puzzleGameProvider.notifier);
        for (final pt in lineCells) {
          notifier.updateDragCross(pt.x, pt.y);
        }
        _lastVisitedCell = currentCell;
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event, double innerSize) {
    if (event.pointer != _activePointerId) return;
    _activePointerId = null;
    _pressedCellNotifier.value = null;

    if (_isDragGesture) {
      ref.read(puzzleGameProvider.notifier).endDragCross();
      _isDragGesture = false;
      _downPosition = null;
      _downCell = null;
      _lastVisitedCell = null;
      _justDoubleTappedCell = null;
      return;
    }

    // It was a tap (not a drag)
    final tappedCell = _downCell;
    _downPosition = null;
    _downCell = null;
    _lastVisitedCell = null;

    if (tappedCell == null) return;

    // If this tap was already handled as a double tap on pointer down, reset flag and do not schedule single tap
    if (_justDoubleTappedCell == tappedCell) {
      _justDoubleTappedCell = null;
      return;
    }

    // Schedule single tap callback after the double-tap interval expires
    _pendingTapTimers[tappedCell]?.cancel();
    _pendingTapTimers[tappedCell] = Timer(_doubleTapTimeout, () {
      _pendingTapTimers.remove(tappedCell);
      if (mounted) {
        ref.read(puzzleGameProvider.notifier).singleTapCell(tappedCell.x, tappedCell.y);
      }
    });
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointerId) return;
    _activePointerId = null;
    _pressedCellNotifier.value = null;

    if (_isDragGesture) {
      ref.read(puzzleGameProvider.notifier).cancelDragCross();
      _isDragGesture = false;
    }

    _cancelAllTapTimers();
    _justDoubleTappedCell = null;
    _downPosition = null;
    _downCell = null;
    _lastVisitedCell = null;
  }

  List<Point<int>> _getLineCells(Point<int> from, Point<int> to) {
    final List<Point<int>> cells = [];
    int x0 = from.y; // col
    int y0 = from.x; // row
    final int x1 = to.y;
    final int y1 = to.x;

    final int dx = (x1 - x0).abs();
    final int dy = -(y1 - y0).abs();
    final int sx = x0 < x1 ? 1 : -1;
    final int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;

    while (true) {
      cells.add(Point(y0, x0));
      if (x0 == x1 && y0 == y1) break;
      final int e2 = 2 * err;
      if (e2 >= dy) {
        err += dy;
        x0 += sx;
      }
      if (e2 <= dx) {
        err += dx;
        y0 += sy;
      }
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    // Watch only the puzzle instance so the board container does not rebuild on timer or cell changes
    final puzzle = ref.watch(puzzleGameProvider.select((s) => s.puzzle));

    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardSize = min(constraints.maxWidth, constraints.maxHeight);
        final double innerSize = boardSize - 13.0; // padding 4 * 2 + border 2.5 * 2

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.regionBorderThick, width: 2.4),
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
              child: _PressedCellScope(
                pressedCellNotifier: _pressedCellNotifier,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => _handlePointerDown(event, innerSize),
                  onPointerMove: (event) => _handlePointerMove(event, innerSize),
                  onPointerUp: (event) => _handlePointerUp(event, innerSize),
                  onPointerCancel: _handlePointerCancel,
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
            ),
          ),
        );
      },
    );
  }
}

/// InheritedWidget that provides the active pressed cell notifier to child cell widgets.
class _PressedCellScope extends InheritedWidget {
  final ValueNotifier<Point<int>?> pressedCellNotifier;

  const _PressedCellScope({
    required this.pressedCellNotifier,
    required super.child,
  });

  static ValueNotifier<Point<int>?> of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_PressedCellScope>()!.pressedCellNotifier;
  }

  @override
  bool updateShouldNotify(_PressedCellScope oldWidget) =>
      pressedCellNotifier != oldWidget.pressedCellNotifier;
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
        final isSameRow = selected != null && selected.x == row;
        final isSameCol = selected != null && selected.y == col;
        final isHighlighted = !isSelected && (isSameRow || isSameCol);

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

    final breed = DogBreedAssignment.forPuzzle(puzzle).getBreedAt(row, col);

    final pressedCellNotifier = _PressedCellScope.of(context);
    return ValueListenableBuilder<Point<int>?>(
      valueListenable: pressedCellNotifier,
      builder: (context, pressedCell, child) {
        final isPressed = pressedCell != null && pressedCell.x == row && pressedCell.y == col;

        return Semantics(
          label: semanticLabel,
          button: true,
          onTap: () {
            ref.read(puzzleGameProvider.notifier).singleTapCell(row, col);
          },
          child: AnimatedScale(
            scale: isPressed ? 0.93 : 1.0,
            duration: const Duration(milliseconds: 60),
            curve: Curves.easeOutQuad,
            child: _CellView(
              row: row,
              col: col,
              regionId: regionId,
              breed: breed,
              cellState: cellState,
              isPressed: isPressed,
              isTopDiff: isTopDiff,
              isBottomDiff: isBottomDiff,
              isLeftDiff: isLeftDiff,
              isRightDiff: isRightDiff,
            ),
          ),
        );
      },
    );
  }
}

/// Visual representation of the cell with borders, background tint, and content.
class _CellView extends StatelessWidget {
  final int row;
  final int col;
  final int regionId;
  final DogBreed breed;
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
    required this.breed,
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
      // Subtle background tint for selected cell
      cellBg = Color.lerp(regionColor, Colors.white, 0.40)!;
    } else if (cellState.isHighlighted) {
      // Subtle background tint for row & column highlight
      cellBg = Color.lerp(regionColor, Colors.white, 0.18)!;
    }

    // Immediate tactile feedback on touch down
    if (isPressed) {
      cellBg = Color.lerp(cellBg, Colors.black, 0.08)!;
    }

    // Border styling: Medium-strength muted brown for region boundaries, clean thin for internal cells
    const boundaryBorder = BorderSide(color: AppColors.regionBorderThick, width: 2.2);
    const thinBorder = BorderSide(color: AppColors.gridLineThin, width: 0.8);

    // Consistent single-edge border rendering avoids thick double borders where regions meet
    final cellBorder = Border(
      bottom: row < 9 ? (isBottomDiff ? boundaryBorder : thinBorder) : BorderSide.none,
      right: col < 9 ? (isRightDiff ? boundaryBorder : thinBorder) : BorderSide.none,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: cellBg,
        border: cellBorder,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle translucent overlay for highlighted row and column
          if (cellState.isHighlighted)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),

          // Gentle selection highlight for selected cell (gentle luminous overlay & soft highlight border, NO RED)
          if (cellState.isSelected)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xCCFFFFFF), // Soft luminous highlight
                    width: 1.5,
                  ),
                ),
              ),
            ),

          // Hint pulsing highlight indicator
          if (cellState.isHint && !cellState.hasDog)
            const Positioned.fill(
              child: _PulsingHintHighlight(),
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glowing aura ring around placed dogs (Reference Image 3)
                  if (!cellState.isConflicting)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD166),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD166).withValues(alpha: 0.65),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  CuteDogCharacter(
                    size: 38,
                    breed: breed,
                    hasClash: cellState.isConflicting,
                  ),
                ],
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

/// Lightweight pulsing highlight border for the suggested hint cell.
class _PulsingHintHighlight extends StatefulWidget {
  const _PulsingHintHighlight();

  @override
  State<_PulsingHintHighlight> createState() => _PulsingHintHighlightState();
}

class _PulsingHintHighlightState extends State<_PulsingHintHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
    _glowAnimation = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final val = _glowAnimation.value;
        return Container(
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.gold.withValues(alpha: val),
              width: 2.4,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.35 * val),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
