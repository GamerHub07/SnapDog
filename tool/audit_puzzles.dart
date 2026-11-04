// ignore_for_file: avoid_print

import 'dart:io';
import 'package:snapdog/features/game/models/dog_placement.dart';
import 'package:snapdog/features/game/models/puzzle.dart';
import 'package:snapdog/features/game/services/puzzle_repository.dart';
import 'package:snapdog/features/game/services/puzzle_solver.dart';
import 'package:snapdog/features/game/services/puzzle_validator.dart';

void main() {
  print('=====================================================');
  print('          SNAPDOG PUZZLE COMPREHENSIVE AUDIT          ');
  print('=====================================================\n');

  int validPuzzlesCount = 0;
  int zeroCount = 0;
  int uniqueCount = 0;
  int multipleCount = 0;
  int cappedCount = 0;

  final totalPuzzles = PuzzleRepository.puzzles.length;

  for (int i = 0; i < totalPuzzles; i++) {
    final puzzle = PuzzleRepository.puzzles[i];
    print('-----------------------------------------------------');
    print('PUZZLE ${i + 1}: "${puzzle.title}" (${puzzle.difficultyLabel})');
    print('-----------------------------------------------------');

    // 1. Structure Audit: 100 cells, 10 regions, each cell has 1 region, all regions connected
    final structureError = auditStructure(puzzle);
    if (structureError == null) {
      print('✓ Structure: 100 cells, exactly 10 regions, all connected.');
    } else {
      print('✗ Structure Error: $structureError');
    }

    // 2. Stored Solution Audit: Bounds check, exactly 10 unique positions, all rules satisfied
    final solutionError = auditSolution(puzzle);
    if (solutionError == null) {
      print('✓ Stored Solution: 10 unique positions, bounded, satisfies all rules.');
    } else {
      print('✗ Stored Solution Error: $solutionError');
    }

    // 3. Solver Result Audit: Counts solutions, distinguishes zero, unique, multiple, capped
    final solveResult = PuzzleSolver.countSolutions(puzzle, maxCount: 20);
    switch (solveResult.status) {
      case SolutionStatus.zero:
        zeroCount++;
        break;
      case SolutionStatus.unique:
        uniqueCount++;
        break;
      case SolutionStatus.multiple:
        multipleCount++;
        break;
      case SolutionStatus.capped:
        cappedCount++;
        break;
    }
    print('✓ Solver Output: $solveResult');

    final solverError = auditSolver(puzzle, solveResult);
    if (solverError == null) {
      print('✓ Solver Check: Confirmed unique solution matching stored solution.');
    } else {
      print('✗ Solver Check Error: $solverError');
    }

    // 4. Fixed-Placement Audit: Valid fix, row/col/region/touching conflicts, out-of-bounds
    final fixedPlacementError = auditFixedPlacements(puzzle);
    if (fixedPlacementError == null) {
      print('✓ Fixed Placements: Verified enforcement and conflict handling.');
    } else {
      print('✗ Fixed Placement Error: $fixedPlacementError');
    }

    // A puzzle is counted as valid ONLY IF structure, stored solution, solver result, and fixed placements all pass
    final isPuzzleValid = structureError == null &&
        solutionError == null &&
        solverError == null &&
        fixedPlacementError == null;

    if (isPuzzleValid) {
      validPuzzlesCount++;
      print('✓ Overall Puzzle Status: VALID');
    } else {
      print('✗ Overall Puzzle Status: INVALID');
    }

    print('');
  }

  // 5. Audit all 8 neighbors adjacency test
  print('-----------------------------------------------------');
  print('NEIGHBOR ADJACENCY RULE AUDIT (ALL 8 DIRECTIONS)');
  print('-----------------------------------------------------');
  final neighborAuditResult = auditAllEightNeighbors();
  final neighborAuditPassed = neighborAuditResult == null;
  if (neighborAuditPassed) {
    print('✓ All 8 neighboring positions around a dog correctly trigger touching violation.');
  } else {
    print('✗ Neighbor Adjacency Error: $neighborAuditResult');
  }

  // Overall audit status: requires all puzzles valid, all unique, zero non-uniques, neighbor audit passed
  final overallPassed = (validPuzzlesCount == totalPuzzles) &&
      (uniqueCount == totalPuzzles) &&
      (zeroCount == 0) &&
      (multipleCount == 0) &&
      (cappedCount == 0) &&
      neighborAuditPassed;

  print('\n=====================================================');
  print('                    SUMMARY REPORT                   ');
  print('=====================================================');
  print('Total Puzzles Audited : $totalPuzzles');
  print('Valid Puzzles         : $validPuzzlesCount / $totalPuzzles (all 4 checks passed)');
  print('');
  print('Solution Status Breakdown:');
  print('  - Zero solutions    : $zeroCount');
  print('  - Unique solutions  : $uniqueCount');
  print('  - Multiple solutions: $multipleCount');
  print('  - Capped solutions  : $cappedCount');
  print('');
  print('Eight-Neighbor Audit  : ${neighborAuditPassed ? "PASSED" : "FAILED"}');
  print('Overall Audit Status  : ${overallPassed ? "PASSED" : "FAILED"}');
  print('=====================================================\n');

  if (!overallPassed) {
    exit(1);
  }
}

