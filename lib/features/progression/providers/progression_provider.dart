import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/models/dog_placement.dart';
import '../../game/models/puzzle.dart';
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
    final loaded = await ProgressionRepository.loadProgression();
    if (!_disposed) {
      state = loaded;
    }
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

    final newState = state.copyWith(
      puzzleProgress: newMap,
      lastPlayedPuzzleId: puzzle.id,
    );

    state = newState;
    ProgressionRepository.saveProgression(newState);
    return true;
  }

  /// Sets the active/last played puzzle id.
  void setLastPlayedPuzzle(String puzzleId) {
    final newState = state.copyWith(lastPlayedPuzzleId: puzzleId);
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
