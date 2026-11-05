import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/app.dart';
import 'package:snapdog/features/game/screens/game_screen.dart';
import 'package:snapdog/features/home/widgets/daily_challenge_card.dart';
import 'package:snapdog/features/home/widgets/home_decorations.dart';
import 'package:snapdog/features/home/widgets/home_dog_face_row.dart';
import 'package:snapdog/features/home/widgets/latest_completed_challenge_card.dart';
import 'package:snapdog/features/settings/screens/settings_screen.dart';
import 'package:snapdog/features/statistics/screens/statistics_screen.dart';
import 'package:snapdog/shared/widgets/cute_dog_character.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'snapdog_onboarding_completed': true,
    });
  });

  testWidgets('SnapDog App renders Home screen with Continue Level button', (WidgetTester tester) async {
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
    expect(find.text('Continue Level'), findsOneWidget);
    expect(find.textContaining('Level 1'), findsOneWidget);

    // Verify decorative row of 3D dog face illustrations
    expect(find.byType(HomeDogFaceRow), findsOneWidget);

    // Verify settings button on header
    expect(find.byIcon(Icons.settings_rounded), findsWidgets);

    // Verify statistics card is removed from home screen
    expect(find.text('Games Played'), findsNothing);
    expect(find.text('Day Streak'), findsNothing);

    // Verify subtle decorative background elements are present
    expect(find.byType(HomeBackgroundDecorations), findsOneWidget);

    // Verify only one completed challenge card (DailyChallengeCard) is present in Home screen
    expect(find.byType(DailyChallengeCard), findsOneWidget);
    expect(find.byType(LatestCompletedChallengeCard), findsNothing);
  });

  testWidgets('Progress screen displays relocated statistics, streaks, achievements, and completion history', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SnapDogApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Switch to Progress tab in bottom navigation
    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Verify StatisticsScreen rendered with all relocated metrics
    expect(find.byType(StatisticsScreen), findsOneWidget);
    expect(find.text('Puppy Progress'), findsOneWidget);
    expect(find.text('Progress & Stats Overview'), findsOneWidget);
    expect(find.text('Games Played'), findsOneWidget);
    expect(find.text('Levels Completed'), findsOneWidget);
    expect(find.text('Day Streak'), findsOneWidget);

    // Verify streaks section
    expect(find.text('Streak Stats'), findsOneWidget);
    expect(find.text('Current Streak'), findsOneWidget);
    expect(find.text('Best Streak'), findsOneWidget);

    // Verify milestone achievements
    expect(find.text('Milestone Achievements'), findsOneWidget);
    expect(find.text('Puppy Steps'), findsOneWidget);
    expect(find.text('Good Dog'), findsOneWidget);
    expect(find.text('Top Dog Champion'), findsOneWidget);

    // Verify completion history section
    expect(find.text('Level Completion History'), findsOneWidget);
    expect(find.textContaining('Puppy Park'), findsOneWidget);
  });

  testWidgets('Home header settings icon opens SettingsScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SnapDogApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap settings icon in header (tooltip: 'Settings')
    final settingsIconFinder = find.byTooltip('Settings');
    expect(settingsIconFinder, findsOneWidget);
    await tester.tap(settingsIconFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Puppy Settings'), findsOneWidget);
    expect(find.text('Feedback & Senses'), findsOneWidget);
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
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('EASY'), findsOneWidget);
    expect(find.text('Dogs: 0/10'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);

    // Tap Hint button
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('A little pup belongs here!'), findsOneWidget);

    // Dismiss the Hint overlay dialog via Got it button
    if (find.text('Got it').evaluate().isNotEmpty) {
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    }

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
