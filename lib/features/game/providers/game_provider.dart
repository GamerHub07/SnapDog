import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapdog/core/utils/sound_haptic_helper.dart';
import 'package:snapdog/features/game/models/dog_placement.dart';
import 'package:snapdog/features/game/models/puzzle.dart';
import 'package:snapdog/features/game/services/puzzle_repository.dart';
import 'package:snapdog/features/game/services/puzzle_validator.dart';
import 'package:snapdog/features/progression/providers/progression_provider.dart';
import 'package:snapdog/features/settings/models/settings_state.dart';
import 'package:snapdog/features/statistics/models/game_stats.dart';

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
    return hintCell != null && hintCell!.x == row && hintCell!.y == col;
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
    final nextClashes = PuzzleValidator.findClashingPlacements(nextPuzzle, nextPlacements);

    return PuzzleGameState(
      puzzle: nextPuzzle,
      puzzleIndex: puzzleIndex ?? this.puzzleIndex,
      placements: nextPlacements,
      clashingPlacements: nextClashes,
      conflictingPlacements: conflictingPlacements ?? this.conflictingPlacements,
      crosses: crosses ?? (markedEmptyCells ?? this.crosses),
      selectedCell: clearSelectedCell ? null : (selectedCell ?? this.selectedCell),
      hintCell: clearHintCell ? null : (hintCell ?? this.hintCell),
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

  @override
  PuzzleGameState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _messageClearTimer?.cancel();
    });

    final initialPuzzle = PuzzleRepository.getPuzzleByIndex(0);
    _startTimer();

    return PuzzleGameState(
      puzzle: initialPuzzle,
      puzzleIndex: 0,
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

  /// Loads a specific puzzle by index.
  void loadPuzzle(int index) {
    _timer?.cancel();
    _messageClearTimer?.cancel();
    final puzzle = PuzzleRepository.getPuzzleByIndex(index);

    state = PuzzleGameState(
      puzzle: puzzle,
      puzzleIndex: index,
      placements: const [],
      clashingPlacements: const {},
      conflictingPlacements: const {},
      crosses: const {},
      selectedCell: null,
      hintCell: null,
      wrongPlacementCell: null,
      contextualMessage: null,
      timerSeconds: 0,
      isPaused: false,
      isCompleted: false,
      isGameOver: false,
      hintsUsed: 0,
      mistakes: 0,
      undoStack: const [],
    );

    _startTimer();
    SoundHapticHelper.successVibrate();
    ref.read(progressionProvider.notifier).setLastPlayedPuzzle(puzzle.id);
  }

  /// Loads a specific puzzle by its unique ID.
  void loadPuzzleById(String id) {
    final puzzle = PuzzleRepository.getPuzzleById(id);
    final idx = PuzzleRepository.getPuzzleIndex(puzzle);
    loadPuzzle(idx >= 0 ? idx : 0);
  }

  /// Advances to the next unlocked puzzle in progression.
  void nextPuzzle() {
    final nextIndex = state.puzzleIndex + 1;
    if (nextIndex < PuzzleRepository.totalCount) {
      loadPuzzle(nextIndex);
    } else {
      loadPuzzle(0);
    }
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
      );

      SoundHapticHelper.crossMark();
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
    );

    SoundHapticHelper.crossMark();
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

    // Clear hint if placed on the hint cell
    final clearHint = state.hintCell == Point(r, c);

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
      clearHintCell: clearHint,
      clearContextualMessage: true,
      conflictingPlacements: const {},
      isCompleted: isSolved,
    );
  }

  /// Backward-compatible alias for single tap
  void tapCell(int r, int c) => singleTapCell(r, c);

  /// Backward-compatible alias for double tap dog placement
  void toggleDog(int r, int c) => doubleTapCell(r, c);

  /// Backward-compatible method to toggle cross
  void toggleMarkEmpty(int r, int c) => singleTapCell(r, c);

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
    );
    SoundHapticHelper.undoAction();
  }

  /// Resets the current puzzle: clears all player placements, crosses, mistakes, hints, timer, and game over state.
  void resetPuzzle() {
    _timer?.cancel();
    _messageClearTimer?.cancel();

    state = state.copyWith(
      placements: const [],
      crosses: const {},
      conflictingPlacements: const {},
      clearSelectedCell: true,
      clearHintCell: true,
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

  /// Uses a hint by finding an empty cell from the verified solution that should contain a dog.
  /// Highlights that cell and shows "A little pup belongs here!". Never reveals the entire solution.
  void useHint() {
    if (state.isPaused || state.isCompleted || state.isGameOver) return;

    // Find an empty cell that should contain a dog according to the verified solution
    DogPlacement? hintTarget;
    for (final solDog in state.puzzle.solution) {
      if (!state.hasDogAt(solDog.row, solDog.col)) {
        hintTarget = solDog;
        break;
      }
    }

    if (hintTarget == null) return;

    state = state.copyWith(
      selectedCell: Point(hintTarget.row, hintTarget.col),
      hintCell: Point(hintTarget.row, hintTarget.col),
      hintsUsed: state.hintsUsed + 1,
      contextualMessage: 'A little pup belongs here!',
      conflictingPlacements: const {},
    );

    SoundHapticHelper.hintUsed();
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
    final currentStats = await StatsRepository.loadStats();
    final updated = currentStats.copyWith(
      gamesPlayed: currentStats.gamesPlayed + 1,
      gamesWon: currentStats.gamesWon + 1,
      currentStreak: currentStats.currentStreak + 1,
      bestStreak: max(currentStats.bestStreak, currentStats.currentStreak + 1),
    );
    await StatsRepository.saveStats(updated);
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
