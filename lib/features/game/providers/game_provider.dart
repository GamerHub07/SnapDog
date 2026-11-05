import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapdog/core/utils/sound_haptic_helper.dart';
import 'package:snapdog/features/game/models/dog_placement.dart';
import 'package:snapdog/features/game/models/progressive_hint.dart';
import 'package:snapdog/features/game/models/puzzle.dart';
import 'package:snapdog/features/game/services/hint_service.dart';
import 'package:snapdog/features/game/services/puzzle_repository.dart';
import 'package:snapdog/features/game/services/puzzle_validator.dart';
import 'package:snapdog/features/progression/models/progression_state.dart';
import 'package:snapdog/features/progression/providers/progression_provider.dart';
import 'package:snapdog/features/settings/models/settings_state.dart';
import 'package:snapdog/features/statistics/models/game_stats.dart';

enum DragAction {
  addCross,
  removeCross,
}

class GameActionSnapshot {
  final List<DogPlacement> placements;
  final Set<Point<int>> crosses;

  const GameActionSnapshot({
    required this.placements,
    required this.crosses,
  });
}

class PuzzleGameState {
  final Puzzle puzzle;
  final int puzzleIndex;
  final List<DogPlacement> placements;
  final Set<DogPlacement> clashingPlacements;
  final Set<DogPlacement> conflictingPlacements; // Briefly highlighted conflicting dogs
  final Set<Point<int>> crosses;
  final Point<int>? selectedCell;
  final Point<int>? hintCell;
  final ProgressiveHint? activeHint;
  final HintStage? hintStage;
  final Set<Point<int>> highlightedCells;
  final int? highlightedRow;
  final int? highlightedCol;
  final int? highlightedRegion;
  final Point<int>? wrongPlacementCell; // Briefly highlighted wrong placement cell
  final String? contextualMessage;
  final int timerSeconds;
  final bool isPaused;
  final bool isCompleted;
  final bool isGameOver;
  final int hintsUsed;
  final int mistakes;
  final List<GameActionSnapshot> undoStack;

  const PuzzleGameState({
    required this.puzzle,
    required this.puzzleIndex,
    this.placements = const [],
    this.clashingPlacements = const {},
    this.conflictingPlacements = const {},
    this.crosses = const {},
    this.selectedCell,
    this.hintCell,
    this.activeHint,
    this.hintStage,
    this.highlightedCells = const {},
    this.highlightedRow,
    this.highlightedCol,
    this.highlightedRegion,
    this.wrongPlacementCell,
    this.contextualMessage,
    this.timerSeconds = 0,
    this.isPaused = false,
    this.isCompleted = false,
    this.isGameOver = false,
    this.hintsUsed = 0,
    this.mistakes = 0,
    this.undoStack = const [],
  });

  int get dogCount => placements.length;
  bool get hasClashes => clashingPlacements.isNotEmpty;
  Set<Point<int>> get markedEmptyCells => crosses;

  bool hasDogAt(int row, int col) {
    return placements.any((p) => p.row == row && p.col == col);
  }

  bool isDogLockedAt(int row, int col) {
    return hasDogAt(row, col) && puzzle.solution.any((p) => p.row == row && p.col == col);
  }

  bool hasCrossAt(int row, int col) {
    return crosses.contains(Point(row, col));
  }

  bool isClashingAt(int row, int col) {
    return clashingPlacements.any((p) => p.row == row && p.col == col);
  }

  bool isConflictingAt(int row, int col) {
    return conflictingPlacements.any((p) => p.row == row && p.col == col);
  }

  bool isHintCellAt(int row, int col) {
    if (activeHint != null && activeHint!.stage != HintStage.placement) {
      return false;
    }
    return hintCell != null && hintCell!.x == row && hintCell!.y == col;
  }

  bool isHintEliminatedAt(int row, int col) {
    return activeHint != null &&
        activeHint!.stage == HintStage.elimination &&
        activeHint!.eliminatedCandidates.any((p) => p.x == row && p.y == col);
  }

  bool isHintHighlightedAt(int row, int col) {
    if (highlightedCells.contains(Point(row, col))) return true;
    if (highlightedRow != null && highlightedRow == row) return true;
    if (highlightedCol != null && highlightedCol == col) return true;
    if (highlightedRegion != null && puzzle.getRegionAt(row, col) == highlightedRegion) return true;
    return false;
  }

