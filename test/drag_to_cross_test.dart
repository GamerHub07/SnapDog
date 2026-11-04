import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/core/services/sound_service.dart';
import 'package:snapdog/features/game/providers/game_provider.dart';
import 'package:snapdog/features/game/screens/game_screen.dart';
import 'package:snapdog/shared/widgets/clay_cross_marker.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.instance.resetTestingState();
    SoundService.instance.init(soundEnabled: true, volume: 1.0);
  });

  group('SnapDog – Step 2: Drag-to-Cross Controller Unit Tests', () {
    test('1. Horizontal dragging across empty cells marks each cell with an X', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);

      // Start drag at (1, 1) and drag horizontally to (1, 5)
      notifier.startDragCross(1, 1);
      for (int c = 2; c <= 5; c++) {
        notifier.updateDragCross(1, c);
      }
      notifier.endDragCross();

      final state = container.read(puzzleGameProvider);
      for (int c = 1; c <= 5; c++) {
        expect(state.hasCrossAt(1, c), isTrue, reason: 'Cell (1, $c) must have cross');
      }
      expect(state.undoStack.length, equals(1), reason: 'Must produce exactly one undo action');
    });

    test('2. Vertical dragging across empty cells marks each cell with an X', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);

      // Start drag at (2, 3) and drag vertically to (6, 3)
      notifier.startDragCross(2, 3);
      for (int r = 3; r <= 6; r++) {
        notifier.updateDragCross(r, 3);
      }
      notifier.endDragCross();

      final state = container.read(puzzleGameProvider);
      for (int r = 2; r <= 6; r++) {
        expect(state.hasCrossAt(r, 3), isTrue, reason: 'Cell ($r, 3) must have cross');
      }
      expect(state.undoStack.length, equals(1));
    });

    test('3. Diagonal dragging across empty cells marks each cell with an X', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);

      // Start drag diagonally from (1, 1) to (4, 4)
      notifier.startDragCross(1, 1);
      notifier.updateDragCross(2, 2);
      notifier.updateDragCross(3, 3);
      notifier.updateDragCross(4, 4);
      notifier.endDragCross();

      final state = container.read(puzzleGameProvider);
      for (int i = 1; i <= 4; i++) {
        expect(state.hasCrossAt(i, i), isTrue, reason: 'Cell ($i, $i) must have cross');
      }
      expect(state.undoStack.length, equals(1));
    });

    test('4. Duplicate prevention: cells already containing X do not duplicate or remove it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);

      // Place a cross at (1, 3) beforehand
      notifier.singleTapCell(1, 3);
      final initialUndoCount = container.read(puzzleGameProvider).undoStack.length;

      // Drag across (1, 1) through (1, 4)
      notifier.startDragCross(1, 1);
      notifier.updateDragCross(1, 2);
      notifier.updateDragCross(1, 3); // Already has X
      notifier.updateDragCross(1, 4);
      notifier.endDragCross();

      final state = container.read(puzzleGameProvider);
      expect(state.hasCrossAt(1, 3), isTrue, reason: 'Existing X marker must remain');
      expect(state.crosses.length, equals(4)); // (1, 1), (1, 2), (1, 3), (1, 4)
      expect(state.undoStack.length, equals(initialUndoCount + 1));
    });

    test('5. Dog cells and locked dogs remain untouched, dragging NEVER places dogs', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);

      // (0, 7) is a solution cell for puzzle 0; place a dog there
      notifier.doubleTapCell(0, 7);
      expect(container.read(puzzleGameProvider).hasDogAt(0, 7), isTrue);

      final dogCountBefore = container.read(puzzleGameProvider).placements.length;

      // Drag across row 0 from (0, 5) to (0, 9), passing directly through the dog at (0, 7)
      notifier.startDragCross(0, 5);
      notifier.updateDragCross(0, 6);
      notifier.updateDragCross(0, 7); // Dog cell
      notifier.updateDragCross(0, 8);
      notifier.updateDragCross(0, 9);
      notifier.endDragCross();

      final state = container.read(puzzleGameProvider);

      // Dog at (0, 7) must still exist and must NOT have a cross placed over it
      expect(state.hasDogAt(0, 7), isTrue);
      expect(state.hasCrossAt(0, 7), isFalse);
      expect(state.placements.length, equals(dogCountBefore), reason: 'Dragging must NEVER place or remove dogs');

      // Empty cells receive crosses
      expect(state.hasCrossAt(0, 5), isTrue);
      expect(state.hasCrossAt(0, 6), isTrue);
      expect(state.hasCrossAt(0, 8), isTrue);
      expect(state.hasCrossAt(0, 9), isTrue);
    });

    test('6. One drag produces ONE undo action, and undo removes only newly added crosses', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);

      // Place a prior cross at (2, 2)
      notifier.singleTapCell(2, 2);

      // Place a prior dog at (0, 7)
      notifier.doubleTapCell(0, 7);

      final undoCountBeforeDrag = container.read(puzzleGameProvider).undoStack.length;

      // Drag across (3, 1), (3, 2), (3, 3), (3, 4), (3, 5)
      notifier.startDragCross(3, 1);
      for (int c = 2; c <= 5; c++) {
        notifier.updateDragCross(3, c);
      }
      notifier.endDragCross();

      final stateAfterDrag = container.read(puzzleGameProvider);
      expect(stateAfterDrag.undoStack.length, equals(undoCountBeforeDrag + 1));
      for (int c = 1; c <= 5; c++) {
        expect(stateAfterDrag.hasCrossAt(3, c), isTrue);
      }

      // Perform single Undo
      notifier.undo();

      final stateAfterUndo = container.read(puzzleGameProvider);

      // All newly added crosses from drag must be removed together
      for (int c = 1; c <= 5; c++) {
        expect(stateAfterUndo.hasCrossAt(3, c), isFalse, reason: 'Cell (3, $c) cross must be undone');
      }

      // Prior cross at (2, 2) and dog at (0, 7) must remain intact
      expect(stateAfterUndo.hasCrossAt(2, 2), isTrue, reason: 'Prior cross must remain intact');
      expect(stateAfterUndo.hasDogAt(0, 7), isTrue, reason: 'Prior dog must remain intact');
    });

    test('7. Drag cancellation reverts any crosses marked during the cancelled drag', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);

      notifier.startDragCross(5, 1);
      notifier.updateDragCross(5, 2);
      notifier.updateDragCross(5, 3);

      expect(container.read(puzzleGameProvider).hasCrossAt(5, 1), isTrue);
      expect(container.read(puzzleGameProvider).hasCrossAt(5, 2), isTrue);
      expect(container.read(puzzleGameProvider).hasCrossAt(5, 3), isTrue);

      // Cancel drag
      notifier.cancelDragCross();

      final state = container.read(puzzleGameProvider);
      expect(state.hasCrossAt(5, 1), isFalse);
      expect(state.hasCrossAt(5, 2), isFalse);
      expect(state.hasCrossAt(5, 3), isFalse);
      expect(state.undoStack, isEmpty);
      expect(notifier.isDragging, isFalse);
    });

    test('8. Re-visiting the same cell multiple times during one drag processes it at most once', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);

      // Drag back and forth over (4, 1), (4, 2), (4, 3)
      notifier.startDragCross(4, 1);
      notifier.updateDragCross(4, 2);
      notifier.updateDragCross(4, 3);
      notifier.updateDragCross(4, 2); // revisit
      notifier.updateDragCross(4, 1); // revisit
      notifier.endDragCross();

      final state = container.read(puzzleGameProvider);
      expect(state.crosses.length, equals(3));
      expect(state.undoStack.length, equals(1));
    });
  });

  group('SnapDog – Step 2: Drag-to-Cross UI & Gesture Widget Tests', () {
    testWidgets('9. Touch and drag across multiple cells marks all cells with crosses immediately', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cell1 = find.byKey(const ValueKey('cell_1_1'));
      final cell2 = find.byKey(const ValueKey('cell_1_2'));
      final cell3 = find.byKey(const ValueKey('cell_1_3'));
      final cell4 = find.byKey(const ValueKey('cell_1_4'));

      // Initially empty
      expect(find.descendant(of: cell1, matching: find.byType(ClayCrossMarker)), findsNothing);
      expect(find.descendant(of: cell2, matching: find.byType(ClayCrossMarker)), findsNothing);
      expect(find.descendant(of: cell3, matching: find.byType(ClayCrossMarker)), findsNothing);
      expect(find.descendant(of: cell4, matching: find.byType(ClayCrossMarker)), findsNothing);

      // Start drag at cell (1, 1) and drag continuously to (1, 4)
      final gesture = await tester.startGesture(tester.getCenter(cell1));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture.moveTo(tester.getCenter(cell2));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture.moveTo(tester.getCenter(cell3));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture.moveTo(tester.getCenter(cell4));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture.up();
      await tester.pumpAndSettle();

      // All 4 cells must now have cross markers
      expect(find.descendant(of: cell1, matching: find.byType(ClayCrossMarker)), findsOneWidget);
      expect(find.descendant(of: cell2, matching: find.byType(ClayCrossMarker)), findsOneWidget);
      expect(find.descendant(of: cell3, matching: find.byType(ClayCrossMarker)), findsOneWidget);
      expect(find.descendant(of: cell4, matching: find.byType(ClayCrossMarker)), findsOneWidget);

      // Tap Undo button (IconButton with undo icon)
      final undoButton = find.byIcon(Icons.undo_rounded);
      expect(undoButton, findsOneWidget);
      await tester.tap(undoButton);
      await tester.pumpAndSettle();

      // All 4 crosses from that drag must be removed together in ONE undo
      expect(find.descendant(of: cell1, matching: find.byType(ClayCrossMarker)), findsNothing);
      expect(find.descendant(of: cell2, matching: find.byType(ClayCrossMarker)), findsNothing);
      expect(find.descendant(of: cell3, matching: find.byType(ClayCrossMarker)), findsNothing);
      expect(find.descendant(of: cell4, matching: find.byType(ClayCrossMarker)), findsNothing);
    });

    testWidgets('10. Fast swipe diagonal drag interpolates intermediate cells', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cellA = find.byKey(const ValueKey('cell_2_2'));
      final cellB = find.byKey(const ValueKey('cell_3_3'));
      final cellC = find.byKey(const ValueKey('cell_4_4'));
      final cellD = find.byKey(const ValueKey('cell_5_5'));

      // Fast swipe from (2, 2) directly to (5, 5) without pausing on (3, 3) or (4, 4)
      final gesture = await tester.startGesture(tester.getCenter(cellA));
      await tester.pump(const Duration(milliseconds: 10));

      await gesture.moveTo(tester.getCenter(cellD));
      await tester.pump(const Duration(milliseconds: 10));

      await gesture.up();
      await tester.pumpAndSettle();

      // Bresenham interpolation ensures intermediate diagonal cells are not skipped
      expect(find.descendant(of: cellA, matching: find.byType(ClayCrossMarker)), findsOneWidget);
      expect(find.descendant(of: cellB, matching: find.byType(ClayCrossMarker)), findsOneWidget);
      expect(find.descendant(of: cellC, matching: find.byType(ClayCrossMarker)), findsOneWidget);
      expect(find.descendant(of: cellD, matching: find.byType(ClayCrossMarker)), findsOneWidget);
    });

    testWidgets('11. Touch slop threshold distinguishes tapping from dragging', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cell = find.byKey(const ValueKey('cell_3_3'));

      // Micro-movement within 12px touch slop (e.g. 4px jitter)
      final gesture = await tester.startGesture(tester.getCenter(cell));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveBy(const Offset(4, 3)); // Distance = 5px < 12px
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.up();
      await tester.pump();

      // Before 220ms single-tap window, X is not placed
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.descendant(of: cell, matching: find.byType(ClayCrossMarker)), findsNothing);

      // Once 220ms elapses, recognized as a single tap!
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.descendant(of: cell, matching: find.byType(ClayCrossMarker)), findsOneWidget);
    });
  });
}
