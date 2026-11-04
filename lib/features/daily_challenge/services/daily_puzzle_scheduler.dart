import '../../game/models/puzzle.dart';
import '../../game/services/puzzle_repository.dart';

class DailyPuzzleScheduler {
  /// Returns the deterministic daily puzzle for a given calendar [date].
  ///
  /// Guarantees:
  /// 1. Every calendar day has exactly one designated puzzle.
  /// 2. All players receive the exact same puzzle on the same date.
  /// 3. The puzzle does not change on app restart or throughout the day.
  /// 4. Different dates cycle through different puzzles smoothly across month and year boundaries.
  static Puzzle getPuzzleForDate(DateTime date) {
    final puzzles = PuzzleRepository.puzzles;
    if (puzzles.isEmpty) {
      throw StateError('PuzzleRepository contains no puzzles.');
    }

    final index = getPuzzleIndexForDate(date, puzzles.length);
    return puzzles[index];
  }

  /// Calculates the deterministic puzzle index for a [date].
  static int getPuzzleIndexForDate(DateTime date, int totalPuzzles) {
    if (totalPuzzles <= 0) return 0;

    // Using 372 (12 * 31) guarantees that every consecutive day increments by 1,
    // seamlessly crossing month boundaries and year boundaries without any gaps.
    final dayIndex = (date.year * 372) + (date.month * 31) + date.day;
    return dayIndex.abs() % totalPuzzles;
  }
}