/// Audits that the puzzle has 100 cells, 10 distinct connected regions.
String? auditStructure(Puzzle puzzle) {
  if (puzzle.regionMap.length != 10) return 'Rows count is ${puzzle.regionMap.length}, expected 10';

  for (int r = 0; r < 10; r++) {
    if (puzzle.regionMap[r].length != 10) {
      return 'Row $r has ${puzzle.regionMap[r].length} columns, expected 10';
    }
    for (int c = 0; c < 10; c++) {
      final reg = puzzle.regionMap[r][c];
      if (reg < 0 || reg >= 10) {
        return 'Cell ($r,$c) has invalid region $reg, expected 0..9';
      }
    }
  }

  // Verify exactly 10 distinct regions exist
  final regions = <int>{};
  for (int r = 0; r < 10; r++) {
    for (int c = 0; c < 10; c++) {
      regions.add(puzzle.regionMap[r][c]);
    }
  }
  if (regions.length != 10) {
    return 'Puzzle has ${regions.length} distinct regions, expected 10';
  }

  // Verify all 10 regions are connected via BFS
  for (int reg = 0; reg < 10; reg++) {
    final cells = <String>{};
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        if (puzzle.regionMap[r][c] == reg) cells.add('$r,$c');
      }
    }
    if (cells.isEmpty) return 'Region $reg has no cells';

    final visited = <String>{};
    final q = [cells.first];
    visited.add(cells.first);

    while (q.isNotEmpty) {
      final curr = q.removeLast().split(',').map(int.parse).toList();
      final cr = curr[0];
      final cc = curr[1];

      final neighbors = [
        '${cr + 1},$cc',
        '${cr - 1},$cc',
        '$cr,${cc + 1}',
        '$cr,${cc - 1}',
      ];

      for (final n in neighbors) {
        if (cells.contains(n) && !visited.contains(n)) {
          visited.add(n);
          q.add(n);
        }
      }
    }

    if (visited.length != cells.length) {
      return 'Region $reg is disconnected (visited ${visited.length} of ${cells.length} cells)';
    }
  }

  return null;
}

