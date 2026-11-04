import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapdog/app.dart';
import 'package:snapdog/features/game/screens/game_screen.dart';
import 'package:snapdog/features/home/widgets/daily_challenge_card.dart';
import 'package:snapdog/features/progression/screens/puzzle_selection_screen.dart';
import 'package:snapdog/shared/widgets/cute_dog_character.dart';

void main() {
  testWidgets('SnapDog App renders Home screen with Continue Playing and Play buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SnapDogApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify SnapDog branding and puzzle prompt exist
    expect(find.text('SnapDog'), findsOneWidget);
    expect(find.text('Can you place all 10 dogs with no touching?'), findsOneWidget);
    expect(find.text('Overall Progress'), findsOneWidget);
    expect(find.text('Continue Playing'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);

    // Tap Play button to open PuzzleSelectionScreen
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    expect(find.byType(PuzzleSelectionScreen), findsOneWidget);
    expect(find.text('Select Puzzle'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
  });

  testWidgets('Navigation to GameScreen and interactive board controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: GameScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify GameScreen components render properly
    expect(find.textContaining('Puppy Park'), findsOneWidget);
    expect(find.text('Dogs: 0/10'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);

    // Tap Hint button
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('A little pup belongs here!'), findsOneWidget);

    // Tap Reset button to open confirmation dialog
    await tester.tap(find.text('Reset'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Reset Puzzle?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap Cancel in dialog
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Dialog closed
    expect(find.text('Reset Puzzle?'), findsNothing);
  });

  testWidgets('Cell gestures: single tap marks cross, double tap places dog, replaces cross', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: GameScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final cellFinder = find.byKey(const ValueKey('cell_0_7'));
    expect(cellFinder, findsOneWidget);

    // 1. Single tap on empty cell: marks with cross (close icon)
    await tester.tap(cellFinder);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.descendant(of: cellFinder, matching: find.byIcon(Icons.close_rounded)), findsOneWidget);
    expect(find.byType(CuteDogCharacter), findsNothing);
    expect(find.text('Dogs: 0/10'), findsOneWidget); // Cross does not change dog count

    // 2. Double tap on the same crossed cell: replaces cross with dog!
    await tester.tap(cellFinder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(cellFinder);
    await tester.pumpAndSettle();

    expect(find.byType(CuteDogCharacter), findsOneWidget);
    expect(find.descendant(of: cellFinder, matching: find.byIcon(Icons.close_rounded)), findsNothing);
    expect(find.text('Dogs: 1/10'), findsOneWidget);

    // 3. Locked dog cannot be undone: dog remains on board
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.byType(CuteDogCharacter), findsOneWidget);
    expect(find.text('Dogs: 1/10'), findsOneWidget);

    // 4. Single tap on locked dog does not remove it
    await tester.tap(cellFinder);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.byType(CuteDogCharacter), findsOneWidget);
    expect(find.text('Dogs: 1/10'), findsOneWidget);

    // 5. Eligible cross marking and undo on another cell
    final emptyCellFinder = find.byKey(const ValueKey('cell_1_1'));
    await tester.tap(emptyCellFinder);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.descendant(of: emptyCellFinder, matching: find.byIcon(Icons.close_rounded)), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: emptyCellFinder, matching: find.byIcon(Icons.close_rounded)), findsNothing);
  });

  testWidgets('Home screen Daily Challenge card opens DailyChallengeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SnapDogApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap on the daily challenge card
    final dailyCardFinder = find.byType(DailyChallengeCard);
    expect(dailyCardFinder, findsOneWidget);

    await tester.scrollUntilVisible(dailyCardFinder, 200);
    await tester.tap(dailyCardFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Daily Challenge screen components
    expect(find.text('Daily Challenge'), findsOneWidget);
    expect(find.text('Play Today\'s Challenge'), findsOneWidget);
    expect(find.text('Challenge Calendar'), findsOneWidget);
    expect(find.text('Streak Rewards'), findsOneWidget);
    expect(find.text('Puppy Steps'), findsOneWidget);
    expect(find.text('Good Dog'), findsOneWidget);
    expect(find.text('Top Dog Champion'), findsOneWidget);
  });
}
