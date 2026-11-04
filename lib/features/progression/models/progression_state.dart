import '../../game/models/puzzle.dart';
import '../../game/services/puzzle_repository.dart';
import 'puzzle_progress.dart';

/// Tracks player progression across all puzzles and difficulties.
class ProgressionState {
  final Map<String, PuzzleProgress> puzzleProgress;
  final String? lastPlayedPuzzleId;

  const ProgressionState({
    this.puzzleProgress = const {},
    this.lastPlayedPuzzleId,
  });

  bool isPuzzleCompleted(String puzzleId) {
    return puzzleProgress[puzzleId]?.isCompleted ?? false;
  }

  PuzzleProgress? getProgress(String puzzleId) {
    return puzzleProgress[puzzleId];
  }

  /// Determines if a specific puzzle is currently unlocked.
  /// Rules:
  /// 1. Initially, Easy puzzle 1 is unlocked.
  /// 2. Completing a puzzle unlocks the next puzzle in that difficulty tier.
  /// 3. Completing the final puzzle in Easy unlocks Medium (specifically Medium puzzle 1).
  /// 4. Completing the final puzzle in Medium unlocks Hard (specifically Hard puzzle 1).
  /// 5. Completed puzzles remain unlocked and can be replayed.
  bool isPuzzleUnlocked(String puzzleId) {
    final puzzle = PuzzleRepository.getPuzzleById(puzzleId);
    final easyPuzzles = PuzzleRepository.getPuzzlesByDifficulty(Difficulty.easy);
    final mediumPuzzles = PuzzleRepository.getPuzzlesByDifficulty(Difficulty.medium);
    final hardPuzzles = PuzzleRepository.getPuzzlesByDifficulty(Difficulty.hard);

    switch (puzzle.difficulty) {
      case Difficulty.easy:
        final index = easyPuzzles.indexWhere((p) => p.id == puzzleId);
        if (index <= 0) return true; // First Easy puzzle is always unlocked
        return isPuzzleCompleted(easyPuzzles[index - 1].id);

      case Difficulty.medium:
        if (!isDifficultyUnlocked(Difficulty.medium)) return false;
        final index = mediumPuzzles.indexWhere((p) => p.id == puzzleId);
        if (index <= 0) return true;
        return isPuzzleCompleted(mediumPuzzles[index - 1].id);

      case Difficulty.hard:
        if (!isDifficultyUnlocked(Difficulty.hard)) return false;
        final index = hardPuzzles.indexWhere((p) => p.id == puzzleId);
        if (index <= 0) return true;
        return isPuzzleCompleted(hardPuzzles[index - 1].id);
    }
  }

  /// Determines if an entire difficulty category is unlocked.
  bool isDifficultyUnlocked(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return true;
      case Difficulty.medium:
        final easyPuzzles = PuzzleRepository.getPuzzlesByDifficulty(Difficulty.easy);
        return easyPuzzles.isNotEmpty && isPuzzleCompleted(easyPuzzles.last.id);
      case Difficulty.hard:
        final mediumPuzzles = PuzzleRepository.getPuzzlesByDifficulty(Difficulty.medium);
        return isDifficultyUnlocked(Difficulty.medium) &&
            mediumPuzzles.isNotEmpty &&
            isPuzzleCompleted(mediumPuzzles.last.id);
    }
  }

  /// Total number of completed puzzles.
  int get completedPuzzlesCount =>
      puzzleProgress.values.where((p) => p.isCompleted).length;

  /// Count of completed puzzles for a given difficulty.
  int completedCountForDifficulty(Difficulty diff) {
    final puzzles = PuzzleRepository.getPuzzlesByDifficulty(diff);
    return puzzles.where((p) => isPuzzleCompleted(p.id)).length;
  }

  /// Finds the next uncompleted unlocked puzzle in progression order.
  Puzzle getNextAvailablePuzzle() {
    for (final p in PuzzleRepository.puzzles) {
      if (!isPuzzleCompleted(p.id) && isPuzzleUnlocked(p.id)) {
        return p;
      }
    }
    return PuzzleRepository.puzzles.first;
  }

  /// Resumes the most recently active available puzzle, or next available puzzle.
  Puzzle getResumePuzzle() {
    if (lastPlayedPuzzleId != null) {
      if (isPuzzleUnlocked(lastPlayedPuzzleId!)) {
        return PuzzleRepository.getPuzzleById(lastPlayedPuzzleId!);
      }
    }
    return getNextAvailablePuzzle();
  }

  ProgressionState copyWith({
    Map<String, PuzzleProgress>? puzzleProgress,
    String? lastPlayedPuzzleId,
  }) {
    return ProgressionState(
      puzzleProgress: puzzleProgress ?? this.puzzleProgress,
      lastPlayedPuzzleId: lastPlayedPuzzleId ?? this.lastPlayedPuzzleId,
    );
  }
}