/// Audits bounds, 10 unique positions, and rules satisfaction for stored solution.
String? auditSolution(Puzzle puzzle) {
  final sol = puzzle.solution;

  // 1. Exactly 10 positions
  if (sol.length != 10) {
    return 'Solution has ${sol.length} dogs, expected 10';
  }

  // 2. Exactly 10 unique positions
  final uniquePositions = sol.toSet();
  if (uniquePositions.length != 10) {
    return 'Solution contains duplicate positions (only ${uniquePositions.length} unique)';
  }

  // 3. Bounds checking for all coordinates before accessing regionMap
  for (final p in sol) {
    if (p.row < 0 || p.row >= 10 || p.col < 0 || p.col >= 10) {
      return 'Dog at (${p.row}, ${p.col}) is out of bounds [0..9, 0..9]';
    }
  }

  // 4. Exactly 1 dog per row
  final rows = sol.map((p) => p.row).toSet();
  if (rows.length != 10) {
    return 'Solution has duplicate rows (covers ${rows.length} rows)';
  }

  // 5. Exactly 1 dog per column
  final cols = sol.map((p) => p.col).toSet();
  if (cols.length != 10) {
    return 'Solution has duplicate columns (covers ${cols.length} columns)';
  }

  // 6. Exactly 1 dog per color region
  final regions = sol.map((p) => puzzle.getRegionAt(p.row, p.col)).toSet();
  if (regions.length != 10) {
    return 'Solution covers ${regions.length} regions, expected 10';
  }

  // 7. No touching rule (horizontal, vertical, diagonal)
  if (!PuzzleValidator.areDogsNotTouching(sol)) {
    return 'Solution violates the no-touching rule';
  }

  // 8. Overall completion validation
  if (!PuzzleValidator.isPuzzleCompleted(puzzle, sol)) {
    return 'PuzzleValidator.isPuzzleCompleted returned false for stored solution';
  }

  return null;
}

/// Audits solver results against stored solution.
String? auditSolver(Puzzle puzzle, SolutionCountResult solveResult) {
  if (solveResult.status == SolutionStatus.zero) {
    return 'Solver found 0 solutions for puzzle "${puzzle.title}". Expected 1 unique solution.';
  }
  if (solveResult.status == SolutionStatus.multiple) {
    return 'Solver found ${solveResult.count} solutions for puzzle "${puzzle.title}". Expected exactly 1 unique solution.';
  }
  if (solveResult.status == SolutionStatus.capped) {
    return 'Solver found at least ${solveResult.count} solutions (capped) for puzzle "${puzzle.title}". Expected exactly 1 unique solution.';
  }
  if (!solveResult.isUnique) {
    return 'Solver did not report a unique solution (status=${solveResult.status}, count=${solveResult.count}).';
  }

  // Retrieve actual solution and verify it matches puzzle.solution
  final solutions = PuzzleSolver.solve(puzzle, maxSolutions: 2);
  if (solutions.length != 1) {
    return 'PuzzleSolver.solve returned ${solutions.length} solutions, expected exactly 1.';
  }

  final solved = solutions.first.toSet();
  final expected = puzzle.solution.toSet();
  if (solved.length != expected.length || !solved.containsAll(expected)) {
    return 'Solver solution does not match stored solution: solved=$solved, expected=$expected';
  }

  return null;
}

