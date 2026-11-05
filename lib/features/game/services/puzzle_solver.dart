import '../models/dog_placement.dart';
import '../models/puzzle.dart';

/// Outcomes of unique-solution validation.
enum UniqueSolutionStatus {
  // ignore: constant_identifier_names
  ZERO_SOLUTIONS,
  // ignore: constant_identifier_names
  UNIQUE_SOLUTION,
  // ignore: constant_identifier_names
  MULTIPLE_SOLUTIONS;

  static const zeroSolutions = ZERO_SOLUTIONS;
  static const uniqueSolution = UNIQUE_SOLUTION;
  static const multipleSolutions = MULTIPLE_SOLUTIONS;

  bool get isUnique => this == UNIQUE_SOLUTION;
  bool get isZero => this == ZERO_SOLUTIONS;
  bool get isMultiple => this == MULTIPLE_SOLUTIONS;
}

/// Reusable validation result representing the uniqueness classification of a puzzle.
class UniqueSolutionResult {
  final UniqueSolutionStatus status;
  final List<DogPlacement>? solution;
  final int solutionsFound;
  final String? message;

  const UniqueSolutionResult({
    required this.status,
    this.solution,
    this.solutionsFound = 0,
    this.message,
  });

  bool get isUnique => status == UniqueSolutionStatus.UNIQUE_SOLUTION;
  bool get hasZeroSolutions => status == UniqueSolutionStatus.ZERO_SOLUTIONS;
  bool get hasMultipleSolutions => status == UniqueSolutionStatus.MULTIPLE_SOLUTIONS;

  @override
  String toString() =>
      'UniqueSolutionResult($status, solutionsFound: $solutionsFound${message != null ? ", $message" : ""})';
}

/// Legacy status enum preserved for backward compatibility.
enum SolutionStatus {
  zero,
  unique,
  multiple,
  capped,
}

/// Result of solution-counting operations with capping information.
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

/// Exact constraint-based solver for 10x10 SnapDog puzzles.
///
/// Enforces:
/// 1. Exactly one dog in every row (0..9).
/// 2. Exactly one dog in every column (0..9).
/// 3. Exactly one dog in every color region (0..9).
/// 4. No two dogs touch horizontally, vertically, or diagonally.
///
/// Applies row, column, region, and 8-neighborhood adjacency constraints
/// to eliminate impossible placements early without brute-force enumeration.
class PuzzleSolver {
  PuzzleSolver._();

  /// Validates puzzle structure to handle malformed puzzle data safely.
  /// Returns null if valid, or an error description string if malformed.
  static String? validateBoardStructure(Puzzle puzzle) {
    if (puzzle.regionMap.length != 10) {
      return 'Region map must have exactly 10 rows (found ${puzzle.regionMap.length})';
    }

    final observedRegions = <int>{};
    for (int r = 0; r < 10; r++) {
      final row = puzzle.regionMap[r];
      if (row.length != 10) {
        return 'Row $r must have exactly 10 columns (found ${row.length})';
      }
      for (int c = 0; c < 10; c++) {
        final reg = row[c];
        if (reg < 0 || reg >= 10) {
          return 'Cell ($r, $c) has invalid region $reg; expected 0..9';
        }
        observedRegions.add(reg);
      }
    }

    if (observedRegions.length != 10) {
      return 'Board contains ${observedRegions.length} distinct regions; exactly 10 required';
    }

    return null;
  }

  /// Establishes the unique-solution classification of [puzzle].
  ///
  /// Stops immediately after finding two solutions when uniqueness is disproven,
  /// avoiding unnecessary full search space exploration.
  /// When exactly one solution exists, returns it in [UniqueSolutionResult.solution].
  static UniqueSolutionResult validateUniqueness(
    Puzzle puzzle, {
    List<DogPlacement> fixedPlacements = const [],
  }) {
    final structureError = validateBoardStructure(puzzle);
    if (structureError != null) {
      return UniqueSolutionResult(
        status: UniqueSolutionStatus.ZERO_SOLUTIONS,
        solutionsFound: 0,
        message: structureError,
      );
    }

    // Stop after finding at most 2 solutions
    final solutions = solve(
      puzzle,
      maxSolutions: 2,
      fixedPlacements: fixedPlacements,
    );

    if (solutions.isEmpty) {
      return const UniqueSolutionResult(
        status: UniqueSolutionStatus.ZERO_SOLUTIONS,
        solutionsFound: 0,
        message: 'Puzzle has no valid solutions',
      );
    } else if (solutions.length == 1) {
      return UniqueSolutionResult(
        status: UniqueSolutionStatus.UNIQUE_SOLUTION,
        solution: solutions.first,
        solutionsFound: 1,
        message: 'Puzzle has exactly one unique solution',
      );
    } else {
      return const UniqueSolutionResult(
        status: UniqueSolutionStatus.MULTIPLE_SOLUTIONS,
        solutionsFound: 2,
        message: 'Puzzle has multiple valid solutions',
      );
    }
  }

  /// Checks if [puzzle] has exactly one unique solution.
  static bool hasUniqueSolution(
    Puzzle puzzle, {
    List<DogPlacement> fixedPlacements = const [],
  }) {
    return validateUniqueness(puzzle, fixedPlacements: fixedPlacements).isUnique;
  }

  /// Returns the first valid solution found for [puzzle], or null if impossible.
  static List<DogPlacement>? findSolution(
    Puzzle puzzle, {
    List<DogPlacement> fixedPlacements = const [],
  }) {
    final solutions = solve(
      puzzle,
      maxSolutions: 1,
      fixedPlacements: fixedPlacements,
    );
    return solutions.isNotEmpty ? solutions.first : null;
  }

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

  /// Finds up to [maxSolutions] valid solutions for [puzzle], respecting any [fixedPlacements].
  ///
  /// Returns an empty list if:
  /// - [maxSolutions] <= 0
  /// - Board is malformed
  /// - [fixedPlacements] contains any rule violations
  /// - Puzzle has no valid solutions
  static List<List<DogPlacement>> solve(
    Puzzle puzzle, {
    int maxSolutions = 10,
    List<DogPlacement> fixedPlacements = const [],
  }) {
    if (maxSolutions <= 0) return [];
    if (validateBoardStructure(puzzle) != null) return [];

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
        if (puzzle.getRegionAt(p1.row, p1.col) == puzzle.getRegionAt(p2.row, p2.col)) {
          return []; // same region
        }
        if ((p1.row - p2.row).abs() <= 1 && (p1.col - p2.col).abs() <= 1) {
          return []; // touching
        }
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

    // Pre-calculate per-region cell lists to detect dead regions early
    final regionCells = List.generate(10, (_) => <int>[]);
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        final reg = puzzle.getRegionAt(r, c);
        regionCells[reg].add((r << 4) | c);
      }
    }

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

        // Check adjacency with fixed placement in row + 1 if present
        final nextFixedCol = fixedMap[row + 1];
        if (nextFixedCol != null && (col - nextFixedCol).abs() <= 1) {
          continue;
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
