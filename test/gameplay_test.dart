import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapdog/features/game/models/dog_placement.dart';
import 'package:snapdog/features/game/providers/game_provider.dart';
import 'package:snapdog/features/game/services/puzzle_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('SnapDog – Cell Interaction Update & Validation', () {
    test('1. Selecting cells updates selectedCell', () {
      final notifier = container.read(puzzleGameProvider.notifier);
      expect(container.read(puzzleGameProvider).selectedCell, isNull);

      notifier.selectCell(3, 4);
      expect(container.read(puzzleGameProvider).selectedCell, equals(const Point(3, 4)));

      notifier.selectCell(0, 0);
      expect(container.read(puzzleGameProvider).selectedCell, equals(const Point(0, 0)));
    });

    test('2. Single tap marks with a cross (×) and never places a dog', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      expect(container.read(puzzleGameProvider).hasCrossAt(0, 0), isFalse);
      expect(container.read(puzzleGameProvider).hasDogAt(0, 0), isFalse);

      // Single tap on empty cell (0, 0)
      notifier.singleTapCell(0, 0);

      final state = container.read(puzzleGameProvider);
      expect(state.hasCrossAt(0, 0), isTrue);
      expect(state.hasDogAt(0, 0), isFalse); // Single tap must NEVER place a dog
      expect(state.dogCount, equals(0)); // Crosses must NOT affect dog count
      expect(state.selectedCell, equals(const Point(0, 0)));
      expect(state.undoStack.length, equals(1));
    });

    test('3. Toggling crosses: single tapping a crossed cell removes cross and returns to empty', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      // Single tap to mark with cross
      notifier.singleTapCell(1, 1);
      expect(container.read(puzzleGameProvider).hasCrossAt(1, 1), isTrue);

      // Single tap again to toggle cross off
      notifier.singleTapCell(1, 1);
      final state = container.read(puzzleGameProvider);
      expect(state.hasCrossAt(1, 1), isFalse);
      expect(state.hasDogAt(1, 1), isFalse);
      expect(state.undoStack.length, equals(2));
    });

    test('4. Double tap places a dog on empty cell and locks it permanently', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      // Double tap valid position (0, 7) from puzzle solution
      notifier.doubleTapCell(0, 7);

      final state = container.read(puzzleGameProvider);
      expect(state.dogCount, equals(1));
      expect(state.hasDogAt(0, 7), isTrue);
      expect(state.isDogLockedAt(0, 7), isTrue);
      expect(state.hasCrossAt(0, 7), isFalse);
      expect(state.selectedCell, equals(const Point(0, 7)));
      expect(state.mistakes, equals(0));
      expect(state.contextualMessage, isNull);
    });

    test('5. Replacing a cross with a dog: double tap on crossed cell replaces cross with dog', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      // Step 1: Single tap cell (0, 7) to place a cross
      notifier.singleTapCell(0, 7);
      expect(container.read(puzzleGameProvider).hasCrossAt(0, 7), isTrue);
      expect(container.read(puzzleGameProvider).hasDogAt(0, 7), isFalse);

      // Step 2: Double tap cell (0, 7)
      notifier.doubleTapCell(0, 7);

      final state = container.read(puzzleGameProvider);
      expect(state.hasDogAt(0, 7), isTrue);
      expect(state.hasCrossAt(0, 7), isFalse); // Cross must be replaced by dog
      expect(state.dogCount, equals(1));
    });

    test('6. Double tap on an already occupied cell does not duplicate dog', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      // Place dog
      notifier.doubleTapCell(0, 7);
      expect(container.read(puzzleGameProvider).dogCount, equals(1));
      final undoLengthBefore = container.read(puzzleGameProvider).undoStack.length;

      // Double tap same dog cell again
      notifier.doubleTapCell(0, 7);

      final state = container.read(puzzleGameProvider);
      expect(state.dogCount, equals(1)); // Must not duplicate dog
      expect(state.placements.where((p) => p.row == 0 && p.col == 7).length, equals(1));
      expect(state.undoStack.length, equals(undoLengthBefore)); // No duplicate action pushed
    });

    test('7. Single tap on a locked dog does not remove the dog', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      // Place dog
      notifier.doubleTapCell(0, 7);
      expect(container.read(puzzleGameProvider).dogCount, equals(1));

      // Single tap same cell: locked dog must NOT be removed
      notifier.singleTapCell(0, 7);

      final state = container.read(puzzleGameProvider);
      expect(state.dogCount, equals(1));
      expect(state.hasDogAt(0, 7), isTrue);
      expect(state.isDogLockedAt(0, 7), isTrue);
      expect(state.contextualMessage, contains('locked'));
    });

    test('8. Invalid row placement is rejected on double tap, records mistake', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      // Place first dog at (0, 7)
      notifier.doubleTapCell(0, 7);
      expect(container.read(puzzleGameProvider).dogCount, equals(1));

      // Attempt to double-tap in the same row at (0, 1)
      notifier.doubleTapCell(0, 1);

      final state = container.read(puzzleGameProvider);
      expect(state.dogCount, equals(1));
      expect(state.hasDogAt(0, 1), isFalse);
      expect(state.mistakes, equals(1));
      expect(state.contextualMessage, contains('Row 1 already has a puppy'));
      expect(state.conflictingPlacements.contains(const DogPlacement(0, 7)), isTrue);
    });

    test('9. Invalid column placement is rejected on double tap, records mistake', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      // Place first dog at (0, 7)
      notifier.doubleTapCell(0, 7);
      expect(container.read(puzzleGameProvider).dogCount, equals(1));

      // Attempt to double tap in the same column at (8, 7)
      notifier.doubleTapCell(8, 7);

      final state = container.read(puzzleGameProvider);
      expect(state.dogCount, equals(1));
      expect(state.hasDogAt(8, 7), isFalse);
      expect(state.mistakes, equals(1));
      expect(state.contextualMessage, contains('Column 8 already has a puppy'));
      expect(state.conflictingPlacements.contains(const DogPlacement(0, 7)), isTrue);
    });

    test('10. Invalid color-region placement is rejected on double tap', () {
      final notifier = container.read(puzzleGameProvider.notifier);
      final puzzle = container.read(puzzleGameProvider).puzzle;

      Point<int>? cellA;
      Point<int>? cellB;

      outer:
      for (final solDog in puzzle.solution) {
        final reg = puzzle.getRegionAt(solDog.row, solDog.col);
        for (int r2 = 0; r2 < 10; r2++) {
          for (int c2 = 0; c2 < 10; c2++) {
            if (r2 != solDog.row && c2 != solDog.col && (r2 - solDog.row).abs() > 1 && (c2 - solDog.col).abs() > 1) {
              if (puzzle.getRegionAt(r2, c2) == reg) {
                cellA = Point(solDog.row, solDog.col);
                cellB = Point(r2, c2);
                break outer;
              }
            }
          }
        }
      }

      expect(cellA, isNotNull);
      expect(cellB, isNotNull);

      // Place first dog at cellA (which is part of the solution)
      notifier.doubleTapCell(cellA!.x, cellA.y);
      expect(container.read(puzzleGameProvider).dogCount, equals(1));

      // Attempt to place second dog in the same region at cellB
      notifier.doubleTapCell(cellB!.x, cellB.y);

      final state = container.read(puzzleGameProvider);
      expect(state.dogCount, equals(1));
      expect(state.hasDogAt(cellB.x, cellB.y), isFalse);
      expect(state.mistakes, equals(1));
      expect(state.contextualMessage, contains('color area'));
      expect(state.conflictingPlacements.contains(DogPlacement(cellA.x, cellA.y)), isTrue);
    });

    test('11. All eight touching directions are rejected on double tap', () {
      final notifier = container.read(puzzleGameProvider.notifier);
      final puzzle = container.read(puzzleGameProvider).puzzle;
      final solDog = puzzle.solution.firstWhere((p) => p.row == 2 && p.col == 5);

      final eightOffsets = [
        [-1, -1],
        [-1,  0],
        [-1,  1],
        [ 0, -1],
        [ 0,  1],
        [ 1, -1],
        [ 1,  0],
        [ 1,  1],
      ];

      for (final offset in eightOffsets) {
        notifier.resetPuzzle();
        notifier.doubleTapCell(solDog.row, solDog.col);
        expect(container.read(puzzleGameProvider).dogCount, equals(1));

        final tr = solDog.row + offset[0];
        final tc = solDog.col + offset[1];

        notifier.doubleTapCell(tr, tc);

        final state = container.read(puzzleGameProvider);
        expect(state.dogCount, equals(1));
        expect(state.hasDogAt(tr, tc), isFalse);
        expect(state.mistakes, equals(1));
        expect(state.contextualMessage, contains('cannot touch'));
        expect(state.conflictingPlacements.contains(solDog), isTrue);
      }
    });

    test('12. Undo restores both cross and dog actions, including replacing cross with dog', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      // Action 1: Single tap (0, 0) -> cross
      notifier.singleTapCell(0, 0);
      expect(container.read(puzzleGameProvider).hasCrossAt(0, 0), isTrue);

      // Undo Action 1: returns to empty
      notifier.undo();
      expect(container.read(puzzleGameProvider).hasCrossAt(0, 0), isFalse);

      // Action 2: Single tap (0, 0) -> cross
      notifier.singleTapCell(0, 0);
      expect(container.read(puzzleGameProvider).hasCrossAt(0, 0), isTrue);

      // Action 3: Single tap (0, 0) -> empty (removed cross)
      notifier.singleTapCell(0, 0);
      expect(container.read(puzzleGameProvider).hasCrossAt(0, 0), isFalse);

      // Undo Action 3: cross restored!
      notifier.undo();
      expect(container.read(puzzleGameProvider).hasCrossAt(0, 0), isTrue);

      // Action 4: Place a locked dog at (0, 7)
      notifier.doubleTapCell(0, 7);
      expect(container.read(puzzleGameProvider).hasDogAt(0, 7), isTrue);

      // Action 5: Add cross at (2, 2)
      notifier.singleTapCell(2, 2);
      expect(container.read(puzzleGameProvider).hasCrossAt(2, 2), isTrue);

      // Undo Action 5: Cross at (2, 2) is undone, but locked dog at (0, 7) remains locked!
      notifier.undo();
      expect(container.read(puzzleGameProvider).hasCrossAt(2, 2), isFalse);
      expect(container.read(puzzleGameProvider).hasDogAt(0, 7), isTrue);

      // Undo Action 3: Cross at (0, 0) is undone, locked dog at (0, 7) remains locked!
      notifier.undo();
      expect(container.read(puzzleGameProvider).hasCrossAt(0, 0), isFalse);
      expect(container.read(puzzleGameProvider).hasDogAt(0, 7), isTrue);
    });

    test('13. Reset clears both dogs and crosses, timer, mistakes, hints, and undo stack', () {
      final notifier = container.read(puzzleGameProvider.notifier);

      // Put cross, put dog, make mistake, use hint
      notifier.singleTapCell(1, 1); // Cross
      notifier.doubleTapCell(0, 7); // Dog
      notifier.doubleTapCell(0, 1); // Mistake
      notifier.useHint(); // Hint

      final before = container.read(puzzleGameProvider);
      expect(before.hasCrossAt(1, 1), isTrue);
      expect(before.hasDogAt(0, 7), isTrue);
      expect(before.mistakes, equals(1));
      expect(before.hintsUsed, equals(1));
      expect(before.undoStack.isNotEmpty, isTrue);

      // Execute reset
      notifier.resetPuzzle();

      final after = container.read(puzzleGameProvider);
      expect(after.hasCrossAt(1, 1), isFalse); // Cross cleared
      expect(after.dogCount, equals(0)); // Dogs cleared
      expect(after.mistakes, equals(0));
      expect(after.hintsUsed, equals(0));
      expect(after.timerSeconds, equals(0));
      expect(after.undoStack, isEmpty);
      expect(after.selectedCell, isNull);
      expect(after.hintCell, isNull);
      expect(after.contextualMessage, isNull);
      expect(after.isCompleted, isFalse);
    });

    test('14. Puzzle completion succeeds with crosses present on the board', () {
      final notifier = container.read(puzzleGameProvider.notifier);
      final puzzle = container.read(puzzleGameProvider).puzzle;

      expect(container.read(puzzleGameProvider).isCompleted, isFalse);

      // Add arbitrary crosses across non-solution cells
      notifier.singleTapCell(0, 0);
      notifier.singleTapCell(1, 1);
      notifier.singleTapCell(2, 2);
      notifier.singleTapCell(3, 3);
      notifier.singleTapCell(4, 4);

      expect(container.read(puzzleGameProvider).crosses.length, equals(5));

      // Place all 10 dogs according to verified solution
      for (final dog in puzzle.solution) {
        notifier.doubleTapCell(dog.row, dog.col);
      }

      final state = container.read(puzzleGameProvider);
      expect(state.dogCount, equals(10));
      expect(state.isCompleted, isTrue);
      expect(PuzzleValidator.isPuzzleCompleted(puzzle, state.placements), isTrue);
    });

    test('15. Hint on a crossed cell replaces the cross with the dog when accepted', () {
      final notifier = container.read(puzzleGameProvider.notifier);
      final puzzle = container.read(puzzleGameProvider).puzzle;

      final targetSol = puzzle.solution.first;

      // Mark that cell with a cross
      notifier.singleTapCell(targetSol.row, targetSol.col);
      expect(container.read(puzzleGameProvider).hasCrossAt(targetSol.row, targetSol.col), isTrue);

      // Request hint (targets an unplaced solution cell)
      notifier.useHint();
      final state = container.read(puzzleGameProvider);
      expect(state.hintCell, equals(Point(targetSol.row, targetSol.col)));
      expect(state.contextualMessage, equals('A little pup belongs here!'));

      // Accept hint
      notifier.acceptHint();

      final after = container.read(puzzleGameProvider);
      expect(after.hasDogAt(targetSol.row, targetSol.col), isTrue);
      expect(after.hasCrossAt(targetSol.row, targetSol.col), isFalse); // Cross replaced
      expect(after.hintCell, isNull);
    });
  });
}
