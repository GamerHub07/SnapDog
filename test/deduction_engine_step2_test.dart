import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapdog/features/game/models/dog_placement.dart';
import 'package:snapdog/features/game/models/puzzle.dart';
import 'package:snapdog/features/game/models/deduction_step.dart';
import 'package:snapdog/features/game/services/deduction_engine.dart';
import 'package:snapdog/features/game/services/difficulty_classifier.dart';
import 'package:snapdog/features/game/services/puzzle_repository.dart';
import 'package:snapdog/features/game/services/puzzle_solver.dart';
import 'package:snapdog/features/game/services/puzzle_validator.dart';

void main() {
  group('SnapDog Step 2: Logical Deduction Engine & Difficulty Classifier Tests', () {
    // 1. A straightforward easy puzzle
    test('1. A straightforward easy puzzle', () {
      final puzzle = PuzzleRepository.puzzles[2]; // Cozy Kennel (Level 3)
      final analysis = DifficultyClassifier.classify(puzzle);

      expect(analysis.difficulty, equals(Difficulty.easy));
      expect(analysis.isLogicallySolvable, isTrue);
      expect(analysis.requiresLookAhead, isFalse);
      expect(analysis.stalled, isFalse);
      expect(analysis.deductionResult.placements.length, equals(10));

      // Easy puzzles use only basic singles
      expect(
        analysis.techniquesUsed.contains(DeductionTechnique.pointingRegionToLine),
        isFalse,
      );
      expect(
        analysis.techniquesUsed.contains(DeductionTechnique.lookAheadContradiction),
        isFalse,
      );
      expect(analysis.reasoning, contains('Easy'));
    });

    // 2. A medium puzzle requiring interacting constraints
    test('2. A medium puzzle requiring interacting constraints', () {
      final puzzle = PuzzleRepository.puzzles[0]; // Puppy Park (Level 1)
      final analysis = DifficultyClassifier.classify(puzzle);

      expect(analysis.difficulty, equals(Difficulty.medium));
      expect(analysis.isLogicallySolvable, isTrue);
      expect(analysis.requiresLookAhead, isFalse);
      expect(analysis.stalled, isFalse);
      expect(analysis.deductionResult.placements.length, equals(10));

      // Medium puzzles require line-region pointing constraints
      expect(
        analysis.techniquesUsed.contains(DeductionTechnique.pointingRegionToLine),
        isTrue,
        reason: 'Puppy Park must use Pointing Region to Line interaction',
      );
      expect(analysis.reasoning, contains('Medium'));
    });

    // 3. A hard puzzle requiring advanced reasoning or look-ahead
    test('3. A hard puzzle requiring advanced reasoning or look-ahead', () {
      // Fixture with mutually constraining region layout where lookahead contradiction is required
      final hardRegionMap = [
        [0, 1, 1, 1, 1, 2, 2, 2, 3, 3],
        [4, 0, 1, 1, 1, 2, 2, 2, 3, 3],
        [4, 4, 1, 1, 1, 2, 2, 2, 3, 3],
        [4, 4, 4, 5, 5, 5, 6, 6, 6, 6],
        [4, 4, 4, 5, 5, 5, 6, 6, 6, 6],
        [7, 7, 7, 5, 5, 5, 6, 6, 6, 6],
        [7, 7, 7, 7, 8, 8, 8, 8, 9, 9],
        [7, 7, 7, 7, 8, 8, 8, 8, 9, 9],
        [7, 7, 7, 7, 8, 8, 8, 8, 9, 9],
        [7, 7, 7, 7, 8, 8, 8, 8, 9, 9],
      ];

      final hardPuzzle = Puzzle(
        id: 'hard_lookahead_puzzle',
        title: 'Hard Lookahead Fixture',
        regionMap: hardRegionMap,
        solution: const [],
      );

      final analysis = DifficultyClassifier.classify(hardPuzzle);
      expect(analysis.difficulty, equals(Difficulty.hard));
      expect(analysis.reasoning, contains('Hard'));

      // Deduction with look-ahead triggers contradiction elimination steps
      final deductionResult = analysis.deductionResult;
      expect(
        deductionResult.techniquesUsed.contains(DeductionTechnique.lookAheadContradiction),
        isTrue,
      );
      expect(analysis.requiresLookAhead, isTrue);
    });

    // 4. A puzzle solved entirely through forced deductions
    test('4. A puzzle solved entirely through forced deductions', () {
      final puzzle = PuzzleRepository.puzzles[3]; // Daisy Meadow (Level 4)
      final result = DeductionEngine.analyze(puzzle, allowLookAhead: false);

      expect(result.isSolved, isTrue);
      expect(result.stalled, isFalse);
      expect(result.placements.length, equals(10));
      expect(result.remainingPlacementsNeeded, equals(0));

      // Every placement must be forced
      for (final step in result.steps) {
        if (step.forcedPlacement != null) {
          expect(step.remainingCandidates.length, equals(1));
          expect(step.remainingCandidates.first,
              equals(Point(step.forcedPlacement!.row, step.forcedPlacement!.col)));
        }
      }

      // Validated against the puzzle rules
      expect(PuzzleValidator.isPuzzleCompleted(puzzle, result.placements), isTrue);
    });

    // 5. A puzzle where basic deduction reaches a dead end
    test('5. A puzzle where basic deduction reaches a dead end', () {
      // In Puppy Park (Puzzle 1), if we run only singles and disable pointing and lookahead,
      // it reaches a dead end before placing all 10 dogs.
      final puzzle = PuzzleRepository.puzzles[0];

      // Simulated engine that only uses Pass 1-3 (singles)
      final candidates = List.generate(10, (_) => List.filled(10, true));
      final placedRows = <int>{};
      final placedCols = <int>{};
      final placedRegions = <int>{};
      final placements = <DogPlacement>[];

      bool progress = true;
      while (progress && placements.length < 10) {
        progress = false;

        // Check rows
        for (int r = 0; r < 10; r++) {
          if (placedRows.contains(r)) continue;
          final avail = <int>[];
          for (int c = 0; c < 10; c++) {
            if (candidates[r][c]) avail.add(c);
          }
          if (avail.length == 1) {
            final c = avail.first;
            placements.add(DogPlacement(r, c));
            placedRows.add(r);
            placedCols.add(c);
            final reg = puzzle.getRegionAt(r, c);
            placedRegions.add(reg);
            for (int i = 0; i < 10; i++) {
              candidates[r][i] = false;
              candidates[i][c] = false;
            }
            for (int row = 0; row < 10; row++) {
              for (int col = 0; col < 10; col++) {
                if (puzzle.getRegionAt(row, col) == reg) candidates[row][col] = false;
                if ((row - r).abs() <= 1 && (col - c).abs() <= 1) candidates[row][col] = false;
              }
            }
            progress = true;
            break;
          }
        }
        if (progress) continue;

        // Check regions
        for (int reg = 0; reg < 10; reg++) {
          if (placedRegions.contains(reg)) continue;
          final avail = <Point<int>>[];
          for (int r = 0; r < 10; r++) {
            for (int c = 0; c < 10; c++) {
              if (puzzle.getRegionAt(r, c) == reg && candidates[r][c]) {
                avail.add(Point(r, c));
              }
            }
          }
          if (avail.length == 1) {
            final pt = avail.first;
            placements.add(DogPlacement(pt.x, pt.y));
            placedRows.add(pt.x);
            placedCols.add(pt.y);
            placedRegions.add(reg);
            for (int i = 0; i < 10; i++) {
              candidates[pt.x][i] = false;
              candidates[i][pt.y] = false;
            }
            for (int row = 0; row < 10; row++) {
              for (int col = 0; col < 10; col++) {
                if (puzzle.getRegionAt(row, col) == reg) candidates[row][col] = false;
                if ((row - pt.x).abs() <= 1 && (col - pt.y).abs() <= 1) candidates[row][col] = false;
              }
            }
            progress = true;
            break;
          }
        }
      }

      // Basic deduction stalled at 7/10 placements
      expect(placements.length, lessThan(10));
      expect(placements.length, equals(7));
      expect(progress, isFalse, reason: 'Basic deduction must reach a dead end without guessing');
    });

    // 6. Correct deduction trace generation
    test('6. Correct deduction trace generation', () {
      final puzzle = PuzzleRepository.puzzles[0];
      final result = DeductionEngine.analyze(puzzle);

      expect(result.steps.isNotEmpty, isTrue);

      for (int i = 0; i < result.steps.length; i++) {
        final step = result.steps[i];
        expect(step.stepNumber, equals(i + 1));
        expect(step.explanation, isNotEmpty);
        expect(step.technique, isNotNull);
        expect(step.unitType, isNotNull);

        // Verification of candidates sets
        if (step.forcedPlacement != null) {
          expect(step.remainingCandidates.length, equals(1));
          expect(step.remainingCandidates.first,
              equals(Point(step.forcedPlacement!.row, step.forcedPlacement!.col)));
        }

        // Explanation must be contextual
        expect(
          step.explanation.contains('Row') ||
              step.explanation.contains('Column') ||
              step.explanation.contains('Region') ||
              step.explanation.contains('Dog placed') ||
              step.explanation.contains('Controlled look-ahead'),
          isTrue,
        );
      }
    });

    // 7. No incorrect candidate elimination
    test('7. No incorrect candidate elimination', () {
      for (final puzzle in PuzzleRepository.puzzles) {
        final oracleSolution = puzzle.solution;

        // Run analysis with oracle assertion enabled
        final result = DeductionEngine.analyze(
          puzzle,
          oracleSolution: oracleSolution,
        );

        // Verify that NO eliminated candidate in any step was a valid solution position!
        for (final step in result.steps) {
          for (final eliminated in step.eliminatedCandidates) {
            final placement = DogPlacement(eliminated.x, eliminated.y);
            expect(
              oracleSolution.contains(placement),
              isFalse,
              reason:
                  'Step ${step.stepNumber} [${step.technique.name}] eliminated true solution cell at (${eliminated.x}, ${eliminated.y})!',
            );
          }
        }
      }
    });

    // 8. Deterministic difficulty classification
    test('8. Deterministic difficulty classification', () {
      for (final puzzle in PuzzleRepository.puzzles) {
        final firstRun = DifficultyClassifier.classify(puzzle);
        final secondRun = DifficultyClassifier.classify(puzzle);
        final thirdRun = DifficultyClassifier.classify(puzzle);

        expect(firstRun.difficulty, equals(secondRun.difficulty));
        expect(firstRun.difficulty, equals(thirdRun.difficulty));
        expect(firstRun.difficultyScore, equals(secondRun.difficultyScore));
        expect(firstRun.totalDeductionSteps, equals(secondRun.totalDeductionSteps));
        expect(firstRun.techniquesUsed, equals(secondRun.techniquesUsed));
        expect(firstRun.reasoning, equals(secondRun.reasoning));
      }
    });

    // 9. Consistency with the unique-solution solver
    test('9. Consistency with the unique-solution solver', () {
      for (final puzzle in PuzzleRepository.puzzles) {
        // Step 1 solver oracle
        final uniqueResult = PuzzleSolver.validateUniqueness(puzzle);
        expect(uniqueResult.isUnique, isTrue);
        final expectedSolution = uniqueResult.solution!;

        // Step 2 logical deduction engine
        final deductionResult = DeductionEngine.analyze(puzzle);
        expect(deductionResult.isSolved, isTrue);

        // Resulting placements must match the solver's unique solution exactly
        final deductionPlacementsSet = deductionResult.placements.toSet();
        final expectedSolutionSet = expectedSolution.toSet();
        expect(deductionPlacementsSet, equals(expectedSolutionSet),
            reason: '${puzzle.title} deduction placements must match solver solution');

        // Check full validation
        expect(PuzzleValidator.isPuzzleCompleted(puzzle, deductionResult.placements), isTrue);
      }
    });

    // 10. Malformed puzzle handling
    test('10. Malformed puzzle handling', () {
      // 1. Missing rows
      final shortRowsPuzzle = Puzzle(
        id: 'short_rows',
        title: 'Short Rows',
        regionMap: List.generate(8, (_) => List.filled(10, 0)),
        solution: const [],
      );
      final res1 = DeductionEngine.analyze(shortRowsPuzzle);
      expect(res1.isSolved, isFalse);
      expect(res1.stalled, isTrue);
      expect(res1.steps.first.explanation, contains('Malformed'));

      // 2. Short columns
      final shortColsPuzzle = Puzzle(
        id: 'short_cols',
        title: 'Short Cols',
        regionMap: List.generate(10, (_) => List.filled(7, 0)),
        solution: const [],
      );
      final res2 = DeductionEngine.analyze(shortColsPuzzle);
      expect(res2.isSolved, isFalse);
      expect(res2.stalled, isTrue);
      expect(res2.steps.first.explanation, contains('Malformed'));

      // 3. Invalid region IDs
      final invalidRegPuzzle = Puzzle(
        id: 'invalid_reg',
        title: 'Invalid Region ID',
        regionMap: List.generate(10, (_) => List.filled(10, 15)),
        solution: const [],
      );
      final res3 = DeductionEngine.analyze(invalidRegPuzzle);
      expect(res3.isSolved, isFalse);
      expect(res3.stalled, isTrue);
      expect(res3.steps.first.explanation, contains('Malformed'));

      // 4. Missing regions (e.g. only 9 distinct regions)
      final missingRegPuzzle = Puzzle(
        id: 'missing_reg',
        title: 'Missing Region',
        regionMap: List.generate(10, (r) => List.filled(10, r % 9)),
        solution: const [],
      );
      final res4 = DeductionEngine.analyze(missingRegPuzzle);
      expect(res4.isSolved, isFalse);
      expect(res4.stalled, isTrue);
      expect(res4.steps.first.explanation, contains('distinct regions'));
    });
  });
}
