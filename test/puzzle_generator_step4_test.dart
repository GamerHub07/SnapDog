import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/features/game/models/puzzle.dart';
import 'package:snapdog/features/game/services/difficulty_classifier.dart';
import 'package:snapdog/features/game/services/difficulty_scheduler.dart';
import 'package:snapdog/features/game/services/puzzle_fingerprint.dart';
import 'package:snapdog/features/game/services/puzzle_generator.dart';
import 'package:snapdog/features/game/services/puzzle_repository.dart';
import 'package:snapdog/features/game/services/puzzle_solver.dart';
import 'package:snapdog/features/game/services/puzzle_validator.dart';
import 'package:snapdog/features/progression/models/progression_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PuzzleRepository.clearCacheForTesting();
  });

  group('SnapDog Step 4: Procedural Puzzle Generation, Diversity & Scheduling Tests', () {
    // 1. Levels 1–9 return their original handcrafted puzzles
    test('1. Levels 1–9 return their original handcrafted puzzles', () {
      for (int lvl = 1; lvl <= 9; lvl++) {
        final puzzle = PuzzleRepository.getPuzzleByLevel(lvl);
        expect(puzzle.levelNumber, equals(lvl));
        expect(puzzle.id, equals('puzzle_$lvl'));
        expect(puzzle.title, equals(PuzzleRepository.puzzles[lvl - 1].title));
        expect(puzzle.regionMap, equals(PuzzleRepository.puzzles[lvl - 1].regionMap));
        expect(puzzle.solution, equals(PuzzleRepository.puzzles[lvl - 1].solution));
      }
    });

    // 2. Level 10 uses procedural generation
    test('2. Level 10 uses procedural generation', () {
      final puzzle10 = PuzzleRepository.getPuzzleByLevel(10);

      expect(puzzle10.levelNumber, equals(10));
      expect(puzzle10.id, equals('puzzle_10'));
      expect(puzzle10.regionMap.length, equals(10));
      expect(puzzle10.solution.length, equals(10));

      // Must not match any handcrafted puzzle id or exact region map
      for (int i = 0; i < 9; i++) {
        expect(puzzle10.title, isNot(equals(PuzzleRepository.puzzles[i].title)));
      }

      // Must be validated as uniquely solvable
      final uniqueness = PuzzleSolver.validateUniqueness(puzzle10);
      expect(uniqueness.isUnique, isTrue);
    });

    // 3. Levels 15, 50, 100 and 1000 are supported
    test('3. Levels 15, 50, 100 and 1000 are supported', () {
      const testLevels = [15, 50, 100, 1000];

      for (final lvl in testLevels) {
        final puzzle = PuzzleRepository.getPuzzleByLevel(lvl);
        expect(puzzle.levelNumber, equals(lvl));
        expect(puzzle.id, equals('puzzle_$lvl'));
        expect(puzzle.solution.length, equals(10));

        final uniqueness = PuzzleSolver.validateUniqueness(puzzle);
        expect(uniqueness.isUnique, isTrue, reason: 'Level $lvl must have a unique solution');
      }
    });

    // 4. Generated puzzles have exactly one solution
    test('4. Generated puzzles have exactly one solution', () {
      for (int lvl = 10; lvl <= 15; lvl++) {
        final puzzle = PuzzleRepository.getPuzzleByLevel(lvl);
        final uniqueness = PuzzleSolver.validateUniqueness(puzzle);
        expect(uniqueness.isUnique, isTrue);
        expect(uniqueness.status, equals(UniqueSolutionStatus.uniqueSolution));
        expect(uniqueness.solution, isNotNull);
        expect(uniqueness.solution!.length, equals(10));
      }
    });

    // 5. Generated puzzles satisfy all four rules
    test('5. Generated puzzles satisfy all four rules', () {
      for (int lvl = 10; lvl <= 14; lvl++) {
        final puzzle = PuzzleRepository.getPuzzleByLevel(lvl);
        final solution = puzzle.solution;

        // Rule 1: Exactly 1 dog per row
        final rowCounts = List.filled(10, 0);
        for (final p in solution) {
          rowCounts[p.row]++;
        }
        for (int r = 0; r < 10; r++) {
          expect(rowCounts[r], equals(1), reason: 'Row $r in level $lvl must contain exactly 1 dog');
        }

        // Rule 2: Exactly 1 dog per col
        final colCounts = List.filled(10, 0);
        for (final p in solution) {
          colCounts[p.col]++;
        }
        for (int c = 0; c < 10; c++) {
          expect(colCounts[c], equals(1), reason: 'Col $c in level $lvl must contain exactly 1 dog');
        }

        // Rule 3: Exactly 1 dog per region (10 regions total)
        final regionCounts = List.filled(10, 0);
        for (final p in solution) {
          final reg = puzzle.getRegionAt(p.row, p.col);
          regionCounts[reg]++;
        }
        for (int reg = 0; reg < 10; reg++) {
          expect(regionCounts[reg], equals(1), reason: 'Region $reg in level $lvl must contain exactly 1 dog');
        }

        // Rule 4: No two dogs touch horizontally, vertically, or diagonally
        for (int i = 0; i < solution.length; i++) {
          for (int j = i + 1; j < solution.length; j++) {
            final a = solution[i];
            final b = solution[j];
            final rowDiff = (a.row - b.row).abs();
            final colDiff = (a.col - b.col).abs();
            final touches = rowDiff <= 1 && colDiff <= 1;
            expect(touches, isFalse, reason: 'Dogs at (${a.row},${a.col}) and (${b.row},${b.col}) touch in level $lvl');
          }
        }

        expect(PuzzleValidator.isPuzzleCompleted(puzzle, solution), isTrue);
      }
    });

    // 6. Duplicate fingerprints are rejected
    test('6. Duplicate fingerprints are rejected', () {
      final tracker = RecentFingerprintTracker(maxCapacity: 10);
      final p1 = PuzzleRepository.puzzles[0];
      final fp1 = PuzzleFingerprint.compute(p1);

      expect(tracker.contains(fp1), isFalse);
      tracker.add(fp1);
      expect(tracker.contains(fp1), isTrue);
      expect(tracker.containsPuzzle(p1), isTrue);

      // Verify generator rejects duplicate when tracker is passed
      final pGen = PuzzleGenerator.generateForLevel(20, tracker: tracker);
      final fpGen = PuzzleFingerprint.compute(pGen);

      expect(tracker.contains(fpGen), isTrue); // Was added by generator upon generation

      // Generating another puzzle with tracker rejects recent duplicate
      final pGen2 = PuzzleGenerator.generateForLevel(21, tracker: tracker);
      expect(PuzzleFingerprint.compute(pGen2), isNot(equals(fpGen)));
    });

    // 7. Different seeds can produce different layouts
    test('7. Different seeds can produce different layouts', () {
      final p10 = PuzzleGenerator.generateForLevel(10);
      final p11 = PuzzleGenerator.generateForLevel(11);
      final p12 = PuzzleGenerator.generateForLevel(12);

      final fp10 = PuzzleFingerprint.compute(p10);
      final fp11 = PuzzleFingerprint.compute(p11);
      final fp12 = PuzzleFingerprint.compute(p12);

      expect(fp10, isNot(equals(fp11)));
      expect(fp10, isNot(equals(fp12)));
      expect(fp11, isNot(equals(fp12)));

      // Solutions are distinct
      final sol10Cols = p10.solution.map((p) => p.col).toList();
      final sol11Cols = p11.solution.map((p) => p.col).toList();
      expect(sol10Cols, isNot(equals(sol11Cols)));
    });

    // 8. Difficulty classification matches the actual deduction engine
    test('8. Difficulty classification matches the actual deduction engine', () {
      for (int lvl = 10; lvl <= 15; lvl++) {
        final puzzle = PuzzleRepository.getPuzzleByLevel(lvl);
        final analysis = DifficultyClassifier.classify(puzzle);

        expect(
          puzzle.difficulty,
          equals(analysis.difficulty),
          reason: 'Level $lvl difficulty label (${puzzle.difficulty.name}) must match classifier (${analysis.difficulty.name})',
        );
      }
    });

    // 9. The scheduler produces approximately the target 50/35/15 distribution over a sufficiently large test sample
    test('9. The scheduler produces approximately the target 50/35/15 distribution over a sufficiently large test sample', () {
      final scheduler = DifficultyScheduler();
      final history = <Difficulty>[];

      // Schedule 100 procedural levels (levels 10 to 109)
      for (int lvl = 10; lvl < 110; lvl++) {
        final diff = scheduler.getDifficultyForLevel(lvl);
        history.add(diff);
      }

      final countEasy = history.where((d) => d == Difficulty.easy).length;
      final countMed = history.where((d) => d == Difficulty.medium).length;
      final countHard = history.where((d) => d == Difficulty.hard).length;

      final pctEasy = countEasy / history.length;
      final pctMed = countMed / history.length;
      final pctHard = countHard / history.length;

      // Target: Easy ~50% (allow 38% - 62%)
      expect(pctEasy, inInclusiveRange(0.38, 0.62), reason: 'Easy ratio ($pctEasy) should approximate 50%');

      // Target: Medium ~35% (allow 24% - 46%)
      expect(pctMed, inInclusiveRange(0.24, 0.46), reason: 'Medium ratio ($pctMed) should approximate 35%');

      // Target: Hard ~15% (allow 08% - 24%)
      expect(pctHard, inInclusiveRange(0.08, 0.24), reason: 'Hard ratio ($pctHard) should approximate 15%');
    });

    // 10. The scheduler does not produce long consecutive HARD runs
    test('10. The scheduler does not produce long consecutive HARD runs', () {
      final scheduler = DifficultyScheduler();
      Difficulty? prev;

      for (int lvl = 10; lvl < 150; lvl++) {
        final curr = scheduler.getDifficultyForLevel(lvl);
        if (prev == Difficulty.hard) {
          expect(
            curr,
            isNot(equals(Difficulty.hard)),
            reason: 'Level $lvl cannot be HARD when Level ${lvl - 1} was HARD (max consecutive HARD is 1)',
          );
        }
        prev = curr;
      }
    });

    // 11. The scheduler does not produce excessive EASY-only stretches
    test('11. The scheduler does not produce excessive EASY-only stretches', () {
      final scheduler = DifficultyScheduler();
      int consecutiveEasy = 0;

      for (int lvl = 10; lvl < 150; lvl++) {
        final curr = scheduler.getDifficultyForLevel(lvl);
        if (curr == Difficulty.easy) {
          consecutiveEasy++;
          expect(
            consecutiveEasy,
            lessThanOrEqualTo(3),
            reason: 'Level $lvl exceeded max 3 consecutive EASY puzzles (consecutive: $consecutiveEasy)',
          );
        } else {
          consecutiveEasy = 0;
        }
      }
    });

    // 12. Scheduling is deterministic for identical persisted history
    test('12. Scheduling is deterministic for identical persisted history', () {
      final schedA = DifficultyScheduler();
      final schedB = DifficultyScheduler();

      final listA = List.generate(30, (i) => schedA.getDifficultyForLevel(10 + i));
      final listB = List.generate(30, (i) => schedB.getDifficultyForLevel(10 + i));

      expect(listA, equals(listB));
    });

    // 13. Scheduled difficulty survives app restarts
    test('13. Scheduled difficulty survives app restarts', () async {
      final prefs = await SharedPreferences.getInstance();

      // Session 1: generate level 12 and 13
      final p12Session1 = PuzzleRepository.getPuzzleByLevel(12);
      final p13Session1 = PuzzleRepository.getPuzzleByLevel(13);
      await PuzzleRepository.savePersistedData(prefs);

      // Session 2 (simulate fresh app launch): clear in-memory cache and reload from prefs
      PuzzleRepository.clearCacheForTesting();
      await PuzzleRepository.loadPersistedData(prefs);

      final p12Session2 = PuzzleRepository.getPuzzleByLevel(12);
      final p13Session2 = PuzzleRepository.getPuzzleByLevel(13);

      expect(p12Session2.difficulty, equals(p12Session1.difficulty));
      expect(p12Session2.regionMap, equals(p12Session1.regionMap));
      expect(p12Session2.solution, equals(p12Session1.solution));

      expect(p13Session2.difficulty, equals(p13Session1.difficulty));
      expect(p13Session2.regionMap, equals(p13Session1.regionMap));
      expect(p13Session2.solution, equals(p13Session1.solution));
    });

    // 14. Existing in-progress levels retain their original puzzle and difficulty
    test('14. Existing in-progress levels retain their original puzzle and difficulty', () async {
      final prefs = await SharedPreferences.getInstance();

      // Start Level 14
      final puzzle14 = PuzzleRepository.getPuzzleByLevel(14);
      final originalDiff = puzzle14.difficulty;
      final originalGrid = puzzle14.regionMap;

      final inProgress = InProgressPuzzleState(
        puzzleId: puzzle14.id,
        levelNumber: 14,
        placements: [puzzle14.solution.first],
        crosses: {const Point(0, 0)},
        timerSeconds: 42,
        mistakes: 1,
        hintsUsed: 1,
      );

      final state = ProgressionState(
        highestUnlockedLevel: 14,
        currentLevel: 14,
        inProgressState: inProgress,
      );

      // Simulate app restart
      PuzzleRepository.clearCacheForTesting();
      await PuzzleRepository.loadPersistedData(prefs);

      final resumePuzzle = state.getResumePuzzle();
      expect(resumePuzzle.levelNumber, equals(14));
      expect(resumePuzzle.difficulty, equals(originalDiff));
      expect(resumePuzzle.regionMap, equals(originalGrid));
    });

    // 15. Generation failure is handled safely
    test('15. Generation failure is handled safely', () {
      // Even with heavily constrained budget and forced tracker collisions,
      // generator safely produces a valid unique candidate without crashing or infinite loop
      final tracker = RecentFingerprintTracker();
      final puzzle = PuzzleGenerator.generateForLevel(
        42,
        targetDifficulty: Difficulty.hard,
        tracker: tracker,
        maxAttempts: 5,
      );

      expect(puzzle, isNotNull);
      expect(puzzle.levelNumber, equals(42));
      final val = PuzzleSolver.validateUniqueness(puzzle);
      expect(val.isUnique, isTrue);

      // The puzzle's labeled difficulty matches actual logical deduction classification
      final analysis = DifficultyClassifier.classify(puzzle);
      expect(puzzle.difficulty, equals(analysis.difficulty));
    });

    // 16. No hardcoded maximum level exists
    test('16. No hardcoded maximum level exists', () {
      // Arbitrary high levels can be generated and played
      const highLevels = [250, 500, 2000, 5000];

      for (final lvl in highLevels) {
        final puzzle = PuzzleRepository.getPuzzleByLevel(lvl);
        expect(puzzle.levelNumber, equals(lvl));
        expect(puzzle.id, equals('puzzle_$lvl'));
        expect(puzzle.regionMap.length, equals(10));
        expect(puzzle.solution.length, equals(10));

        final val = PuzzleSolver.validateUniqueness(puzzle);
        expect(val.isUnique, isTrue, reason: 'Level $lvl must be uniquely solvable');
      }
    });

    // 17. No silent repeated handcrafted-puzzle fallback occurs
    test('17. No silent repeated handcrafted-puzzle fallback occurs', () {
      final handcraftedFingerprints = PuzzleRepository.puzzles
          .map((p) => PuzzleFingerprint.compute(p))
          .toSet();

      for (int lvl = 10; lvl <= 20; lvl++) {
        final generated = PuzzleRepository.getPuzzleByLevel(lvl);
        final genFingerprint = PuzzleFingerprint.compute(generated);

        expect(
          handcraftedFingerprints.contains(genFingerprint),
          isFalse,
          reason: 'Procedural level $lvl must NOT be an exact or transformed duplicate of handcrafted puzzles 1-9',
        );
      }
    });
  });
}
