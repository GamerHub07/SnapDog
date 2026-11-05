import 'package:flutter_test/flutter_test.dart';
import 'package:snapdog/features/game/models/dog_placement.dart';
import 'package:snapdog/features/game/models/puzzle.dart';
import 'package:snapdog/features/game/services/puzzle_generator.dart';
import 'package:snapdog/features/game/services/puzzle_repository.dart';
import 'package:snapdog/features/game/services/puzzle_solver.dart';
import 'package:snapdog/features/game/services/puzzle_validator.dart';

void main() {
  group('SnapDog Step 1: Puzzle Solver & Unique-Solution Validator Tests', () {
    // 1. A puzzle with exactly one solution
    test('1. A puzzle with exactly one solution', () {
      final puzzle = PuzzleRepository.puzzles[0]; // Puppy Park (Level 1)
      final result = PuzzleSolver.validateUniqueness(puzzle);

      expect(result.status, equals(UniqueSolutionStatus.UNIQUE_SOLUTION));
      expect(result.isUnique, isTrue);
      expect(result.hasZeroSolutions, isFalse);
      expect(result.hasMultipleSolutions, isFalse);
      expect(result.solutionsFound, equals(1));
      expect(result.solution, isNotNull);
      expect(result.solution!.length, equals(10));
      expect(result.solution, equals(puzzle.solution));

      expect(PuzzleSolver.hasUniqueSolution(puzzle), isTrue);
      expect(PuzzleSolver.findSolution(puzzle), equals(puzzle.solution));

      final countResult = PuzzleSolver.countSolutions(puzzle, maxCount: 2);
      expect(countResult.count, equals(1));
      expect(countResult.isCapped, isFalse);
      expect(countResult.isUnique, isTrue);
    });

    // 2. A puzzle with no valid solution
    test('2. A puzzle with no valid solution', () {
      // Impossible puzzle: row 0 and row 1 both belong entirely to region 0.
      // Since each row needs a dog, two dogs would be forced into region 0.
      final impossiblePuzzle = Puzzle(
        id: 'impossible_puzzle',
        title: 'Impossible Layout',
        regionMap: [
          List.filled(10, 0),
          List.filled(10, 0),
          ...List.generate(8, (r) => List.filled(10, r + 2)),
        ],
        solution: const [],
      );

      final result = PuzzleSolver.validateUniqueness(impossiblePuzzle);
      expect(result.status, equals(UniqueSolutionStatus.ZERO_SOLUTIONS));
      expect(result.isUnique, isFalse);
      expect(result.hasZeroSolutions, isTrue);
      expect(result.hasMultipleSolutions, isFalse);
      expect(result.solutionsFound, equals(0));
      expect(result.solution, isNull);

      expect(PuzzleSolver.hasUniqueSolution(impossiblePuzzle), isFalse);
      expect(PuzzleSolver.findSolution(impossiblePuzzle), isNull);
      expect(PuzzleSolver.solve(impossiblePuzzle), isEmpty);

      // Malformed puzzle test: missing region 9 (only 9 distinct regions)
      final malformedPuzzle = Puzzle(
        id: 'malformed_puzzle',
        title: 'Malformed Regions',
        regionMap: List.generate(10, (r) => List.filled(10, r % 9)),
        solution: const [],
      );
      final malformedResult = PuzzleSolver.validateUniqueness(malformedPuzzle);
      expect(malformedResult.status, equals(UniqueSolutionStatus.ZERO_SOLUTIONS));
      expect(malformedResult.message, contains('distinct regions'));
    });

    // 3. A puzzle with multiple valid solutions
    test('3. A puzzle with multiple valid solutions', () {
      // Striped board where row r is entirely region r.
      // Admits dozens of valid non-touching solutions.
      final multiPuzzle = Puzzle(
        id: 'multi_puzzle',
        title: 'Multi Solution Stripes',
        regionMap: List.generate(10, (r) => List.filled(10, r)),
        solution: const [],
      );

      final result = PuzzleSolver.validateUniqueness(multiPuzzle);
      expect(result.status, equals(UniqueSolutionStatus.MULTIPLE_SOLUTIONS));
      expect(result.isUnique, isFalse);
      expect(result.hasZeroSolutions, isFalse);
      expect(result.hasMultipleSolutions, isTrue);
      // Stopped after finding 2 solutions to establish uniqueness early
      expect(result.solutionsFound, equals(2));
      expect(result.solution, isNull);

      expect(PuzzleSolver.hasUniqueSolution(multiPuzzle), isFalse);

      final multiSolutions = PuzzleSolver.solve(multiPuzzle, maxSolutions: 3);
      expect(multiSolutions.length, equals(3));
      for (final sol in multiSolutions) {
        expect(sol.length, equals(10));
        expect(PuzzleValidator.isPuzzleCompleted(multiPuzzle, sol), isTrue);
      }
    });

    // 4. Two dogs in the same row
    test('4. Two dogs in the same row', () {
      final puzzle = PuzzleRepository.puzzles[0];
      const sameRowDogs = [DogPlacement(0, 1), DogPlacement(0, 5)];

      expect(PuzzleValidator.isRowValid(sameRowDogs, 0), isFalse);

      final valResult = PuzzleValidator.validateNewPlacement(
        puzzle,
        [sameRowDogs[0]],
        sameRowDogs[1],
      );
      expect(valResult.isValid, isFalse);
      expect(valResult.violation, equals(PlacementRuleViolation.sameRow));

      final solveResult = PuzzleSolver.solve(puzzle, fixedPlacements: sameRowDogs);
      expect(solveResult, isEmpty);

      final uniqueness = PuzzleSolver.validateUniqueness(puzzle, fixedPlacements: sameRowDogs);
      expect(uniqueness.status, equals(UniqueSolutionStatus.ZERO_SOLUTIONS));
    });

    // 5. Two dogs in the same column
    test('5. Two dogs in the same column', () {
      final puzzle = PuzzleRepository.puzzles[0];
      const sameColDogs = [DogPlacement(1, 4), DogPlacement(6, 4)];

      expect(PuzzleValidator.isColumnValid(sameColDogs, 4), isFalse);

      final valResult = PuzzleValidator.validateNewPlacement(
        puzzle,
        [sameColDogs[0]],
        sameColDogs[1],
      );
      expect(valResult.isValid, isFalse);
      expect(valResult.violation, equals(PlacementRuleViolation.sameColumn));

      final solveResult = PuzzleSolver.solve(puzzle, fixedPlacements: sameColDogs);
      expect(solveResult, isEmpty);

      final uniqueness = PuzzleSolver.validateUniqueness(puzzle, fixedPlacements: sameColDogs);
      expect(uniqueness.status, equals(UniqueSolutionStatus.ZERO_SOLUTIONS));
    });

    // 6. Two dogs in the same region
    test('6. Two dogs in the same region', () {
      final puzzle = PuzzleRepository.puzzles[0];
      // In puzzle 1, cells (1, 0) and (7, 2) both belong to region 7.
      // They are in different rows (1 and 7) and different columns (0 and 2), not touching.
      expect(puzzle.getRegionAt(1, 0), equals(7));
      expect(puzzle.getRegionAt(7, 2), equals(7));

      const sameRegionDogs = [DogPlacement(1, 0), DogPlacement(7, 2)];
      expect(PuzzleValidator.isColorRegionValid(puzzle, sameRegionDogs, 7), isFalse);

      final valResult = PuzzleValidator.validateNewPlacement(
        puzzle,
        [sameRegionDogs[0]],
        sameRegionDogs[1],
      );
      expect(valResult.isValid, isFalse);
      expect(valResult.violation, equals(PlacementRuleViolation.sameRegion));

      final solveResult = PuzzleSolver.solve(puzzle, fixedPlacements: sameRegionDogs);
      expect(solveResult, isEmpty);

      final uniqueness = PuzzleSolver.validateUniqueness(puzzle, fixedPlacements: sameRegionDogs);
      expect(uniqueness.status, equals(UniqueSolutionStatus.ZERO_SOLUTIONS));
    });

    // 7. Two dogs touching diagonally
    test('7. Two dogs touching diagonally', () {
      final puzzle = PuzzleRepository.puzzles[0];
      const diagonalDogs = [DogPlacement(3, 3), DogPlacement(4, 4)];

      expect(PuzzleValidator.areDogsNotTouching(diagonalDogs), isFalse);

      final valResult = PuzzleValidator.validateNewPlacement(
        puzzle,
        [diagonalDogs[0]],
        diagonalDogs[1],
      );
      expect(valResult.isValid, isFalse);
      expect(valResult.violation, equals(PlacementRuleViolation.touching));

      final solveResult = PuzzleSolver.solve(puzzle, fixedPlacements: diagonalDogs);
      expect(solveResult, isEmpty);

      final uniqueness = PuzzleSolver.validateUniqueness(puzzle, fixedPlacements: diagonalDogs);
      expect(uniqueness.status, equals(UniqueSolutionStatus.ZERO_SOLUTIONS));
    });

    // 8. Two dogs touching horizontally or vertically
    test('8. Two dogs touching horizontally or vertically', () {
      final puzzle = PuzzleRepository.puzzles[0];

      // Horizontal touching
      const horizontalDogs = [DogPlacement(3, 3), DogPlacement(3, 4)];
      expect(PuzzleValidator.areDogsNotTouching(horizontalDogs), isFalse);
      final horizSolve = PuzzleSolver.solve(puzzle, fixedPlacements: horizontalDogs);
      expect(horizSolve, isEmpty);
      expect(
        PuzzleSolver.validateUniqueness(puzzle, fixedPlacements: horizontalDogs).status,
        equals(UniqueSolutionStatus.ZERO_SOLUTIONS),
      );

      // Vertical touching
      const verticalDogs = [DogPlacement(3, 3), DogPlacement(4, 3)];
      expect(PuzzleValidator.areDogsNotTouching(verticalDogs), isFalse);
      final vertSolve = PuzzleSolver.solve(puzzle, fixedPlacements: verticalDogs);
      expect(vertSolve, isEmpty);
      expect(
        PuzzleSolver.validateUniqueness(puzzle, fixedPlacements: verticalDogs).status,
        equals(UniqueSolutionStatus.ZERO_SOLUTIONS),
      );
    });

    // 9. A valid 10-dog solution satisfying every rule
    test('9. A valid 10-dog solution satisfying every rule', () {
      final puzzle = PuzzleRepository.puzzles[0];
      final solution = puzzle.solution;

      expect(solution.length, equals(10));
      expect(PuzzleValidator.isPuzzleCompleted(puzzle, solution), isTrue);

      // 1. One dog per row
      final rows = solution.map((p) => p.row).toSet();
      expect(rows.length, equals(10));
      for (int r = 0; r < 10; r++) {
        expect(PuzzleValidator.isRowValid(solution, r), isTrue);
      }

      // 2. One dog per column
      final cols = solution.map((p) => p.col).toSet();
      expect(cols.length, equals(10));
      for (int c = 0; c < 10; c++) {
        expect(PuzzleValidator.isColumnValid(solution, c), isTrue);
      }

      // 3. One dog per region
      final regions = solution.map((p) => puzzle.getRegionAt(p.row, p.col)).toSet();
      expect(regions.length, equals(10));
      for (int reg = 0; reg < 10; reg++) {
        expect(PuzzleValidator.isColorRegionValid(puzzle, solution, reg), isTrue);
      }

      // 4. No touching
      expect(PuzzleValidator.areDogsNotTouching(solution), isTrue);

      // 5. No clashing placements
      expect(PuzzleValidator.findClashingPlacements(puzzle, solution), isEmpty);
    });

    // 10. Solver performance on representative 10x10 puzzles
    test('10. Solver performance on representative 10x10 puzzles', () {
      final stopwatch = Stopwatch()..start();

      // Check all 9 handcrafted predefined puzzles
      for (final p in PuzzleRepository.puzzles) {
        final uniqueness = PuzzleSolver.validateUniqueness(p);
        expect(uniqueness.isUnique, isTrue,
            reason: '${p.title} must have exactly one unique solution');
      }

      // Check 10 procedurally generated endless levels (levels 10 to 19)
      for (int lvl = 10; lvl <= 19; lvl++) {
        final generated = PuzzleGenerator.generateForLevel(lvl);
        final uniqueness = PuzzleSolver.validateUniqueness(generated);
        expect(uniqueness.isUnique, isTrue,
            reason: 'Generated Level $lvl must have exactly one unique solution');
      }

      stopwatch.stop();
      final totalElapsed = stopwatch.elapsedMilliseconds;
      final avgPerPuzzle = totalElapsed / 19.0;

      // Verification: must run well within UI performance limits (<100ms per puzzle under heavy test runner load)
      expect(avgPerPuzzle, lessThan(100.0),
          reason: 'Average solve time was ${avgPerPuzzle.toStringAsFixed(2)}ms, must be < 100ms');
    });
  });
}