  bool isWrongPlacementAt(int row, int col) {
    return wrongPlacementCell != null && wrongPlacementCell!.x == row && wrongPlacementCell!.y == col;
  }

  bool isMarkedEmptyAt(int row, int col) => hasCrossAt(row, col);

  PuzzleGameState copyWith({
    Puzzle? puzzle,
    int? puzzleIndex,
    List<DogPlacement>? placements,
    Set<DogPlacement>? conflictingPlacements,
    Set<Point<int>>? crosses,
    Set<Point<int>>? markedEmptyCells,
    Point<int>? selectedCell,
    bool clearSelectedCell = false,
    Point<int>? hintCell,
    bool clearHintCell = false,
    ProgressiveHint? activeHint,
    bool clearActiveHint = false,
    HintStage? hintStage,
    bool clearHintStage = false,
    Set<Point<int>>? highlightedCells,
    bool clearHighlightedCells = false,
    int? highlightedRow,
    bool clearHighlightedRow = false,
    int? highlightedCol,
    bool clearHighlightedCol = false,
    int? highlightedRegion,
    bool clearHighlightedRegion = false,
    Point<int>? wrongPlacementCell,
    bool clearWrongPlacementCell = false,
    String? contextualMessage,
    bool clearContextualMessage = false,
    int? timerSeconds,
    bool? isPaused,
    bool? isCompleted,
    bool? isGameOver,
    int? hintsUsed,
    int? mistakes,
    List<GameActionSnapshot>? undoStack,
  }) {
    final nextPlacements = placements ?? this.placements;
    final nextPuzzle = puzzle ?? this.puzzle;
    final nextClashes = (placements != null || puzzle != null)
        ? PuzzleValidator.findClashingPlacements(nextPuzzle, nextPlacements)
        : clashingPlacements;

    return PuzzleGameState(
      puzzle: nextPuzzle,
      puzzleIndex: puzzleIndex ?? this.puzzleIndex,
      placements: nextPlacements,
      clashingPlacements: nextClashes,
      conflictingPlacements: conflictingPlacements ?? this.conflictingPlacements,
      crosses: crosses ?? (markedEmptyCells ?? this.crosses),
      selectedCell: clearSelectedCell ? null : (selectedCell ?? this.selectedCell),
      hintCell: clearHintCell ? null : (hintCell ?? this.hintCell),
      activeHint: clearActiveHint ? null : (activeHint ?? this.activeHint),
      hintStage: clearHintStage ? null : (hintStage ?? this.hintStage),
      highlightedCells: clearHighlightedCells ? const {} : (highlightedCells ?? this.highlightedCells),
      highlightedRow: clearHighlightedRow ? null : (highlightedRow ?? this.highlightedRow),
      highlightedCol: clearHighlightedCol ? null : (highlightedCol ?? this.highlightedCol),
      highlightedRegion: clearHighlightedRegion ? null : (highlightedRegion ?? this.highlightedRegion),
      wrongPlacementCell: clearWrongPlacementCell ? null : (wrongPlacementCell ?? this.wrongPlacementCell),
      contextualMessage: clearContextualMessage ? null : (contextualMessage ?? this.contextualMessage),
      timerSeconds: timerSeconds ?? this.timerSeconds,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      isGameOver: isGameOver ?? this.isGameOver,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      mistakes: mistakes ?? this.mistakes,
      undoStack: undoStack ?? this.undoStack,
    );
  }
}

class PuzzleGameNotifier extends Notifier<PuzzleGameState> {
  Timer? _timer;
  Timer? _messageClearTimer;

  // Track whether a hint was already revealed for the current board state
  bool _hintRevealedForCurrentBoardState = false;

  // Drag-to-cross gesture state
  GameActionSnapshot? _dragPreSnapshot;
  final Set<Point<int>> _dragVisitedCells = {};
  final Set<Point<int>> _dragModifiedCrosses = {};
  DragAction _dragAction = DragAction.addCross;
  bool _isDragging = false;

