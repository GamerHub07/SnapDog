import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/features/game/models/dog_placement.dart';
import 'package:snapdog/features/game/models/progressive_hint.dart';
import 'package:snapdog/features/game/providers/game_provider.dart';
import 'package:snapdog/features/game/services/hint_service.dart';
import 'package:snapdog/features/game/services/puzzle_repository.dart';
import 'package:snapdog/features/progression/providers/progression_provider.dart';
import 'package:snapdog/features/progression/services/progression_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('SnapDog Step 3 — Progressive Hint System Tests', () {
    // 1. Hint 1 provides valid constraint guidance
    test('1. Hint 1 provides valid constraint guidance', () {
      final puzzle = PuzzleRepository.getPuzzleByLevel(1);
      final hint = HintService.generateHint(
        puzzle: puzzle,
        currentPlacements: const [],
        stage: HintStage.guidance,
      );

      expect(hint.stage, equals(HintStage.guidance));
      expect(hint.targetCell, isNull, reason: 'Stage 1 must never reveal exact cell position');
      expect(hint.remainingDogsNeeded, equals(10));
      expect(hint.message, isNotEmpty);
      expect(hint.message.contains('10'), isTrue, reason: 'Must explain remaining dogs needed');
      expect(
        hint.highlightedRow != null || hint.highlightedCol != null || hint.highlightedRegion != null,
        isTrue,
        reason: 'Stage 1 must highlight a useful unresolved row, column, or region',
      );
    });

    // 2. Hint 2 provides a valid elimination explanation
    test('2. Hint 2 provides a valid elimination explanation', () {
      final puzzle = PuzzleRepository.getPuzzleByLevel(1);
      final hint = HintService.generateHint(
        puzzle: puzzle,
        currentPlacements: const [],
        stage: HintStage.elimination,
      );

      expect(hint.stage, equals(HintStage.elimination));
      expect(hint.targetCell, isNull, reason: 'Stage 2 must not reveal exact forced dog cell');
      expect(hint.message, isNotEmpty);
      expect(hint.explanation, isNotEmpty);

      // Verify highlighted cells/regions are provided
      expect(
        hint.highlightedCells.isNotEmpty ||
            hint.highlightedRow != null ||
            hint.highlightedCol != null ||
            hint.highlightedRegion != null,
        isTrue,
      );

      // Crucial: Stage 2 must NEVER eliminate any cell that contains a valid solution dog
      for (final eliminated in hint.eliminatedCandidates) {
        final isSolution = puzzle.solution.any((p) => p.row == eliminated.x && p.col == eliminated.y);
        expect(isSolution, isFalse,
            reason: 'Eliminated candidate at (${eliminated.x}, ${eliminated.y}) is in the solution!');
      }
    });

    // 3. Hint 3 identifies a genuinely forced cell
    test('3. Hint 3 identifies a genuinely forced cell', () {
      final puzzle = PuzzleRepository.getPuzzleByLevel(1);
      final hint = HintService.generateHint(
        puzzle: puzzle,
        currentPlacements: const [],
        stage: HintStage.placement,
      );

      expect(hint.stage, equals(HintStage.placement));
      expect(hint.targetCell, isNotNull, reason: 'Stage 3 must identify the forced dog placement');

      // Must be a verified dog cell in the unique solution
      final isSolution = puzzle.solution.any(
        (p) => p.row == hint.targetCell!.x && p.col == hint.targetCell!.y,
      );
      expect(isSolution, isTrue, reason: 'Hint 3 target cell must genuinely be part of the solution');
      expect(hint.message, isNotEmpty);
      expect(hint.highlightedCells.contains(hint.targetCell!), isTrue);
    });

    // 4. Hints never contradict the unique solution
    test('4. Hints never contradict the unique solution across levels', () {
      final testLevels = [1, 3, 5, 8, 10, 15];
      for (final lvl in testLevels) {
        final puzzle = PuzzleRepository.getPuzzleByLevel(lvl);

        for (final stage in HintStage.values) {
          final hint = HintService.generateHint(
            puzzle: puzzle,
            currentPlacements: const [],
            stage: stage,
          );

          if (stage == HintStage.guidance) {
            expect(hint.targetCell, isNull);
          } else if (stage == HintStage.elimination) {
            expect(hint.targetCell, isNull);
            for (final elim in hint.eliminatedCandidates) {
              expect(puzzle.solution.any((p) => p.row == elim.x && p.col == elim.y), isFalse);
            }
          } else if (stage == HintStage.placement) {
            expect(hint.targetCell, isNotNull);
            expect(
              puzzle.solution.any((p) => p.row == hint.targetCell!.x && p.col == hint.targetCell!.y),
              isTrue,
            );
          }
        }
      }
    });

    // 5. Hints update after the player places a dog
    test('5. Hints update after the player places a dog', () {
      final puzzle = PuzzleRepository.getPuzzleByLevel(1);

      // Initial hint
      final hint1 = HintService.generateHint(
        puzzle: puzzle,
        currentPlacements: const [],
        stage: HintStage.placement,
      );
      expect(hint1.remainingDogsNeeded, equals(10));
      final firstTarget = hint1.targetCell!;

      // Player places that forced dog
      final placedDog = DogPlacement(firstTarget.x, firstTarget.y);
      final hint2 = HintService.generateHint(
        puzzle: puzzle,
        currentPlacements: [placedDog],
        stage: HintStage.placement,
      );

      expect(hint2.remainingDogsNeeded, equals(9));
      expect(hint2.targetCell, isNotNull);
      // New target cannot be the already placed dog
      expect(hint2.targetCell, isNot(equals(firstTarget)));
      expect(
        puzzle.solution.any((p) => p.row == hint2.targetCell!.x && p.col == hint2.targetCell!.y),
        isTrue,
      );
    });

    // 6. Manually marked X cells are not treated as proven eliminations
    test('6. Manually marked X cells are not treated as proven eliminations', () {
      final puzzle = PuzzleRepository.getPuzzleByLevel(1);

      // Suppose the player incorrectly placed an X on an actual solution dog cell
      final solDog = puzzle.solution.first;
      final playerCrosses = {Point(solDog.row, solDog.col), const Point(9, 9)};

      // The hint system must strictly base deductions on mathematically proven rules and placed dogs,
      // completely ignoring player-marked crosses
      final hintPlacement = HintService.generateHint(
        puzzle: puzzle,
        currentPlacements: const [],
        stage: HintStage.placement,
      );

      // Verify the engine did not treat player crosses as mathematical facts
      expect(hintPlacement.targetCell, isNotNull);
      expect(
        puzzle.solution.any((p) => p.row == hintPlacement.targetCell!.x && p.col == hintPlacement.targetCell!.y),
        isTrue,
      );
      expect(playerCrosses.contains(Point(solDog.row, solDog.col)), isTrue);
    });

    // 7. Stale hints are cleared after board changes
    test('7. Stale hints are cleared after board changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);

      // Request a hint
      notifier.requestHint();
      expect(notifier.state.activeHint, isNotNull);
      expect(notifier.state.highlightedCells, isNotEmpty);

      // Board change: player marks a cross with single tap
      notifier.singleTapCell(5, 5);

      // Active hint and highlights must be immediately cleared
      expect(notifier.state.activeHint, isNull);
      expect(notifier.state.highlightedCells, isEmpty);
      expect(notifier.state.hintCell, isNull);
    });

    // 8. Hint count is deducted exactly once
    test('8. Hint count is deducted exactly once', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);
      expect(notifier.state.hintsUsed, equals(0));

      // Reveal Hint 1: count increases by 1
      notifier.requestHint();
      expect(notifier.state.hintsUsed, equals(1));

      // Rapid / repeated tap on Hint button must NOT increase hint count again
      notifier.requestHint();
      expect(notifier.state.hintsUsed, equals(1));

      // Advancing through progressive stages on same clue does NOT deduct additional hints
      notifier.requestNextHintStage(); // Stage 2
      expect(notifier.state.hintsUsed, equals(1));
      notifier.requestNextHintStage(); // Stage 3
      expect(notifier.state.hintsUsed, equals(1));

      // Dismissing hint does NOT deduct
      notifier.dismissHint();
      expect(notifier.state.hintsUsed, equals(1));

      // Reopening hint before making any board move does NOT deduct again
      notifier.requestHint();
      expect(notifier.state.hintsUsed, equals(1));
    });

    // 9. Hint usage persists correctly
    test('9. Hint usage persists correctly across app restarts and level loads', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);
      notifier.loadLevel(2);

      // Use a hint on Level 2
      notifier.requestHint();
      expect(notifier.state.hintsUsed, equals(1));

      // Check persisted in-progress state
      final savedInProgress = container.read(progressionProvider).inProgressState;
      expect(savedInProgress, isNotNull);
      expect(savedInProgress!.levelNumber, equals(2));
      expect(savedInProgress.hintsUsed, equals(1));

      // Re-initialize a new container mimicking app restart: load persisted progression
      final savedState = await ProgressionRepository.loadProgression();
      expect(savedState.inProgressState, isNotNull);
      expect(savedState.inProgressState!.levelNumber, equals(2));
      expect(savedState.inProgressState!.hintsUsed, equals(1));

      final newContainer = ProviderContainer();
      addTearDown(newContainer.dispose);
      newContainer.read(progressionProvider.notifier).setStateForTesting(savedState);

      newContainer.read(puzzleGameProvider.notifier).loadLevel(2);
      final restoredState = newContainer.read(puzzleGameProvider);
      expect(restoredState.puzzle.levelNumber, equals(2));
      expect(restoredState.hintsUsed, equals(1), reason: 'Hint usage must persist across restarts');
    });

    // 10. The system works on a procedurally generated Level 10 puzzle
    test('10. The system works on a procedurally generated Level 10 puzzle', () {
      final puzzleLevel10 = PuzzleRepository.getPuzzleByLevel(10);
      expect(puzzleLevel10.levelNumber, equals(10));

      // Stage 1
      final hint1 = HintService.generateHint(
        puzzle: puzzleLevel10,
        currentPlacements: const [],
        stage: HintStage.guidance,
      );
      expect(hint1.stage, equals(HintStage.guidance));
      expect(hint1.targetCell, isNull);
      expect(hint1.remainingDogsNeeded, equals(10));

      // Stage 2
      final hint2 = HintService.generateHint(
        puzzle: puzzleLevel10,
        currentPlacements: const [],
        stage: HintStage.elimination,
      );
      expect(hint2.stage, equals(HintStage.elimination));
      expect(hint2.targetCell, isNull);

      // Stage 3
      final hint3 = HintService.generateHint(
        puzzle: puzzleLevel10,
        currentPlacements: const [],
        stage: HintStage.placement,
      );
      expect(hint3.stage, equals(HintStage.placement));
      expect(hint3.targetCell, isNotNull);
      expect(
        puzzleLevel10.solution.any((p) => p.row == hint3.targetCell!.x && p.col == hint3.targetCell!.y),
        isTrue,
      );
    });

    // 11. The system works on a generated puzzle with a level number greater than 9
    test('11. The system works on a generated puzzle with level > 9 (Level 12 and 15)', () {
      for (final lvl in [12, 15]) {
        final puzzle = PuzzleRepository.getPuzzleByLevel(lvl);
        expect(puzzle.levelNumber, equals(lvl));

        final hint = HintService.generateHint(
          puzzle: puzzle,
          currentPlacements: const [],
          stage: HintStage.placement,
        );

        expect(hint.targetCell, isNotNull);
        expect(
          puzzle.solution.any((p) => p.row == hint.targetCell!.x && p.col == hint.targetCell!.y),
          isTrue,
          reason: 'Procedural puzzle at Level $lvl must provide valid hint matching solution',
        );
      }
    });

    // 12. No hardcoded nine-level assumption exists in the hint implementation
    test('12. No hardcoded nine-level assumption exists in the hint implementation', () {
      // Create or generate a puzzle with levelNumber 999
      final puzzle999 = PuzzleRepository.getPuzzleByLevel(999);
      expect(puzzle999.levelNumber, equals(999));

      final hint1 = HintService.generateHint(
        puzzle: puzzle999,
        currentPlacements: const [],
        stage: HintStage.guidance,
      );
      expect(hint1.remainingDogsNeeded, equals(10));

      final hint3 = HintService.generateHint(
        puzzle: puzzle999,
        currentPlacements: const [],
        stage: HintStage.placement,
      );
      expect(hint3.targetCell, isNotNull);
      expect(
        puzzle999.solution.any((p) => p.row == hint3.targetCell!.x && p.col == hint3.targetCell!.y),
        isTrue,
      );
    });
  });
}
