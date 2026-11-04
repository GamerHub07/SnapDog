import '../models/dog_placement.dart';
import '../models/puzzle.dart';

enum SolutionStatus {
  zero,
  unique,
  multiple,
  capped,
}

class SolutionCountResult {
  final int count;
  final bool isCapped;

  const SolutionCountResult({
    required this.count,
    required this.isCapped,
  });

  bool get isUnique => !isCapped && count == 1;

  SolutionStatus get status {
    if (isCapped) return SolutionStatus.capped;
    if (count == 0) return SolutionStatus.zero;
    if (count == 1) return SolutionStatus.unique;
    return SolutionStatus.multiple;
  }

  @override
  String toString() {
    switch (status) {
      case SolutionStatus.zero:
        return '0 (No solutions)';
      case SolutionStatus.unique:
        return '1 (Unique solution)';
      case SolutionStatus.multiple:
        return '$count (Multiple solutions)';
      case SolutionStatus.capped:
        return '$count+ (Capped at $count)';
    }
  }
}

/// Exact solver that verifies puzzles, finds solutions, and checks solution uniqueness.
class PuzzleSolver {
  /// Counts solutions for [puzzle], optionally respecting [fixedPlacements].
  /// Accurately distinguishes between an exhausted search and reaching [maxCount].
  /// Handles invalid [maxCount] (<= 0) by returning 0 solutions, uncapped.
  static SolutionCountResult countSolutions(
    Puzzle puzzle, {
    int maxCount = 10,
    List<DogPlacement> fixedPlacements = const [],
  }) {
    if (maxCount <= 0) {
      return const SolutionCountResult(count: 0, isCapped: false);
    }

    // Search for maxCount + 1 solutions to determine if more solutions remain
    final solutions = solve(
      puzzle,
      maxSolutions: maxCount + 1,
      fixedPlacements: fixedPlacements,
    );

    final isCapped = solutions.length > maxCount;
    final reportedCount = isCapped ? maxCount : solutions.length;

    return SolutionCountResult(
      count: reportedCount,
      isCapped: isCapped,
    );
  }

  /// Checks if [puzzle] has exactly one unique solution.
  static bool hasUniqueSolution(
    Puzzle puzzle, {
    List<DogPlacement> fixedPlacements = const [],
  }) {
    final result = countSolutions(
      puzzle,
      maxCount: 1,
      fixedPlacements: fixedPlacements,
    );
    return result.isUnique;
  }

  /// Finds up to [maxSolutions] valid solutions for [puzzle], respecting any [fixedPlacements].
  /// If there are internal conflicts among [fixedPlacements] or invalid [maxSolutions], returns [].
  static List<List<DogPlacement>> solve(
    Puzzle puzzle, {
    int maxSolutions = 10,
    List<DogPlacement> fixedPlacements = const [],
  }) {
    if (maxSolutions <= 0) return [];

    // 1. Comprehensive verification of fixed placements
    if (fixedPlacements.length > 10) return [];

    for (int i = 0; i < fixedPlacements.length; i++) {
      final p1 = fixedPlacements[i];
      if (p1.row < 0 || p1.row >= 10 || p1.col < 0 || p1.col >= 10) return [];

      for (int j = i + 1; j < fixedPlacements.length; j++) {
        final p2 = fixedPlacements[j];
        if (p2.row < 0 || p2.row >= 10 || p2.col < 0 || p2.col >= 10) return [];

        // Conflicts between fixed placements:
        if (p1.row == p2.row) return []; // same row
        if (p1.col == p2.col) return []; // same col
        if (puzzle.getRegionAt(p1.row, p1.col) == puzzle.getRegionAt(p2.row, p2.col)) return []; // same region
        if ((p1.row - p2.row).abs() <= 1 && (p1.col - p2.col).abs() <= 1) return []; // touching
      }
    }

    final fixedMap = <int, int>{};
    for (final fp in fixedPlacements) {
      fixedMap[fp.row] = fp.col;
    }

    final solutions = <List<DogPlacement>>[];
    final current = List.filled(10, -1);
    final usedCols = List.filled(10, false);
    final usedRegions = List.filled(10, false);

    void backtrack(int row) {
      if (solutions.length >= maxSolutions) return;

      if (row == 10) {
        final placement = List.generate(10, (r) => DogPlacement(r, current[r]));
        solutions.add(placement);
        return;
      }

      // If this row has a fixed placement, only that column can be placed
      final fixedCol = fixedMap[row];
      final allowedCols = fixedCol != null ? [fixedCol] : List.generate(10, (c) => c);

      for (final col in allowedCols) {
        if (usedCols[col]) continue;

        final reg = puzzle.getRegionAt(row, col);
        if (usedRegions[reg]) continue;

        // Check horizontal, vertical, and diagonal adjacency with previous row
        if (row > 0) {
          final prevCol = current[row - 1];
          if ((col - prevCol).abs() <= 1) continue;
        }

        current[row] = col;
        usedCols[col] = true;
        usedRegions[reg] = true;

        backtrack(row + 1);

        usedCols[col] = false;
        usedRegions[reg] = false;
        current[row] = -1;
      }
    }

    backtrack(0);
    return solutions;
  }
}