  @override
  PuzzleGameState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _messageClearTimer?.cancel();
      _dragPreSnapshot = null;
      _dragVisitedCells.clear();
      _dragModifiedCrosses.clear();
      _isDragging = false;
    });

    final progression = ref.read(progressionProvider);
    final resumePuzzle = progression.getResumePuzzle();
    final inProgress = progression.inProgressState;

    _startTimer();

    if (inProgress != null &&
        inProgress.levelNumber == resumePuzzle.levelNumber &&
        !progression.isLevelCompleted(resumePuzzle.levelNumber)) {
      return PuzzleGameState(
        puzzle: resumePuzzle,
        puzzleIndex: resumePuzzle.levelNumber - 1,
        placements: List.from(inProgress.placements),
        crosses: Set.from(inProgress.crosses),
        timerSeconds: inProgress.timerSeconds,
        mistakes: inProgress.mistakes,
        hintsUsed: inProgress.hintsUsed,
      );
    }

    return PuzzleGameState(
      puzzle: resumePuzzle,
      puzzleIndex: resumePuzzle.levelNumber - 1,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isPaused && !state.isCompleted && !state.isGameOver) {
        state = state.copyWith(timerSeconds: state.timerSeconds + 1);
      }
    });
  }

  void _saveCurrentInProgress() {
    if (state.isCompleted || state.isGameOver) return;
    ref.read(progressionProvider.notifier).saveInProgress(
      InProgressPuzzleState(
        puzzleId: state.puzzle.id,
        levelNumber: state.puzzle.levelNumber,
        placements: state.placements,
        crosses: state.crosses,
        timerSeconds: state.timerSeconds,
        mistakes: state.mistakes,
        hintsUsed: state.hintsUsed,
      ),
    );
  }

  /// Loads a specific level by its 1-based level number.
  void loadLevel(int levelNumber) {
    _timer?.cancel();
    _messageClearTimer?.cancel();
    _dragPreSnapshot = null;
    _dragVisitedCells.clear();
    _dragModifiedCrosses.clear();
    _isDragging = false;
    _hintRevealedForCurrentBoardState = false;

    final puzzle = PuzzleRepository.getPuzzleByLevel(levelNumber);
    final progression = ref.read(progressionProvider);
    final inProgress = progression.inProgressState;

    if (inProgress != null &&
        inProgress.levelNumber == levelNumber &&
        !progression.isLevelCompleted(levelNumber)) {
      state = PuzzleGameState(
        puzzle: puzzle,
        puzzleIndex: levelNumber - 1,
        placements: List.from(inProgress.placements),
        crosses: Set.from(inProgress.crosses),
        timerSeconds: inProgress.timerSeconds,
        mistakes: inProgress.mistakes,
        hintsUsed: inProgress.hintsUsed,
      );
    } else {
      state = PuzzleGameState(
        puzzle: puzzle,
        puzzleIndex: levelNumber - 1,
      );
    }

    _startTimer();
    SoundHapticHelper.successVibrate();
    ref.read(progressionProvider.notifier).setCurrentLevel(levelNumber);
  }

  /// Loads a specific puzzle by index (0-based, corresponding to levelNumber = index + 1).
  void loadPuzzle(int index) => loadLevel(index + 1);

  /// Loads a specific puzzle by its unique ID.
  void loadPuzzleById(String id) {
    final puzzle = PuzzleRepository.getPuzzleById(id);
    loadLevel(puzzle.levelNumber);
  }

  /// Advances to the next unlocked level in endless progression.
  void nextPuzzle() {
    loadLevel(state.puzzle.levelNumber + 1);
  }

  /// Selects a cell and highlights its row, column, and color region.
  void selectCell(int r, int c) {
    if (state.isPaused || state.isCompleted || state.isGameOver) return;
    state = state.copyWith(selectedCell: Point(r, c));
    SoundHapticHelper.lightTap();
  }

  /// Single tap – Mark with a cross (×):
  /// - When the player taps an empty cell once, display a simple cross (×) inside it.
  /// - Tapping the same crossed cell again removes the cross and returns to empty.
  /// - Correctly placed dogs are locked and cannot be removed by single tapping.
  /// - A single tap must never place a dog.
  void singleTapCell(int r, int c) {
    if (state.isPaused || state.isCompleted || state.isGameOver) return;

    final hasDog = state.hasDogAt(r, c);
    final hasCross = state.hasCrossAt(r, c);

    if (hasDog) {
      // Locked dog cannot be removed by tapping
      _showMessage('This puppy is locked in the right spot! 🐾', const {});
      SoundHapticHelper.lightTap();
      return;
    }

    final snapshot = GameActionSnapshot(
      placements: List<DogPlacement>.from(state.placements),
      crosses: Set<Point<int>>.from(state.crosses),
    );

    if (hasCross) {
      // Tapping a crossed cell removes the cross and returns it to empty
      final newCrosses = Set<Point<int>>.from(state.crosses)..remove(Point(r, c));

      state = state.copyWith(
        crosses: newCrosses,
        selectedCell: Point(r, c),
        clearContextualMessage: true,
        conflictingPlacements: const {},
        undoStack: [...state.undoStack, snapshot],
        clearActiveHint: true,
        clearHintStage: true,
        clearHighlightedCells: true,
        clearHighlightedRow: true,
        clearHighlightedCol: true,
        clearHighlightedRegion: true,
        clearHintCell: true,
      );

      SoundHapticHelper.crossMark();
      _hintRevealedForCurrentBoardState = false;
      _saveCurrentInProgress();
      return;
    }

    // Cell is empty: mark with a cross (×)
    final newCrosses = Set<Point<int>>.from(state.crosses)..add(Point(r, c));

    state = state.copyWith(
      crosses: newCrosses,
      selectedCell: Point(r, c),
      clearContextualMessage: true,
      conflictingPlacements: const {},
      undoStack: [...state.undoStack, snapshot],
      clearActiveHint: true,
      clearHintStage: true,
      clearHighlightedCells: true,
      clearHighlightedRow: true,
      clearHighlightedCol: true,
      clearHighlightedRegion: true,
      clearHintCell: true,
    );

    SoundHapticHelper.crossMark();
    _hintRevealedForCurrentBoardState = false;
    _saveCurrentInProgress();
  }

  /// Double tap – Place a dog:
  /// - Checks against the verified puzzle solution.
  /// - If the placement is correct, it locks permanently.
  /// - If the placement is incorrect, it shows immediate mistake feedback, increments mistakes,
  ///   removes the dog immediately, and ends the attempt on the 3rd mistake (Game Over).
  void doubleTapCell(int r, int c) {
    if (state.isPaused || state.isCompleted || state.isGameOver) return;

    // If cell already contains a dog, it is locked; double-tapping should not duplicate or remove it
    if (state.hasDogAt(r, c)) {
      state = state.copyWith(selectedCell: Point(r, c));
      return;
    }

    final targetDog = DogPlacement(r, c);

    // Check maximum 10 dogs placed
    if (state.placements.length >= 10) {
      _showMessage('All 10 dogs are already placed!', const {});
      SoundHapticHelper.invalidPlacement();
      state = state.copyWith(selectedCell: Point(r, c));
      return;
    }

    // Check against verified puzzle solution
    final isSolution = state.puzzle.solution.any((p) => p.row == r && p.col == c);

    if (!isSolution) {
      final newMistakes = state.mistakes + 1;
      final isGameOver = newMistakes >= 3;

      if (isGameOver) {
        _timer?.cancel();
      }

      SoundHapticHelper.invalidPlacement();

      // Check if there is also an explicit rule conflict for educational feedback
      final validation = PuzzleValidator.validateNewPlacement(
        state.puzzle,
        state.placements,
        targetDog,
      );

      final String feedbackMsg;
      if (isGameOver) {
        feedbackMsg = 'Game Over! 3 mistakes made.';
      } else if (!validation.isValid && validation.message != null) {
        feedbackMsg = validation.message!;
      } else {
        feedbackMsg = 'Wrong position! That spot is not part of the solution. (Mistake $newMistakes/3)';
      }

      _showMistakeFeedback(
        Point(r, c),
        feedbackMsg,
        newMistakes,
        isGameOver,
        validation.conflictingDogs,
      );
      return;
    }

    // Correct placement: lock dog permanently
    final newPlacements = [...state.placements, targetDog];

    // On a valid double tap, replace the cross (if present) with a dog
    final newCrosses = Set<Point<int>>.from(state.crosses)..remove(Point(r, c));

    final isSolved = PuzzleValidator.isPuzzleCompleted(state.puzzle, newPlacements);

    if (isSolved) {
      _timer?.cancel();
      SoundHapticHelper.puzzleCompleted();
      _saveWinStats(state.timerSeconds);
      ref.read(progressionProvider.notifier).recordCompletion(
        puzzle: state.puzzle,
        placements: newPlacements,
        timeSeconds: state.timerSeconds,
        hintsUsed: state.hintsUsed,
        mistakes: state.mistakes,
      );
    } else {
      SoundHapticHelper.dogPlace();
    }

    state = state.copyWith(
      placements: newPlacements,
      crosses: newCrosses,
      selectedCell: Point(r, c),
      clearHintCell: true,
      clearActiveHint: true,
      clearHintStage: true,
      clearHighlightedCells: true,
      clearHighlightedRow: true,
      clearHighlightedCol: true,
      clearHighlightedRegion: true,
      clearContextualMessage: true,
      conflictingPlacements: const {},
      isCompleted: isSolved,
    );

    if (!isSolved) {
      _hintRevealedForCurrentBoardState = false;
      _saveCurrentInProgress();
    }
  }

  /// Backward-compatible alias for single tap
  void tapCell(int r, int c) => singleTapCell(r, c);

  /// Backward-compatible alias for double tap dog placement
  void toggleDog(int r, int c) => doubleTapCell(r, c);

  /// Backward-compatible method to toggle cross
  void toggleMarkEmpty(int r, int c) => singleTapCell(r, c);

  /// Whether a drag-to-cross gesture is currently active.
  bool get isDragging => _isDragging;

  /// Starts a multi-cell drag-to-cross gesture at cell (r, c).
  ///
  /// Snapshots initial state for a single atomic undo, clears visited/modified sets.
  /// If starting cell has an X mark, the entire drag gesture unmarks X from visited cells.
  /// If starting cell does NOT have an X mark, the drag gesture marks empty cells with X.
  void startDragCross(int r, int c) {
    if (state.isPaused || state.isCompleted || state.isGameOver) return;
    _isDragging = true;
    _dragPreSnapshot = GameActionSnapshot(
      placements: List<DogPlacement>.from(state.placements),
      crosses: Set<Point<int>>.from(state.crosses),
    );
    _dragVisitedCells.clear();
    _dragModifiedCrosses.clear();

    if (state.hasCrossAt(r, c)) {
      _dragAction = DragAction.removeCross;
    } else {
      _dragAction = DragAction.addCross;
    }

    _processDragCell(r, c);
  }

  /// Updates the multi-cell drag gesture as pointer enters cell (r, c).
  void updateDragCross(int r, int c) {
    if (!_isDragging || state.isPaused || state.isCompleted || state.isGameOver) return;
    _processDragCell(r, c);
  }

  /// Ends the multi-cell drag gesture.
  ///
  /// Commits the complete drag action to undo history as ONE atomic action if
  /// any crosses were marked or unmarked, and saves in-progress state.
  void endDragCross() {
    if (!_isDragging) return;
    if (_dragModifiedCrosses.isNotEmpty && _dragPreSnapshot != null) {
      _hintRevealedForCurrentBoardState = false;
      state = state.copyWith(
        undoStack: [...state.undoStack, _dragPreSnapshot!],
        clearActiveHint: true,
        clearHintStage: true,
        clearHighlightedCells: true,
        clearHighlightedRow: true,
        clearHighlightedCol: true,
        clearHighlightedRegion: true,
        clearHintCell: true,
      );
      _saveCurrentInProgress();
    }
    _dragPreSnapshot = null;
    _dragVisitedCells.clear();
    _dragModifiedCrosses.clear();
    _isDragging = false;
  }

  /// Cancels the multi-cell drag gesture and safely reverts any modified crosses.
  void cancelDragCross() {
    if (!_isDragging) return;
    if (_dragPreSnapshot != null) {
      state = state.copyWith(crosses: _dragPreSnapshot!.crosses);
    }
    _dragPreSnapshot = null;
    _dragVisitedCells.clear();
    _dragModifiedCrosses.clear();
    _isDragging = false;
  }

  /// Processes an individual cell visited during a drag gesture.
  /// - If `_dragAction == DragAction.addCross`: empty cells are marked with X.
  /// - If `_dragAction == DragAction.removeCross`: crossed cells have X removed.
  /// - Cells containing dogs (locked or placed) are NEVER modified or removed.
  /// - Each cell is processed at most once during a single gesture.
  void _processDragCell(int r, int c) {
    if (r < 0 || r >= 10 || c < 0 || c >= 10) return;
    final point = Point(r, c);
    if (_dragVisitedCells.contains(point)) return;
    _dragVisitedCells.add(point);

    // If cell contains a dog (locked or placed), do NOT modify or remove it
    if (state.hasDogAt(r, c)) return;

    if (_dragAction == DragAction.addCross) {
      if (state.hasCrossAt(r, c)) return;
      final newCrosses = Set<Point<int>>.from(state.crosses)..add(point);
      _dragModifiedCrosses.add(point);

      state = state.copyWith(
        crosses: newCrosses,
        clearContextualMessage: true,
        conflictingPlacements: const {},
      );
      SoundHapticHelper.crossMark();
    } else {
      if (!state.hasCrossAt(r, c)) return;
      final newCrosses = Set<Point<int>>.from(state.crosses)..remove(point);
      _dragModifiedCrosses.add(point);

      state = state.copyWith(
        crosses: newCrosses,
        clearContextualMessage: true,
        conflictingPlacements: const {},
      );
      SoundHapticHelper.crossMark();
    }
  }

  /// Accepts the active hint by placing a dog on the hinted cell, replacing any cross.
  void acceptHint() {
    if (state.hintCell == null) return;
    doubleTapCell(state.hintCell!.x, state.hintCell!.y);
  }

  /// Undoes eligible cross actions only.
  /// Correctly placed locked dogs cannot be undone. Mistakes cannot be undone.
  void undo() {
    if (state.isPaused || state.isCompleted || state.isGameOver) return;
    if (state.undoStack.isEmpty) return;

    final previous = state.undoStack.last;
    final newUndoStack = List<GameActionSnapshot>.from(state.undoStack)..removeLast();

    state = state.copyWith(
      crosses: previous.crosses,
      clearContextualMessage: true,
      conflictingPlacements: const {},
      undoStack: newUndoStack,
      clearActiveHint: true,
      clearHintStage: true,
      clearHighlightedCells: true,
      clearHighlightedRow: true,
      clearHighlightedCol: true,
      clearHighlightedRegion: true,
      clearHintCell: true,
    );
    _hintRevealedForCurrentBoardState = false;
    _saveCurrentInProgress();
    SoundHapticHelper.undoAction();
  }

  /// Resets the current puzzle: clears all player placements, crosses, mistakes, hints, timer, and game over state.
  void resetPuzzle() {
    _timer?.cancel();
    _messageClearTimer?.cancel();
    _dragPreSnapshot = null;
    _dragVisitedCells.clear();
    _dragModifiedCrosses.clear();
    _isDragging = false;
    _hintRevealedForCurrentBoardState = false;
    ref.read(progressionProvider.notifier).clearInProgress();

    state = state.copyWith(
      placements: const [],
      crosses: const {},
      conflictingPlacements: const {},
      clearSelectedCell: true,
      clearHintCell: true,
      clearActiveHint: true,
      clearHintStage: true,
      clearHighlightedCells: true,
      clearHighlightedRow: true,
      clearHighlightedCol: true,
      clearHighlightedRegion: true,
      clearWrongPlacementCell: true,
      clearContextualMessage: true,
      timerSeconds: 0,
      hintsUsed: 0,
      mistakes: 0,
      undoStack: const [],
      isCompleted: false,
      isGameOver: false,
    );

    _startTimer();
    SoundHapticHelper.undoAction();
  }

  /// Requests a progressive hint.
  /// Deducts a hint only when a hint is actually revealed for the first time on the current board state.
  /// Prevents duplicate deductions from repeated taps.
  void useHint() => requestHint();

  /// Requests a progressive hint starting at Stage 1 (Constraint Guidance).
  void requestHint() {
    if (state.isPaused || state.isCompleted || state.isGameOver) return;

    final hint = HintService.generateHint(
      puzzle: state.puzzle,
      currentPlacements: state.placements,
      stage: HintStage.guidance,
    );

    // Deduct a hint only if a hint has not already been revealed for this board state
    final int newHintsUsed;
    if (!_hintRevealedForCurrentBoardState) {
      _hintRevealedForCurrentBoardState = true;
      newHintsUsed = state.hintsUsed + 1;
    } else {
      newHintsUsed = state.hintsUsed;
    }

    DogPlacement? targetSol;
    for (final solDog in state.puzzle.solution) {
      if (!state.hasDogAt(solDog.row, solDog.col)) {
        targetSol = solDog;
        break;
      }
    }

    state = state.copyWith(
      activeHint: hint,
      hintStage: HintStage.guidance,
      highlightedCells: hint.highlightedCells,
      highlightedRow: hint.highlightedRow,
      highlightedCol: hint.highlightedCol,
      highlightedRegion: hint.highlightedRegion,
      hintCell: targetSol != null ? Point(targetSol.row, targetSol.col) : null,
      contextualMessage: 'A little pup belongs here!',
      hintsUsed: newHintsUsed,
      conflictingPlacements: const {},
    );

    SoundHapticHelper.hintUsed();
    _saveCurrentInProgress();
  }

  /// Advances the active progressive hint to the next stage:
  /// Stage 1 (Guidance) -> Stage 2 (Elimination) -> Stage 3 (Placement).
  /// Does not deduct additional hints.
  void requestNextHintStage() {
    if (state.isPaused || state.isCompleted || state.isGameOver) return;
    if (state.activeHint == null) {
      requestHint();
      return;
    }

    final currentStage = state.activeHint!.stage;
    final HintStage nextStage;
    switch (currentStage) {
      case HintStage.guidance:
        nextStage = HintStage.elimination;
        break;
      case HintStage.elimination:
        nextStage = HintStage.placement;
        break;
      case HintStage.placement:
        nextStage = HintStage.placement;
        break;
    }

    final nextHint = HintService.generateHint(
      puzzle: state.puzzle,
      currentPlacements: state.placements,
      stage: nextStage,
    );

    state = state.copyWith(
      activeHint: nextHint,
      hintStage: nextStage,
      highlightedCells: nextHint.highlightedCells,
      highlightedRow: nextHint.highlightedRow,
      highlightedCol: nextHint.highlightedCol,
      highlightedRegion: nextHint.highlightedRegion,
      hintCell: nextStage == HintStage.placement ? nextHint.targetCell : null,
      clearHintCell: nextStage != HintStage.placement,
      selectedCell: nextStage == HintStage.placement && nextHint.targetCell != null
          ? nextHint.targetCell
          : state.selectedCell,
      contextualMessage: nextHint.message,
      conflictingPlacements: const {},
    );

    SoundHapticHelper.lightTap();
  }

  /// Dismisses the active progressive hint and clears board highlights without modifying hint counter.
  void dismissHint() {
    state = state.copyWith(
      clearActiveHint: true,
      clearHintStage: true,
      clearHighlightedCells: true,
      clearHighlightedRow: true,
      clearHighlightedCol: true,
      clearHighlightedRegion: true,
      clearHintCell: true,
      clearContextualMessage: true,
    );
  }

  /// Pauses or resumes the timer and gameplay.
  void togglePause() {
    if (state.isCompleted) return;
    state = state.copyWith(isPaused: !state.isPaused);
    SoundHapticHelper.lightTap();
  }

  void _showMessage(String message, Set<DogPlacement> conflicts) {
    _messageClearTimer?.cancel();
    state = state.copyWith(
      contextualMessage: message,
      conflictingPlacements: conflicts,
    );

    // Auto-clear message after 3.5 seconds
    _messageClearTimer = Timer(const Duration(milliseconds: 3500), () {
      state = state.copyWith(
        clearContextualMessage: true,
        conflictingPlacements: const {},
      );
    });
  }

  void _showMistakeFeedback(
    Point<int> cell,
    String message,
    int newMistakes,
    bool isGameOver, [
    Set<DogPlacement> conflicts = const {},
  ]) {
    _messageClearTimer?.cancel();
    state = state.copyWith(
      mistakes: newMistakes,
      isGameOver: isGameOver,
      wrongPlacementCell: cell,
      contextualMessage: message,
      conflictingPlacements: conflicts,
      selectedCell: cell,
    );

    // Auto-clear feedback highlight after 1.5 seconds so board returns to normal
    _messageClearTimer = Timer(const Duration(milliseconds: 1500), () {
      state = state.copyWith(
        clearWrongPlacementCell: true,
        clearContextualMessage: true,
        conflictingPlacements: const {},
      );
    });
  }

  void _saveWinStats(int time) async {
    try {
      await StatsRepository.recordWin(
        timeSeconds: time,
        puzzleId: state.puzzle.id,
      );
      ref.invalidate(statsProvider);
    } catch (_) {}
  }
}

final puzzleGameProvider =
    NotifierProvider<PuzzleGameNotifier, PuzzleGameState>(PuzzleGameNotifier.new);

final statsProvider = FutureProvider<GameStats>((ref) async {
  return await StatsRepository.loadStats();
});

final settingsProvider = FutureProvider<SettingsState>((ref) async {
  return await SettingsRepository.loadSettings();
});
