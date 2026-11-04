import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapdog/core/constants/app_colors.dart';
import 'package:snapdog/features/game/providers/game_provider.dart';
import 'package:snapdog/features/game/widgets/puzzle_board_widget.dart';
import 'package:snapdog/features/game/widgets/game_over_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('SnapDog – Gameplay Rule Update (Mistakes, Locked Dogs & Crosses)', () {
    test('1. Correct dog placement locks the dog', () {
      final notifier = container.read(puzzleGameProvider.notifier);
      final puzzle = container.read(puzzleGameProvider).puzzle;

      // Solution dog for puzzle 0 is (0, 7)
      final solDog = puzzle.solution.first;
      notifier.doubleTapCell(solDog.row, solDog.col);

      final state = container.read(puzzleGameProvider);
      expect(state.hasDogAt(solDog.row, solDog.col), isTrue);
      expect(state.isDogLockedAt(solDog.row, solDog.col), isTrue);
      expect(state.dogCount, equals(1));
    });

    test('2. Correct dog cannot be removed by single tap or double tap', () {
      final notifier = container.read(puzzleGameProvider.notifier);
      final puzzle = container.read(puzzleGameProvider).puzzle;
      final solDog = puzzle.solution.first;

      // Place correct dog
      notifier.doubleTapCell(solDog.row, solDog.col);
      expect(container.read(puzzleGameProvider).hasDogAt(solDog.row, solDog.col), isTrue);

      // Single tap on the dog: must NOT remove the dog
      notifier.singleTapCell(solDog.row, solDog.col);
      expect(container.read(puzzleGameProvider).hasDogAt(solDog.row, solDog.col), isTrue);
      expect(container.read(puzzleGameProvider).dogCount, equals(1));
      expect(container.read(puzzleGameProvider).contextualMessage, contains('locked'));

      // Double tap on the dog: must NOT duplicate or remove the dog
      notifier.doubleTapCell(solDog.row, solDog.col);
      expect(container.read(puzzleGameProvider).hasDogAt(solDog.row, solDog.col), isTrue);
      expect(container.read(puzzleGameProvider).dogCount, equals(1));
    });

    test('3. Correct dog cannot be undone', () {
      final notifier = container.read(puzzleGameProvider.notifier);
      final puzzle = container.read(puzzleGameProvider).puzzle;
      final solDog = puzzle.solution.first;

      // Place cross at (1, 1)
      notifier.singleTapCell(1, 1);
      expect(container.read(puzzleGameProvider).hasCrossAt(1, 1), isTrue);

      // Place correct dog at solution position
      notifier.doubleTapCell(solDog.row, solDog.col);
      expect(container.read(puzzleGameProvider).hasDogAt(solDog.row, solDog.col), isTrue);

      // Undo should undo the eligible cross, but NOT the locked dog
      notifier.undo();
      final state = container.read(puzzleGameProvider);
      expect(state.hasCrossAt(1, 1), isFalse);
      expect(state.hasDogAt(solDog.row, solDog.col), isTrue); // Locked dog remains!
      expect(state.dogCount, equals(1));

      // Further undo has nothing left, locked dog still remains
      notifier.undo();
      expect(container.read(puzzleGameProvider).hasDogAt(solDog.row, solDog.col), isTrue);
    });

    test('4. A locally valid but solution-incorrect dog placement counts as a mistake', () {
      final notifier = container.read(puzzleGameProvider.notifier);
      final puzzle = container.read(puzzleGameProvider).puzzle;

      // (0, 0) satisfies local row/col/region constraints on an empty board,
      // but (0, 0) is not in the verified solution for puzzle 0 (which has (0, 7)).
      expect(puzzle.solution.any((p) => p.row == 0 && p.col == 0), isFalse);

      notifier.doubleTapCell(0, 0);

      final state = container.read(puzzleGameProvider);
      expect(state.mistakes, equals(1));
      expect(state.hasDogAt(0, 0), isFalse); // Not placed
      expect(state.dogCount, equals(0));
      expect(state.contextualMessage, contains('not part of the solution'));
    });

    test('5. Wrong dog is removed after feedback', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      // Place in wrong position
      notifier.doubleTapCell(0, 0);

      final state = container.read(puzzleGameProvider);
      // Wrong dog is never left on the board
      expect(state.hasDogAt(0, 0), isFalse);
      expect(state.wrongPlacementCell, equals(const Point(0, 0)));
      expect(state.isWrongPlacementAt(0, 0), isTrue);
    });

    test('6. Each wrong placement increments mistakes exactly once', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      expect(container.read(puzzleGameProvider).mistakes, equals(0));

      notifier.doubleTapCell(0, 0); // Mistake 1
      expect(container.read(puzzleGameProvider).mistakes, equals(1));

      notifier.doubleTapCell(0, 1); // Mistake 2
      expect(container.read(puzzleGameProvider).mistakes, equals(2));
    });

    test('7. First and second mistakes allow continued play', () {
      final notifier = container.read(puzzleGameProvider.notifier);
      final puzzle = container.read(puzzleGameProvider).puzzle;

      // Mistake 1
      notifier.doubleTapCell(0, 0);
      var state = container.read(puzzleGameProvider);
      expect(state.mistakes, equals(1));
      expect(state.isGameOver, isFalse);

      // Can still mark cross
      notifier.singleTapCell(3, 3);
      expect(container.read(puzzleGameProvider).hasCrossAt(3, 3), isTrue);

      // Mistake 2
      notifier.doubleTapCell(0, 1);
      state = container.read(puzzleGameProvider);
      expect(state.mistakes, equals(2));
      expect(state.isGameOver, isFalse);

      // Can still place a correct solution dog
      final solDog = puzzle.solution.first;
      notifier.doubleTapCell(solDog.row, solDog.col);
      expect(container.read(puzzleGameProvider).hasDogAt(solDog.row, solDog.col), isTrue);
    });

    test('8. Third mistake triggers Game Over', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      notifier.doubleTapCell(0, 0); // Mistake 1
      expect(container.read(puzzleGameProvider).isGameOver, isFalse);

      notifier.doubleTapCell(0, 1); // Mistake 2
      expect(container.read(puzzleGameProvider).isGameOver, isFalse);

      notifier.doubleTapCell(0, 2); // Mistake 3 -> Game Over!
      final state = container.read(puzzleGameProvider);
      expect(state.mistakes, equals(3));
      expect(state.isGameOver, isTrue);
      expect(state.contextualMessage, contains('Game Over'));

      // Further cell interactions are blocked
      notifier.singleTapCell(4, 4);
      expect(container.read(puzzleGameProvider).hasCrossAt(4, 4), isFalse);
    });

    test('9. Game Over stops the timer', () async {
      final notifier = container.read(puzzleGameProvider.notifier);

      // Trigger Game Over
      notifier.doubleTapCell(0, 0);
      notifier.doubleTapCell(0, 1);
      notifier.doubleTapCell(0, 2);

      final stateAtGameOver = container.read(puzzleGameProvider);
      expect(stateAtGameOver.isGameOver, isTrue);
      final recordedTime = stateAtGameOver.timerSeconds;

      // Wait 1.2s to ensure timer is stopped
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      final stateAfterWait = container.read(puzzleGameProvider);
      expect(stateAfterWait.timerSeconds, equals(recordedTime));
    });

    test('10. Retry resets the attempt correctly', () {
      final notifier = container.read(puzzleGameProvider.notifier);
      final puzzle = container.read(puzzleGameProvider).puzzle;

      // Setup state with correct dog, cross, hint, and 3 mistakes
      notifier.doubleTapCell(puzzle.solution.first.row, puzzle.solution.first.col);
      notifier.singleTapCell(2, 2);
      notifier.useHint();
      notifier.doubleTapCell(0, 0);
      notifier.doubleTapCell(0, 1);
      notifier.doubleTapCell(0, 2); // Game Over

      expect(container.read(puzzleGameProvider).isGameOver, isTrue);

      // Perform retry/reset
      notifier.resetPuzzle();

      final resetState = container.read(puzzleGameProvider);
      expect(resetState.isGameOver, isFalse);
      expect(resetState.isCompleted, isFalse);
      expect(resetState.mistakes, equals(0));
      expect(resetState.hintsUsed, equals(0));
      expect(resetState.dogCount, equals(0));
      expect(resetState.crosses, isEmpty);
      expect(resetState.undoStack, isEmpty);
      expect(resetState.timerSeconds, equals(0));
      expect(resetState.contextualMessage, isNull);
    });

    test('11. Game Over does not mark a puzzle completed', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      notifier.doubleTapCell(0, 0);
      notifier.doubleTapCell(0, 1);
      notifier.doubleTapCell(0, 2);

      final state = container.read(puzzleGameProvider);
      expect(state.isGameOver, isTrue);
      expect(state.isCompleted, isFalse);
    });

    test('12. Cross size and visibility are updated without breaking the board layout', () {
      // Direct unit check on PuzzleGameState cross state
      final notifier = container.read(puzzleGameProvider.notifier);
      notifier.singleTapCell(4, 5);
      expect(container.read(puzzleGameProvider).hasCrossAt(4, 5), isTrue);
    });

    test('13. Undo still works for eligible cross actions', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      // Action 1: Mark cross at (2, 3)
      notifier.singleTapCell(2, 3);
      expect(container.read(puzzleGameProvider).hasCrossAt(2, 3), isTrue);

      // Action 2: Mark cross at (2, 4)
      notifier.singleTapCell(2, 4);
      expect(container.read(puzzleGameProvider).hasCrossAt(2, 4), isTrue);

      // Undo Action 2: cross at (2, 4) removed, cross at (2, 3) remains
      notifier.undo();
      expect(container.read(puzzleGameProvider).hasCrossAt(2, 4), isFalse);
      expect(container.read(puzzleGameProvider).hasCrossAt(2, 3), isTrue);

      // Action 3: Tap crossed cell (2, 3) to remove cross
      notifier.singleTapCell(2, 3);
      expect(container.read(puzzleGameProvider).hasCrossAt(2, 3), isFalse);

      // Undo Action 3: cross at (2, 3) restored
      notifier.undo();
      expect(container.read(puzzleGameProvider).hasCrossAt(2, 3), isTrue);
    });

    testWidgets('12b. Widget verification: Cross size 22 bold and board layout renders cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 640,
                child: PuzzleBoardWidget(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap cell (0, 0) to place a cross
      final cellFinder = find.byKey(const ValueKey('cell_0_0'));
      await tester.tap(cellFinder);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify the cross icon is rendered with size 22 and text color
      final iconFinder = find.byIcon(Icons.close_rounded);
      expect(iconFinder, findsOneWidget);
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.size, equals(22));
      expect(iconWidget.color, equals(AppColors.text));

      // No overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('GameOverDialog displays friendly message, 3/3 mistakes, Retry and Home buttons', (WidgetTester tester) async {
      bool retried = false;
      bool wentHome = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverDialog(
              onRetry: () => retried = true,
              onHome: () => wentHome = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Game Over'), findsOneWidget);
      expect(find.textContaining('every puppy stumbles'), findsOneWidget);
      expect(find.text('Mistakes used: 3/3'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);

      await tester.tap(find.text('Home'));
      expect(wentHome, isTrue);
    });
  });
}
