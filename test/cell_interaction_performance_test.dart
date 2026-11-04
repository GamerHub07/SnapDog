import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/core/services/sound_service.dart';
import 'package:snapdog/features/game/providers/game_provider.dart';
import 'package:snapdog/features/game/screens/game_screen.dart';
import 'package:snapdog/shared/widgets/clay_cross_marker.dart';
import 'package:snapdog/shared/widgets/cute_dog_character.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.instance.resetTestingState();
    SoundService.instance.init(soundEnabled: true, volume: 1.0);
  });

  group('SnapDog – Step 1: Optimize Cell Interaction Performance Tests', () {
    testWidgets('1. Immediate pressed-state feedback on pointer down', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cellFinder = find.byKey(const ValueKey('cell_0_0'));
      expect(cellFinder, findsOneWidget);

      // Verify cell initially has normal scale (1.0)
      final initialScale = tester.widget<AnimatedScale>(
        find.descendant(of: cellFinder, matching: find.byType(AnimatedScale)),
      );
      expect(initialScale.scale, equals(1.0));

      // Pointer down event on cell
      final gesture = await tester.startGesture(tester.getCenter(cellFinder));
      await tester.pump();

      // Immediately upon pointer down (0ms latency), scale is set to pressed state (0.93)
      final pressedScale = tester.widget<AnimatedScale>(
        find.descendant(of: cellFinder, matching: find.byType(AnimatedScale)),
      );
      expect(pressedScale.scale, equals(0.93));

      // Pointer up releases pressed state
      await gesture.up();
      await tester.pump();

      final releasedScale = tester.widget<AnimatedScale>(
        find.descendant(of: cellFinder, matching: find.byType(AnimatedScale)),
      );
      expect(releasedScale.scale, equals(1.0));

      // Allow single tap timer (220ms) to complete
      await tester.pump(const Duration(milliseconds: 230));
    });

    testWidgets('2. Double tap within 220ms places dog and NEVER accidentally creates an X first', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // (0, 7) is a solution cell for puzzle 0
      final solutionCell = find.byKey(const ValueKey('cell_0_7'));

      // First tap down and up
      final gesture1 = await tester.startGesture(tester.getCenter(solutionCell));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture1.up();
      await tester.pump();

      // At this point (before 220ms), X must NOT exist
      expect(find.descendant(of: solutionCell, matching: find.byType(ClayCrossMarker)), findsNothing);

      // Wait 80ms (total elapsed < 220ms) and dispatch second tap
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.descendant(of: solutionCell, matching: find.byType(ClayCrossMarker)), findsNothing);

      final gesture2 = await tester.startGesture(tester.getCenter(solutionCell));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture2.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Dog is placed!
      expect(find.descendant(of: solutionCell, matching: find.byType(CuteDogCharacter)), findsOneWidget);

      // X was NEVER created
      expect(find.descendant(of: solutionCell, matching: find.byType(ClayCrossMarker)), findsNothing);
    });

    testWidgets('3. Single tap confirms cross after 220ms double-tap timeout', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cell = find.byKey(const ValueKey('cell_1_1'));

      // Single tap
      final gesture = await tester.startGesture(tester.getCenter(cell));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.up();
      await tester.pump();

      // Before 220ms timeout, cross is not yet placed
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.descendant(of: cell, matching: find.byType(ClayCrossMarker)), findsNothing);

      // Once 220ms elapses, cross is confirmed and animated
      await tester.pump(const Duration(milliseconds: 130));
      expect(find.descendant(of: cell, matching: find.byType(ClayCrossMarker)), findsOneWidget);
    });

    testWidgets('4. Rapid taps on different cells operate independently and responsively', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cellA = find.byKey(const ValueKey('cell_2_2'));
      final cellB = find.byKey(const ValueKey('cell_4_4'));

      // Tap cell A
      await tester.tap(cellA);
      await tester.pump(const Duration(milliseconds: 50));

      // Tap cell B
      await tester.tap(cellB);
      await tester.pump();

      // Advance clock past 220ms
      await tester.pump(const Duration(milliseconds: 250));

      // Both cells independently received cross
      expect(find.descendant(of: cellA, matching: find.byType(ClayCrossMarker)), findsOneWidget);
      expect(find.descendant(of: cellB, matching: find.byType(ClayCrossMarker)), findsOneWidget);
    });

    test('5. copyWith skips expensive findClashingPlacements when placements do not change', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final stateBefore = container.read(puzzleGameProvider);
      expect(stateBefore.clashingPlacements, isEmpty);

      // Calling copyWith without changing placements or puzzle
      final stateAfter = stateBefore.copyWith(timerSeconds: 10);
      expect(identical(stateBefore.clashingPlacements, stateAfter.clashingPlacements), isTrue);
    });
  });
}
