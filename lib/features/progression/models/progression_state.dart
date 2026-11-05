import 'dart:math';
import '../../game/models/dog_placement.dart';
import '../../game/models/puzzle.dart';
import '../../game/services/puzzle_repository.dart';
import 'puzzle_progress.dart';

/// Represents in-progress moves, marks, and state of an unfinished puzzle.
class InProgressPuzzleState {
  final String puzzleId;
  final int levelNumber;
  final List<DogPlacement> placements;
  final Set<Point<int>> crosses;
  final int timerSeconds;
  final int mistakes;
  final int hintsUsed;

  const InProgressPuzzleState({
    required this.puzzleId,
    required this.levelNumber,
    required this.placements,
    required this.crosses,
    required this.timerSeconds,
    required this.mistakes,
    required this.hintsUsed,
  });

  Map<String, dynamic> toMap() => {
    'puzzleId': puzzleId,
    'levelNumber': levelNumber,
    'placements': placements.map((p) => {'row': p.row, 'col': p.col}).toList(),
    'crosses': crosses.map((c) => {'row': c.x, 'col': c.y}).toList(),
    'timerSeconds': timerSeconds,
    'mistakes': mistakes,
    'hintsUsed': hintsUsed,
  };

  factory InProgressPuzzleState.fromMap(Map<String, dynamic> map) {
    final rawPlacements = (map['placements'] as List<dynamic>?) ?? [];
    final rawCrosses = (map['crosses'] as List<dynamic>?) ?? [];
    return InProgressPuzzleState(
      puzzleId: (map['puzzleId'] as String?) ?? 'puzzle_1',
      levelNumber: (map['levelNumber'] as int?) ?? 1,
      placements: rawPlacements
          .map((p) => DogPlacement((p as Map)['row'] as int, p['col'] as int))
          .toList(),
      crosses: rawCrosses
          .map((c) => Point<int>((c as Map)['row'] as int, c['col'] as int))
          .toSet(),
      timerSeconds: (map['timerSeconds'] as int?) ?? 0,
      mistakes: (map['mistakes'] as int?) ?? 0,
      hintsUsed: (map['hintsUsed'] as int?) ?? 0,
    );
  }
}

/// Tracks player progression across endless levels.
class ProgressionState {
  final Map<String, PuzzleProgress> puzzleProgress;
  final int highestUnlockedLevel;
  final int currentLevel;
  final InProgressPuzzleState? inProgressState;
  final String? lastPlayedPuzzleId;

  const ProgressionState({
    this.puzzleProgress = const {},
    this.highestUnlockedLevel = 1,
    this.currentLevel = 1,
    this.inProgressState,
    this.lastPlayedPuzzleId,
  });

  bool isPuzzleCompleted(String puzzleId) {
    return puzzleProgress[puzzleId]?.isCompleted ?? false;
  }

  bool isLevelCompleted(int levelNumber) {
    return isPuzzleCompleted('puzzle_$levelNumber');
  }

  PuzzleProgress? getProgress(String puzzleId) {
    return puzzleProgress[puzzleId];
  }

  /// Determines if a specific level is currently unlocked.
  /// Level 1 is always unlocked.
  /// Level N is unlocked if N <= highestUnlockedLevel or if Level N - 1 is completed.
  bool isLevelUnlocked(int levelNumber) {
    if (levelNumber <= 1) return true;
    if (levelNumber <= highestUnlockedLevel) return true;
    return isLevelCompleted(levelNumber - 1);
  }

  /// Backward-compatible check for puzzleId
  bool isPuzzleUnlocked(String puzzleId) {
    if (puzzleId.startsWith('puzzle_')) {
      final lvl = int.tryParse(puzzleId.replaceFirst('puzzle_', ''));
      if (lvl != null) {
        return isLevelUnlocked(lvl);
      }
    }
    final puzzle = PuzzleRepository.getPuzzleById(puzzleId);
    return isLevelUnlocked(puzzle.levelNumber);
  }

  /// Backward-compatible difficulty check
  bool isDifficultyUnlocked(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return true;
      case Difficulty.medium:
        return highestUnlockedLevel >= 4 || isLevelCompleted(3);
      case Difficulty.hard:
        return highestUnlockedLevel >= 7 || isLevelCompleted(6);
    }
  }

  /// Total count of completed puzzles.
  int get completedPuzzlesCount =>
      puzzleProgress.values.where((p) => p.isCompleted).length;

  /// Count of completed puzzles for a given difficulty.
  int completedCountForDifficulty(Difficulty diff) {
    final puzzles = PuzzleRepository.getPuzzlesByDifficulty(diff);
    return puzzles.where((p) => isPuzzleCompleted(p.id)).length;
  }

  /// Returns the next uncompleted unlocked puzzle.
  Puzzle getNextAvailablePuzzle() {
    int lvl = 1;
    while (isLevelCompleted(lvl)) {
      lvl++;
    }
    return PuzzleRepository.getPuzzleByLevel(lvl);
  }

  /// Resumes the current unfinished level.
  /// Guaranteed NEVER to return a completed puzzle!
  Puzzle getResumePuzzle() {
    // 1. If inProgressState exists and is not completed, resume it
    if (inProgressState != null && !isPuzzleCompleted(inProgressState!.puzzleId)) {
      return PuzzleRepository.getPuzzleByLevel(inProgressState!.levelNumber);
    }

    // 2. If currentLevel is not completed and unlocked, resume it
    if (!isLevelCompleted(currentLevel) && isLevelUnlocked(currentLevel)) {
      return PuzzleRepository.getPuzzleByLevel(currentLevel);
    }

    // 3. Otherwise find the first uncompleted unlocked level
    return getNextAvailablePuzzle();
  }

  ProgressionState copyWith({
    Map<String, PuzzleProgress>? puzzleProgress,
    int? highestUnlockedLevel,
    int? currentLevel,
    InProgressPuzzleState? inProgressState,
    bool clearInProgressState = false,
    String? lastPlayedPuzzleId,
  }) {
    return ProgressionState(
      puzzleProgress: puzzleProgress ?? this.puzzleProgress,
      highestUnlockedLevel: highestUnlockedLevel ?? this.highestUnlockedLevel,
      currentLevel: currentLevel ?? this.currentLevel,
      inProgressState: clearInProgressState ? null : (inProgressState ?? this.inProgressState),
      lastPlayedPuzzleId: lastPlayedPuzzleId ?? this.lastPlayedPuzzleId,
    );
  }
}
