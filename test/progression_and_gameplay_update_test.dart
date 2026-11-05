import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/app.dart';
import 'package:snapdog/core/services/sound_service.dart';
import 'package:snapdog/features/game/providers/game_provider.dart';
import 'package:snapdog/features/game/services/puzzle_repository.dart';
import 'package:snapdog/features/game/services/puzzle_validator.dart';
import 'package:snapdog/features/progression/models/progression_state.dart';
import 'package:snapdog/features/progression/providers/progression_provider.dart';
import 'package:snapdog/features/progression/services/progression_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.instance.resetTestingState();
    SoundService.instance.init(soundEnabled: false, volume: 0.0);
  });

  group('SnapDog Progression and Gameplay Update - 8 Required Scenarios', () {
    test('Scenario 1: Complete Level 1 -> Next Level -> Level 2 opens', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final gameNotifier = container.read(puzzleGameProvider.notifier);
      final progressionNotifier = container.read(progressionProvider.notifier);

      expect(container.read(puzzleGameProvider).puzzle.levelNumber, equals(1));

      // Solve level 1
      final p1 = PuzzleRepository.getPuzzleByLevel(1);
      progressionNotifier.recordCompletion(
        puzzle: p1,
        placements: p1.solution,
        timeSeconds: 30,
        hintsUsed: 0,
        mistakes: 0,
      );

      // Call nextPuzzle
      gameNotifier.nextPuzzle();

      final updatedState = container.read(puzzleGameProvider);
      expect(updatedState.puzzle.levelNumber, equals(2));
      expect(container.read(progressionProvider).highestUnlockedLevel, greaterThanOrEqualTo(2));
      expect(container.read(progressionProvider).currentLevel, equals(2));
    });

    test('Scenario 2: Complete Level 1 -> Home -> Continue Level -> Level 2 opens', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final progressionNotifier = container.read(progressionProvider.notifier);
      final p1 = PuzzleRepository.getPuzzleByLevel(1);

      // Player completes Level 1
      progressionNotifier.recordCompletion(
        puzzle: p1,
        placements: p1.solution,
        timeSeconds: 25,
        hintsUsed: 0,
        mistakes: 0,
      );

      // Now Home screen determines resume puzzle
      final progression = container.read(progressionProvider);
      final resumePuzzle = progression.getResumePuzzle();

      expect(resumePuzzle.levelNumber, equals(2));
      expect(progression.isLevelCompleted(1), isTrue);
      expect(progression.isLevelCompleted(2), isFalse);

      // Load through Continue Level
      container.read(puzzleGameProvider.notifier).loadLevel(resumePuzzle.levelNumber);
      expect(container.read(puzzleGameProvider).puzzle.levelNumber, equals(2));
    });

    test('Scenario 3: Start Level 2, mark some X cells, close app, reopen -> Continue Level resumes Level 2 with progress intact', () async {
      SharedPreferences.setMockInitialValues({});

      // Simulate completed Level 1 and in-progress Level 2 saved in repository
      final inProgress = InProgressPuzzleState(
        puzzleId: 'puzzle_2',
        levelNumber: 2,
        placements: const [],
        crosses: {const Point(0, 0), const Point(1, 1), const Point(2, 2)},
        timerSeconds: 42,
        mistakes: 1,
        hintsUsed: 0,
      );

      final stateToSave = ProgressionState(
        highestUnlockedLevel: 2,
        currentLevel: 2,
        inProgressState: inProgress,
      );
      await ProgressionRepository.saveProgression(stateToSave);

      // Simulate app restart: fresh container reading from storage
      final savedState = await ProgressionRepository.loadProgression();
      expect(savedState.inProgressState, isNotNull);
      expect(savedState.inProgressState!.levelNumber, equals(2));
      expect(savedState.inProgressState!.crosses.length, equals(3));
      expect(savedState.inProgressState!.timerSeconds, equals(42));
      expect(savedState.inProgressState!.mistakes, equals(1));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initialize provider with loaded state
      container.read(progressionProvider.notifier).setStateForTesting(savedState);

      final resumePuzzle = container.read(progressionProvider).getResumePuzzle();
      expect(resumePuzzle.levelNumber, equals(2));

      // Load resume puzzle into game
      container.read(puzzleGameProvider.notifier).loadLevel(resumePuzzle.levelNumber);
      final gameState = container.read(puzzleGameProvider);

      expect(gameState.puzzle.levelNumber, equals(2));
      expect(gameState.crosses.contains(const Point(0, 0)), isTrue);
      expect(gameState.crosses.contains(const Point(1, 1)), isTrue);
      expect(gameState.crosses.contains(const Point(2, 2)), isTrue);
      expect(gameState.timerSeconds, equals(42));
      expect(gameState.mistakes, equals(1));
    });

    test('Scenario 4: Complete Level 2 -> Home -> Continue Level -> Level 3 opens', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final progressionNotifier = container.read(progressionProvider.notifier);
      final p1 = PuzzleRepository.getPuzzleByLevel(1);
      final p2 = PuzzleRepository.getPuzzleByLevel(2);

      progressionNotifier.recordCompletion(
        puzzle: p1,
        placements: p1.solution,
        timeSeconds: 30,
        hintsUsed: 0,
        mistakes: 0,
      );

      progressionNotifier.recordCompletion(
        puzzle: p2,
        placements: p2.solution,
        timeSeconds: 35,
        hintsUsed: 0,
        mistakes: 0,
      );

      final progression = container.read(progressionProvider);
      expect(progression.isLevelCompleted(1), isTrue);
      expect(progression.isLevelCompleted(2), isTrue);
      expect(progression.isLevelCompleted(3), isFalse);

      final resumePuzzle = progression.getResumePuzzle();
      expect(resumePuzzle.levelNumber, equals(3));

      container.read(puzzleGameProvider.notifier).loadLevel(resumePuzzle.levelNumber);
      expect(container.read(puzzleGameProvider).puzzle.levelNumber, equals(3));
    });

    test('Scenario 5: Drag over X cells -> X marks are removed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);

      // Pre-mark cells (1, 1), (1, 2), (1, 3) with crosses
      notifier.singleTapCell(1, 1);
      notifier.singleTapCell(1, 2);
      notifier.singleTapCell(1, 3);

      var state = container.read(puzzleGameProvider);
      expect(state.hasCrossAt(1, 1), isTrue);
      expect(state.hasCrossAt(1, 2), isTrue);
      expect(state.hasCrossAt(1, 3), isTrue);

      // Drag starting on an X cell (1, 1) across (1, 2) and (1, 3)
      notifier.startDragCross(1, 1);
      notifier.updateDragCross(1, 2);
      notifier.updateDragCross(1, 3);
      notifier.endDragCross();

      state = container.read(puzzleGameProvider);
      expect(state.hasCrossAt(1, 1), isFalse);
      expect(state.hasCrossAt(1, 2), isFalse);
      expect(state.hasCrossAt(1, 3), isFalse);
    });

    test('Scenario 6: Drag over a mixture of marked and unmarked cells -> follows starting cell state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);

      // Case A: Starting on an empty cell (2, 1) -> drag action is ADD cross
      // Cells: (2, 1) empty, (2, 2) already has X, (2, 3) empty
      notifier.singleTapCell(2, 2);
      expect(container.read(puzzleGameProvider).hasCrossAt(2, 2), isTrue);

      notifier.startDragCross(2, 1); // starts on empty -> addCross mode
      notifier.updateDragCross(2, 2); // already has cross -> stays cross
      notifier.updateDragCross(2, 3); // empty -> gets cross
      notifier.endDragCross();

      var state = container.read(puzzleGameProvider);
      expect(state.hasCrossAt(2, 1), isTrue);
      expect(state.hasCrossAt(2, 2), isTrue);
      expect(state.hasCrossAt(2, 3), isTrue);

      // Case B: Starting on an X cell (3, 1) -> drag action is REMOVE cross
      // Pre-mark (3, 1) and (3, 3) with X; leave (3, 2) empty
      notifier.singleTapCell(3, 1);
      notifier.singleTapCell(3, 3);

      notifier.startDragCross(3, 1); // starts on X -> removeCross mode
      notifier.updateDragCross(3, 2); // empty -> remains empty (remove action does not mark!)
      notifier.updateDragCross(3, 3); // has X -> removed
      notifier.endDragCross();

      state = container.read(puzzleGameProvider);
      expect(state.hasCrossAt(3, 1), isFalse);
      expect(state.hasCrossAt(3, 2), isFalse);
      expect(state.hasCrossAt(3, 3), isFalse);
    });

    test('Scenario 7: Undo after a drag-to-remove gesture -> all affected X marks are restored', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);

      // Pre-mark (4, 1), (4, 2), (4, 3)
      notifier.singleTapCell(4, 1);
      notifier.singleTapCell(4, 2);
      notifier.singleTapCell(4, 3);

      // Drag to remove
      notifier.startDragCross(4, 1);
      notifier.updateDragCross(4, 2);
      notifier.updateDragCross(4, 3);
      notifier.endDragCross();

      var state = container.read(puzzleGameProvider);
      expect(state.hasCrossAt(4, 1), isFalse);
      expect(state.hasCrossAt(4, 2), isFalse);
      expect(state.hasCrossAt(4, 3), isFalse);

      // Perform single undo
      notifier.undo();

      state = container.read(puzzleGameProvider);
      expect(state.hasCrossAt(4, 1), isTrue);
      expect(state.hasCrossAt(4, 2), isTrue);
      expect(state.hasCrossAt(4, 3), isTrue);
    });

    test('Scenario 8: Verify that no completed level is accidentally replayed through Continue Level', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final progressionNotifier = container.read(progressionProvider.notifier);

      // Sequentially complete levels 1, 2, 3, 4, 5
      for (int lvl = 1; lvl <= 5; lvl++) {
        final p = PuzzleRepository.getPuzzleByLevel(lvl);
        progressionNotifier.recordCompletion(
          puzzle: p,
          placements: p.solution,
          timeSeconds: 20,
          hintsUsed: 0,
          mistakes: 0,
        );

        // Verify Continue Level points to lvl + 1, NEVER any completed level <= lvl
        final resume = container.read(progressionProvider).getResumePuzzle();
        expect(resume.levelNumber, equals(lvl + 1));
        for (int completed = 1; completed <= lvl; completed++) {
          expect(resume.levelNumber, isNot(equals(completed)));
        }
      }
    });

    test('Procedural Endless Generation: Levels 10 to 50 generate valid rule-compliant puzzles', () {
      for (int lvl = 10; lvl <= 50; lvl += 5) {
        final puzzle = PuzzleRepository.getPuzzleByLevel(lvl);
        expect(puzzle.levelNumber, equals(lvl));
        expect(puzzle.solution.length, equals(10), reason: 'Must place 10 dogs');

        // Verify row and column constraints (1 dog per row, 1 dog per col)
        final rows = puzzle.solution.map((p) => p.row).toSet();
        final cols = puzzle.solution.map((p) => p.col).toSet();
        expect(rows.length, equals(10));
        expect(cols.length, equals(10));

        // Verify no orthogonal or diagonal neighbors
        final validation = PuzzleValidator.findClashingPlacements(puzzle, puzzle.solution);
        expect(validation, isEmpty, reason: 'Level $lvl solution must have no clashing placements');

        // Verify each dog is in a unique region
        final regions = puzzle.solution.map((p) => puzzle.getRegionAt(p.row, p.col)).toSet();
        expect(regions.length, equals(10));
      }
    });

    testWidgets('UI Test: Home screen Continue Level button and badge display current level', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SnapDogApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Initial state: Level 1
      expect(find.text('Continue Level'), findsOneWidget);
      expect(find.textContaining('Level 1'), findsWidgets);

      // Verify no "Overall Progress" card
      expect(find.text('Overall Progress'), findsNothing);
      // Verify no "Play Levels" button
      expect(find.text('Play Levels'), findsNothing);

      // Tap Continue Level
      await tester.tap(find.text('Continue Level'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Gameplay screen shows Level 1 badge and EASY tag
      expect(find.text('Level 1'), findsWidgets);
      expect(find.text('EASY'), findsOneWidget);
    });
  });
}
