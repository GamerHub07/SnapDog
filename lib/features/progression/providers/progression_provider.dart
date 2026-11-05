import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/models/dog_placement.dart';
import '../../game/models/puzzle.dart';
import '../../game/services/puzzle_repository.dart';
import '../../game/services/puzzle_validator.dart';
import '../models/progression_state.dart';
import '../models/puzzle_progress.dart';
import '../services/progression_repository.dart';

class ProgressionNotifier extends Notifier<ProgressionState> {
  bool _disposed = false;

  @override
  ProgressionState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });

    // Load persisted state asynchronously
    _loadInitialState();
    return const ProgressionState();
  }

  Future<void> _loadInitialState() async {
    try {
      await PuzzleRepository.loadPersistedData();
      final loaded = await ProgressionRepository.loadProgression();
      if (!_disposed) {
        state = loaded;
      }
    } catch (_) {}
  }

  /// Sets state manually (useful for tests or hydration).
  void setStateForTesting(ProgressionState newState) {
    state = newState;
  }

  /// Records puzzle completion with full validation against game rules.
  /// Rejects invalid or incomplete puzzles.
  bool recordCompletion({
    required Puzzle puzzle,
    required List<DogPlacement> placements,
    required int timeSeconds,
    required int hintsUsed,
    required int mistakes,
  }) {
    // 1. Strict Validation: Invalid or incomplete puzzles CANNOT be marked completed
    if (!PuzzleValidator.isPuzzleCompleted(puzzle, placements)) {
      return false;
    }

    final existing = state.getProgress(puzzle.id);

    // 2. Best time update: only update best time if it's better (lower seconds)
    int? newBestTime;
    if (existing?.bestTimeSeconds == null) {
      newBestTime = timeSeconds;
    } else {
      newBestTime = timeSeconds < existing!.bestTimeSeconds!
          ? timeSeconds
          : existing.bestTimeSeconds;
    }

    final updatedProgress = PuzzleProgress(
      puzzleId: puzzle.id,
      isCompleted: true,
      bestTimeSeconds: newBestTime,
      lastTimeSeconds: timeSeconds,
      hintsUsed: hintsUsed,
      mistakes: mistakes,
      completedAt: DateTime.now(),
    );

    final newMap = Map<String, PuzzleProgress>.from(state.puzzleProgress)
      ..[puzzle.id] = updatedProgress;

    final nextLevel = puzzle.levelNumber + 1;
    final newHighest = max(state.highestUnlockedLevel, nextLevel);

    final newState = state.copyWith(
      puzzleProgress: newMap,
      highestUnlockedLevel: newHighest,
      currentLevel: nextLevel,
      clearInProgressState: true,
      lastPlayedPuzzleId: 'puzzle_$nextLevel',
    );

    state = newState;
    ProgressionRepository.saveProgression(newState);
    return true;
  }

  /// Saves the player's active in-progress state for the current unfinished level.
  void saveInProgress(InProgressPuzzleState inProgress) {
    if (state.isPuzzleCompleted(inProgress.puzzleId)) return;

    final newState = state.copyWith(
      inProgressState: inProgress,
      currentLevel: inProgress.levelNumber,
      lastPlayedPuzzleId: inProgress.puzzleId,
    );
    state = newState;
    ProgressionRepository.saveProgression(newState);
  }

  /// Clears in-progress state for a completed or reset level.
  void clearInProgress() {
    final newState = state.copyWith(clearInProgressState: true);
    state = newState;
    ProgressionRepository.saveProgression(newState);
  }

  /// Sets the active level.
  void setCurrentLevel(int levelNumber) {
    final newState = state.copyWith(
      currentLevel: levelNumber,
      lastPlayedPuzzleId: 'puzzle_$levelNumber',
    );
    state = newState;
    ProgressionRepository.saveProgression(newState);
  }

  /// Sets the active/last played puzzle id.
  void setLastPlayedPuzzle(String puzzleId) {
    int? lvl;
    if (puzzleId.startsWith('puzzle_')) {
      lvl = int.tryParse(puzzleId.replaceFirst('puzzle_', ''));
    }
    final newState = state.copyWith(
      lastPlayedPuzzleId: puzzleId,
      currentLevel: lvl ?? state.currentLevel,
    );
    state = newState;
    ProgressionRepository.saveProgression(newState);
  }

  /// Resets progression to default (for debugging or user reset).
  Future<void> resetProgression() async {
    const newState = ProgressionState();
    state = newState;
    await ProgressionRepository.saveProgression(newState);
  }
}

final progressionProvider =
    NotifierProvider<ProgressionNotifier, ProgressionState>(ProgressionNotifier.new);