/// Audits fixed-placement enforcement and conflict handling.
String? auditFixedPlacements(Puzzle puzzle) {
  if (puzzle.solution.isEmpty) {
    return 'Puzzle has no stored solution to test fixed placements against.';
  }

  // 1. Valid fixed placement from solution should still yield unique solution matching stored
  final firstDog = puzzle.solution.first;
  final validFixResult = PuzzleSolver.countSolutions(
    puzzle,
    maxCount: 2,
    fixedPlacements: [firstDog],
  );
  if (!validFixResult.isUnique) {
    return 'Fixed placement with valid dog at $firstDog returned $validFixResult instead of unique solution.';
  }

  // 2. Conflicting fixed placement: Same row
  final rowConflict = PuzzleSolver.countSolutions(
    puzzle,
    fixedPlacements: [
      const DogPlacement(0, 0),
      const DogPlacement(0, 5),
    ],
  );
  if (rowConflict.status != SolutionStatus.zero) {
    return 'Same-row fixed placement conflict was not rejected (status=${rowConflict.status}).';
  }

  // 3. Conflicting fixed placement: Same column
  final colConflict = PuzzleSolver.countSolutions(
    puzzle,
    fixedPlacements: [
      const DogPlacement(0, 0),
      const DogPlacement(5, 0),
    ],
  );
  if (colConflict.status != SolutionStatus.zero) {
    return 'Same-column fixed placement conflict was not rejected (status=${colConflict.status}).';
  }

  // 4. Conflicting fixed placement: Same region
  int? r1, c1, r2, c2;
  outer:
  for (int r = 0; r < 10; r++) {
    for (int c = 0; c < 10; c++) {
      final reg = puzzle.getRegionAt(r, c);
      for (int rNext = 0; rNext < 10; rNext++) {
        for (int cNext = 0; cNext < 10; cNext++) {
          if ((r != rNext || c != cNext) &&
              puzzle.getRegionAt(rNext, cNext) == reg &&
              (r - rNext).abs() > 1 &&
              c != cNext) {
            r1 = r; c1 = c; r2 = rNext; c2 = cNext;
            break outer;
          }
        }
      }
    }
  }
  if (r1 != null && c1 != null && r2 != null && c2 != null) {
    final regionConflict = PuzzleSolver.countSolutions(
      puzzle,
      fixedPlacements: [
        DogPlacement(r1, c1),
        DogPlacement(r2, c2),
      ],
    );
    if (regionConflict.status != SolutionStatus.zero) {
      return 'Same-region fixed placement conflict at ($r1,$c1) and ($r2,$c2) was not rejected (status=${regionConflict.status}).';
    }
  }

  // 5. Conflicting fixed placement: Touching horizontally, vertically, diagonally
  final touchingOffsets = [
    [-1, -1], [-1, 0], [-1, 1],
    [0, -1],           [0, 1],
    [1, -1],  [1, 0],  [1, 1],
  ];
  for (final offset in touchingOffsets) {
    final p1 = const DogPlacement(4, 4);
    final p2 = DogPlacement(4 + offset[0], 4 + offset[1]);
    final touchingConflict = PuzzleSolver.countSolutions(
      puzzle,
      fixedPlacements: [p1, p2],
    );
    if (touchingConflict.status != SolutionStatus.zero) {
      return 'Touching fixed placement conflict between $p1 and $p2 was not rejected (status=${touchingConflict.status}).';
    }
  }

  // 6. Conflicting fixed placement: Out-of-bounds coordinates
  final oobPlacements = [
    const DogPlacement(-1, 0),
    const DogPlacement(0, -1),
    const DogPlacement(10, 0),
    const DogPlacement(0, 10),
  ];
  for (final oob in oobPlacements) {
    final oobConflict = PuzzleSolver.countSolutions(
      puzzle,
      fixedPlacements: [oob],
    );
    if (oobConflict.status != SolutionStatus.zero) {
      return 'Out-of-bounds fixed placement at $oob was not rejected (status=${oobConflict.status}).';
    }
  }

  // 7. Conflicting fixed placement: Exceeding 10 dogs
  final elevenDogs = List.generate(11, (i) => DogPlacement(i, i));
  final excessConflict = PuzzleSolver.countSolutions(
    puzzle,
    fixedPlacements: elevenDogs,
  );
  if (excessConflict.status != SolutionStatus.zero) {
    return 'Excess fixed placements (>10 dogs) was not rejected (status=${excessConflict.status}).';
  }

  // 8. Incompatible fixed placement: Cell in same row as firstDog with wrong column
  final wrongDog = DogPlacement(firstDog.row, (firstDog.col + 1) % 10);
  final incompatibleResult = PuzzleSolver.countSolutions(
    puzzle,
    maxCount: 2,
    fixedPlacements: [wrongDog],
  );
  if (incompatibleResult.status != SolutionStatus.zero) {
    return 'Incompatible fixed placement at $wrongDog produced ${incompatibleResult.count} solutions, expected 0.';
  }

  return null;
}

/// Tests all eight neighboring positions around a dog.
String? auditAllEightNeighbors() {
  const centerDog = DogPlacement(5, 5);

  final eightOffsets = [
    [-1, -1], // Top-Left diagonal
    [-1,  0], // Top vertical
    [-1,  1], // Top-Right diagonal
    [ 0, -1], // Left horizontal
    [ 0,  1], // Right horizontal
    [ 1, -1], // Bottom-Left diagonal
    [ 1,  0], // Bottom vertical
    [ 1,  1], // Bottom-Right diagonal
  ];

  for (final offset in eightOffsets) {
    final neighborDog = DogPlacement(centerDog.row + offset[0], centerDog.col + offset[1]);
    final touchingPair = [centerDog, neighborDog];

    if (PuzzleValidator.areDogsNotTouching(touchingPair)) {
      return 'Offset $offset at $neighborDog was not detected as touching!';
    }
  }

  return null;
}
