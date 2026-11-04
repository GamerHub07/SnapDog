import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapdog/features/game/models/dog_placement.dart';
import 'package:snapdog/features/game/models/puzzle.dart';
import 'package:snapdog/features/game/services/puzzle_repository.dart';
import 'package:snapdog/features/game/services/puzzle_solver.dart';
import 'package:snapdog/features/game/services/puzzle_validator.dart';

void main() {
  late Puzzle puzzle;

  setUp(() {
    puzzle = PuzzleRepository.getPuzzleByIndex(0);
  });

  group('Puzzle Structure & Coordinate Verification', () {
    test('All puzzles contain exactly 100 cells across 10 rows and 10 columns', () {
      for (final p in PuzzleRepository.puzzles) {
        expect(p.regionMap.length, equals(10));
        for (int r = 0; r < 10; r++) {
          expect(p.regionMap[r].length, equals(10));
        }
      }
    });

    test('All puzzles contain exactly 10 distinct color regions (0..9)', () {
      for (final p in PuzzleRepository.puzzles) {
        final regions = <int>{};
        for (int r = 0; r < 10; r++) {
          for (int c = 0; c < 10; c++) {
            regions.add(p.regionMap[r][c]);
          }
        }
        expect(regions.length, equals(10));
        for (int i = 0; i < 10; i++) {
          expect(regions.contains(i), isTrue);
        }
      }
    });

    test('Every color region is fully connected (no disconnected islands)', () {
      for (final p in PuzzleRepository.puzzles) {
        for (int reg = 0; reg < 10; reg++) {
          final cells = <Point<int>>[];
          for (int r = 0; r < 10; r++) {
            for (int c = 0; c < 10; c++) {
              if (p.regionMap[r][c] == reg) cells.add(Point(r, c));
            }
          }

          expect(cells.isNotEmpty, isTrue);

          // BFS connectivity check
          final visited = <Point<int>>{};
          final queue = [cells.first];
          visited.add(cells.first);

          while (queue.isNotEmpty) {
            final curr = queue.removeLast();
            final neighbors = [
              Point(curr.x + 1, curr.y),
              Point(curr.x - 1, curr.y),
              Point(curr.x, curr.y + 1),
              Point(curr.x, curr.y - 1),
            ];

            for (final n in neighbors) {
              if (n.x >= 0 && n.x < 10 && n.y >= 0 && n.y < 10) {
                if (p.regionMap[n.x][n.y] == reg && !visited.contains(n)) {
                  visited.add(n);
                  queue.add(n);
                }
              }
            }
          }

          expect(visited.length, equals(cells.length),
              reason: 'Region $reg in ${p.title} must be connected');
        }
      }
    });

    test('Every stored solution contains exactly 10 unique positions with bounds checking', () {
      for (final p in PuzzleRepository.puzzles) {
        expect(p.solution.length, equals(10));
        expect(p.solution.toSet().length, equals(10),
            reason: '${p.title} solution positions must all be unique');

        for (final dog in p.solution) {
          expect(dog.row >= 0 && dog.row < 10, isTrue);
          expect(dog.col >= 0 && dog.col < 10, isTrue);
        }
      }
    });

    test('Every region contains exactly one dog in the verified solution', () {
      for (final p in PuzzleRepository.puzzles) {
        final regionCounts = List.filled(10, 0);
        for (final dog in p.solution) {
          regionCounts[p.getRegionAt(dog.row, dog.col)]++;
        }
        for (int reg = 0; reg < 10; reg++) {
          expect(regionCounts[reg], equals(1),
              reason: 'Region $reg in ${p.title} must have exactly 1 dog in solution');
        }
      }
    });
  });

  group('Rule Verification Tests & Isolated Conflicts', () {
    test('Same-row conflict without another simultaneous conflict', () {
      // Both dogs are in row 0, but different columns (1 and 7), different regions (1 and 4), and non-touching (col distance 6)
      const p1 = DogPlacement(0, 1);
      const p2 = DogPlacement(0, 7);
      final pair = [p1, p2];

      // Fails row validity for row 0
      expect(PuzzleValidator.isRowValid(pair, 0), isFalse);

      // Passes all other rules in isolation
      expect(PuzzleValidator.isColumnValid(pair, 1), isTrue);
      expect(PuzzleValidator.isColumnValid(pair, 7), isTrue);
      expect(PuzzleValidator.areDogsNotTouching(pair), isTrue);
      expect(PuzzleValidator.isColorRegionValid(puzzle, pair, puzzle.getRegionAt(0, 1)), isTrue);
      expect(PuzzleValidator.isColorRegionValid(puzzle, pair, puzzle.getRegionAt(0, 7)), isTrue);

      // Clashes identify row conflict
      final clashes = PuzzleValidator.findClashingPlacements(puzzle, pair);
      expect(clashes.contains(p1), isTrue);
      expect(clashes.contains(p2), isTrue);

      // Cannot add p2 when p1 is placed
      expect(PuzzleValidator.isPlacementValid(puzzle, [p1], p2), isFalse);
    });

    test('Same-column conflict without another simultaneous conflict', () {
      // Both dogs are in col 4, but different rows (1 and 8), different regions, and non-touching (row distance 7)
      const p1 = DogPlacement(1, 4);
      const p2 = DogPlacement(8, 4);
      final pair = [p1, p2];

      // Fails column validity for col 4
      expect(PuzzleValidator.isColumnValid(pair, 4), isFalse);

      // Passes all other rules in isolation
      expect(PuzzleValidator.isRowValid(pair, 1), isTrue);
      expect(PuzzleValidator.isRowValid(pair, 8), isTrue);
      expect(PuzzleValidator.areDogsNotTouching(pair), isTrue);
      expect(PuzzleValidator.isColorRegionValid(puzzle, pair, puzzle.getRegionAt(1, 4)), isTrue);
      expect(PuzzleValidator.isColorRegionValid(puzzle, pair, puzzle.getRegionAt(8, 4)), isTrue);

      // Clashes identify column conflict
      final clashes = PuzzleValidator.findClashingPlacements(puzzle, pair);
      expect(clashes.contains(p1), isTrue);
      expect(clashes.contains(p2), isTrue);

      // Cannot add p2 when p1 is placed
      expect(PuzzleValidator.isPlacementValid(puzzle, [p1], p2), isFalse);
    });

    test('Same-region conflict without row, column or adjacency conflicts', () {
      // Create a test puzzle where region 0 includes non-touching cells in different rows and columns
      final customRegionMap = List.generate(10, (r) => List.generate(10, (c) => (r + c) % 10));
      // Ensure (0, 0) and (3, 4) share region 5, while not sharing row (0 != 3) or column (0 != 4)
      customRegionMap[0][0] = 5;
      customRegionMap[3][4] = 5;
      final customPuzzle = Puzzle(
        id: 'isolated_region',
        title: 'Isolated Region',
        difficultyLabel: 'Easy',
        regionMap: customRegionMap,
        solution: const [],
      );

      const p1 = DogPlacement(0, 0);
      const p2 = DogPlacement(3, 4);
      final pair = [p1, p2];

      // Fails color region validity for region 5
      expect(PuzzleValidator.isColorRegionValid(customPuzzle, pair, 5), isFalse);

      // Passes all other rules in isolation
      expect(PuzzleValidator.isRowValid(pair, 0), isTrue);
      expect(PuzzleValidator.isRowValid(pair, 3), isTrue);
      expect(PuzzleValidator.isColumnValid(pair, 0), isTrue);
      expect(PuzzleValidator.isColumnValid(pair, 4), isTrue);
      expect(PuzzleValidator.areDogsNotTouching(pair), isTrue);

      // Clashes identify region conflict
      final clashes = PuzzleValidator.findClashingPlacements(customPuzzle, pair);
      expect(clashes.contains(p1), isTrue);
      expect(clashes.contains(p2), isTrue);

      // Cannot add p2 when p1 is placed
      expect(PuzzleValidator.isPlacementValid(customPuzzle, [p1], p2), isFalse);
    });

    test('Horizontal touching: left and right directions', () {
      const center = DogPlacement(4, 4);
      const right = DogPlacement(4, 5);
      const left = DogPlacement(4, 3);

      expect(PuzzleValidator.areDogsNotTouching([center, right]), isFalse);
      expect(PuzzleValidator.areDogsNotTouching([center, left]), isFalse);
      expect(PuzzleValidator.findClashingPlacements(puzzle, [center, right]).length, equals(2));
      expect(PuzzleValidator.findClashingPlacements(puzzle, [center, left]).length, equals(2));
    });

    test('Vertical touching: top and bottom directions', () {
      const center = DogPlacement(4, 4);
      const top = DogPlacement(3, 4);
      const bottom = DogPlacement(5, 4);

      expect(PuzzleValidator.areDogsNotTouching([center, top]), isFalse);
      expect(PuzzleValidator.areDogsNotTouching([center, bottom]), isFalse);
      expect(PuzzleValidator.findClashingPlacements(puzzle, [center, top]).length, equals(2));
      expect(PuzzleValidator.findClashingPlacements(puzzle, [center, bottom]).length, equals(2));
    });

    test('Four diagonal directions touching', () {
      const center = DogPlacement(4, 4);
      const topLeft = DogPlacement(3, 3);
      const topRight = DogPlacement(3, 5);
      const bottomLeft = DogPlacement(5, 3);
      const bottomRight = DogPlacement(5, 5);

      expect(PuzzleValidator.areDogsNotTouching([center, topLeft]), isFalse);
      expect(PuzzleValidator.areDogsNotTouching([center, topRight]), isFalse);
      expect(PuzzleValidator.areDogsNotTouching([center, bottomLeft]), isFalse);
      expect(PuzzleValidator.areDogsNotTouching([center, bottomRight]), isFalse);

      expect(PuzzleValidator.findClashingPlacements(puzzle, [center, topLeft]).length, equals(2));
      expect(PuzzleValidator.findClashingPlacements(puzzle, [center, topRight]).length, equals(2));
      expect(PuzzleValidator.findClashingPlacements(puzzle, [center, bottomLeft]).length, equals(2));
      expect(PuzzleValidator.findClashingPlacements(puzzle, [center, bottomRight]).length, equals(2));
    });

    test('Out-of-bounds coordinate placements handled safely without throwing', () {
      expect(PuzzleValidator.isCoordinateInBounds(-1, 0), isFalse);
      expect(PuzzleValidator.isCoordinateInBounds(0, -1), isFalse);
      expect(PuzzleValidator.isCoordinateInBounds(10, 0), isFalse);
      expect(PuzzleValidator.isCoordinateInBounds(0, 10), isFalse);
      expect(PuzzleValidator.isCoordinateInBounds(5, 5), isTrue);

      // None of the validator methods should throw on out-of-bounds coordinates
      expect(PuzzleValidator.isPlacementValid(puzzle, [], const DogPlacement(-1, 5)), isFalse);
      expect(PuzzleValidator.isPlacementValid(puzzle, [], const DogPlacement(10, 2)), isFalse);
      expect(PuzzleValidator.isPlacementValid(puzzle, [const DogPlacement(20, 20)], const DogPlacement(0, 0)), isFalse);

      expect(PuzzleValidator.isColorRegionValid(puzzle, [const DogPlacement(-1, 0)], 0), isFalse);
      expect(PuzzleValidator.isColorRegionValid(puzzle, [], -1), isFalse);
      expect(PuzzleValidator.isColorRegionValid(puzzle, [], 10), isFalse);

      expect(PuzzleValidator.isRowValid([], -1), isFalse);
      expect(PuzzleValidator.isRowValid([], 10), isFalse);
      expect(PuzzleValidator.isColumnValid([], -1), isFalse);
      expect(PuzzleValidator.isColumnValid([], 10), isFalse);

      final clashes = PuzzleValidator.findClashingPlacements(puzzle, [const DogPlacement(-5, 12)]);
      expect(clashes.length, equals(1));
    });

    test('Duplicate cells are rejected', () {
      const p1 = DogPlacement(2, 3);
      const p2 = DogPlacement(2, 3);

      expect(PuzzleValidator.isPlacementValid(puzzle, [p1], p2), isFalse);
      final clashes = PuzzleValidator.findClashingPlacements(puzzle, [p1, p2]);
      expect(clashes.contains(p1), isTrue);
    });

    test('Invalid and incomplete puzzle completion scenarios', () {
      final validSolution = puzzle.solution;

      // 1. Incomplete: 9 dogs
      expect(PuzzleValidator.isPuzzleCompleted(puzzle, validSolution.take(9).toList()), isFalse);

      // 2. Excess: 11 dogs
      final excess = [...validSolution, const DogPlacement(0, 0)];
      expect(PuzzleValidator.isPuzzleCompleted(puzzle, excess), isFalse);

      // 3. Duplicate cell in 10 dogs
      final duplicate = [validSolution[0], validSolution[0], ...validSolution.skip(2)];
      expect(PuzzleValidator.isPuzzleCompleted(puzzle, duplicate), isFalse);

      // 4. Out of bounds in 10 dogs
      final oob = [const DogPlacement(-1, 0), ...validSolution.skip(1)];
      expect(PuzzleValidator.isPuzzleCompleted(puzzle, oob), isFalse);

      // 5. Touching pair in 10 dogs
      final touching = [const DogPlacement(0, 0), const DogPlacement(1, 1), ...validSolution.skip(2)];
      expect(PuzzleValidator.isPuzzleCompleted(puzzle, touching), isFalse);
    });
  });

  group('Puzzle Solver, Capping & Uniqueness Verification', () {
    test('All predefined puzzles have verified solutions with exactly 10 dogs', () {
      for (final p in PuzzleRepository.puzzles) {
        expect(p.solution.length, equals(10));
        expect(PuzzleValidator.isPuzzleCompleted(p, p.solution), isTrue);
      }
    });

    test('PuzzleSolver confirms each puzzle has a UNIQUE solution', () {
      for (final p in PuzzleRepository.puzzles) {
        final result = PuzzleSolver.countSolutions(p, maxCount: 10);
        expect(result.count, equals(1),
            reason: '${p.title} must have exactly one unique solution');
        expect(result.isCapped, isFalse);
        expect(result.isUnique, isTrue);
        expect(PuzzleSolver.hasUniqueSolution(p), isTrue);
      }
    });

    test('PuzzleSolver respects fixed placements and reports capped status properly', () {
      final p = PuzzleRepository.getPuzzleByIndex(0);
      final fixedDog = p.solution.first;

      // Solving with correct fixed dog yields the unique solution
      final fixedResult = PuzzleSolver.countSolutions(
        p,
        maxCount: 5,
        fixedPlacements: [fixedDog],
      );
      expect(fixedResult.count, equals(1));
      expect(fixedResult.isUnique, isTrue);

      // Solving with an invalid fixed dog yields 0 solutions
      final wrongDog = DogPlacement(fixedDog.row, (fixedDog.col + 1) % 10);
      final invalidResult = PuzzleSolver.countSolutions(
        p,
        maxCount: 5,
        fixedPlacements: [wrongDog],
      );
      expect(invalidResult.count, equals(0));
    });
  });

  group('Zero-Solution, Multiple-Solution & Fixed Placement Enforcement Tests', () {
    test('Zero-Solution: Puzzle with conflicting/impossible region layout yields 0 solutions', () {
      // Create a 10x10 puzzle where row 0 and row 1 both belong entirely to region 0.
      // Since each row must have 1 dog, both row 0 and row 1 must have a dog.
      // But both dogs would be in region 0, violating the 1 dog per region rule.
      final impossiblePuzzle = Puzzle(
        id: 'impossible_layout',
        title: 'Impossible Layout',
        difficultyLabel: 'Easy',
        regionMap: [
          List.filled(10, 0),
          List.filled(10, 0),
          ...List.generate(8, (r) => List.filled(10, r + 2)),
        ],
        solution: const [],
      );

      final result = PuzzleSolver.countSolutions(impossiblePuzzle, maxCount: 10);
      expect(result.count, equals(0));
      expect(result.isUnique, isFalse);
      expect(result.isCapped, isFalse);
      expect(result.status, equals(SolutionStatus.zero));
      expect(result.toString(), contains('No solutions'));
      expect(PuzzleSolver.solve(impossiblePuzzle), isEmpty);
      expect(PuzzleSolver.hasUniqueSolution(impossiblePuzzle), isFalse);
    });

    test('Zero-Solution: Conflicting fixed placements yield 0 solutions immediately', () {
      final p = PuzzleRepository.getPuzzleByIndex(0);

      // 1. Same row conflict
      final sameRow = [const DogPlacement(0, 1), const DogPlacement(0, 5)];
      final rowRes = PuzzleSolver.countSolutions(p, fixedPlacements: sameRow);
      expect(rowRes.count, equals(0));
      expect(rowRes.status, equals(SolutionStatus.zero));

      // 2. Same column conflict
      final sameCol = [const DogPlacement(1, 4), const DogPlacement(6, 4)];
      final colRes = PuzzleSolver.countSolutions(p, fixedPlacements: sameCol);
      expect(colRes.count, equals(0));
      expect(colRes.status, equals(SolutionStatus.zero));

      // 3. Same region conflict (non-touching)
      final sameReg = [const DogPlacement(0, 0), const DogPlacement(2, 0)];
      if (p.getRegionAt(0, 0) == p.getRegionAt(2, 0)) {
        final regRes = PuzzleSolver.countSolutions(p, fixedPlacements: sameReg);
        expect(regRes.count, equals(0));
        expect(regRes.status, equals(SolutionStatus.zero));
      }

      // 4. Touching conflicts (horizontal, vertical, diagonal)
      final touchHoriz = [const DogPlacement(3, 3), const DogPlacement(3, 4)];
      final touchVert = [const DogPlacement(3, 3), const DogPlacement(4, 3)];
      final touchDiag = [const DogPlacement(3, 3), const DogPlacement(4, 4)];
      expect(PuzzleSolver.countSolutions(p, fixedPlacements: touchHoriz).status, equals(SolutionStatus.zero));
      expect(PuzzleSolver.countSolutions(p, fixedPlacements: touchVert).status, equals(SolutionStatus.zero));
      expect(PuzzleSolver.countSolutions(p, fixedPlacements: touchDiag).status, equals(SolutionStatus.zero));

      // 5. Out of bounds coordinates
      final oobNeg = [const DogPlacement(-1, 0)];
      final oobLarge = [const DogPlacement(0, 10)];
      expect(PuzzleSolver.countSolutions(p, fixedPlacements: oobNeg).status, equals(SolutionStatus.zero));
      expect(PuzzleSolver.countSolutions(p, fixedPlacements: oobLarge).status, equals(SolutionStatus.zero));

      // 6. Exceeding 10 fixed placements
      final excessDogs = List.generate(11, (i) => DogPlacement(i, i));
      expect(PuzzleSolver.countSolutions(p, fixedPlacements: excessDogs).status, equals(SolutionStatus.zero));
    });

    test('Zero-Solution: Valid puzzle with incompatible fixed placement yields 0 solutions', () {
      final p = PuzzleRepository.getPuzzleByIndex(0);
      final firstDog = p.solution.first;
      // In a unique puzzle, placing a dog in the same row as firstDog but different col allows 0 solutions
      final wrongDog = DogPlacement(firstDog.row, (firstDog.col + 1) % 10);
      final result = PuzzleSolver.countSolutions(p, fixedPlacements: [wrongDog]);
      expect(result.count, equals(0));
      expect(result.status, equals(SolutionStatus.zero));
      expect(result.isUnique, isFalse);
    });

    test('Multiple-Solution: Striped board admits multiple solutions and reports capping', () {
      // In this puzzle, each row is its own separate region (0..9).
      // Any valid placement of non-touching rooks is a valid solution.
      final multiPuzzle = Puzzle(
        id: 'multi_solution_stripes',
        title: 'Multi Solution Stripes',
        difficultyLabel: 'Easy',
        regionMap: List.generate(10, (r) => List.filled(10, r)),
        solution: const [],
      );

      // When maxCount is small (e.g. 5), solutions hit the cap
      final cappedResult = PuzzleSolver.countSolutions(multiPuzzle, maxCount: 5);
      expect(cappedResult.count, equals(5));
      expect(cappedResult.isCapped, isTrue);
      expect(cappedResult.isUnique, isFalse);
      expect(cappedResult.status, equals(SolutionStatus.capped));
      expect(cappedResult.toString(), contains('Capped at 5'));

      // Check hasUniqueSolution returns false
      expect(PuzzleSolver.hasUniqueSolution(multiPuzzle), isFalse);

      // Verify that solve returns multiple distinct valid solutions
      final solutions = PuzzleSolver.solve(multiPuzzle, maxSolutions: 5);
      expect(solutions.length, equals(5));
      for (final sol in solutions) {
        expect(sol.length, equals(10));
        expect(PuzzleValidator.isPuzzleCompleted(multiPuzzle, sol), isTrue);
      }
    });

    test('Multiple-Solution: SolutionCountResult correctly distinguishes all SolutionStatus cases', () {
      const zeroRes = SolutionCountResult(count: 0, isCapped: false);
      expect(zeroRes.status, equals(SolutionStatus.zero));
      expect(zeroRes.isUnique, isFalse);

      const uniqueRes = SolutionCountResult(count: 1, isCapped: false);
      expect(uniqueRes.status, equals(SolutionStatus.unique));
      expect(uniqueRes.isUnique, isTrue);

      const multiRes = SolutionCountResult(count: 2, isCapped: false);
      expect(multiRes.status, equals(SolutionStatus.multiple));
      expect(multiRes.isUnique, isFalse);
      expect(multiRes.toString(), contains('Multiple solutions'));

      const cappedRes = SolutionCountResult(count: 10, isCapped: true);
      expect(cappedRes.status, equals(SolutionStatus.capped));
      expect(cappedRes.isUnique, isFalse);
      expect(cappedRes.toString(), contains('Capped'));
    });

    test('Exact maximum limit solution counting: does not label exhausted search as capped', () {
      final uniquePuzzle = PuzzleRepository.getPuzzleByIndex(0);

      // Unique puzzle has exactly 1 solution.
      // Searching with maxCount = 1: exhausted search must NOT be labeled as capped!
      final countAtExactLimit = PuzzleSolver.countSolutions(uniquePuzzle, maxCount: 1);
      expect(countAtExactLimit.count, equals(1));
      expect(countAtExactLimit.isCapped, isFalse,
          reason: 'Exhausted search with exactly maxCount solutions must not be capped');
      expect(countAtExactLimit.isUnique, isTrue);
      expect(countAtExactLimit.status, equals(SolutionStatus.unique));

      // Multi-solution puzzle with maxCount = 1 has more solutions remaining, so it MUST be capped
      final multiPuzzle = Puzzle(
        id: 'multi_solution_stripes',
        title: 'Multi Solution Stripes',
        difficultyLabel: 'Easy',
        regionMap: List.generate(10, (r) => List.filled(10, r)),
        solution: const [],
      );

      final cappedAtLimit = PuzzleSolver.countSolutions(multiPuzzle, maxCount: 1);
      expect(cappedAtLimit.count, equals(1));
      expect(cappedAtLimit.isCapped, isTrue,
          reason: 'Search with more solutions remaining beyond maxCount must be capped');
      expect(cappedAtLimit.isUnique, isFalse);
      expect(cappedAtLimit.status, equals(SolutionStatus.capped));
    });

    test('Invalid maxCount and maxSolutions values are handled explicitly', () {
      // countSolutions with maxCount <= 0
      final zeroCountRes = PuzzleSolver.countSolutions(puzzle, maxCount: 0);
      expect(zeroCountRes.count, equals(0));
      expect(zeroCountRes.isCapped, isFalse);
      expect(zeroCountRes.status, equals(SolutionStatus.zero));

      final negCountRes = PuzzleSolver.countSolutions(puzzle, maxCount: -5);
      expect(negCountRes.count, equals(0));
      expect(negCountRes.isCapped, isFalse);
      expect(negCountRes.status, equals(SolutionStatus.zero));

      // solve with maxSolutions <= 0
      expect(PuzzleSolver.solve(puzzle, maxSolutions: 0), isEmpty);
      expect(PuzzleSolver.solve(puzzle, maxSolutions: -10), isEmpty);
    });
  });
}


