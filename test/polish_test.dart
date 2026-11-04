import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/app.dart';
import 'package:snapdog/core/utils/sound_haptic_helper.dart';
import 'package:snapdog/features/game/screens/game_completion_screen.dart';
import 'package:snapdog/features/game/screens/game_screen.dart';
import 'package:snapdog/features/onboarding/widgets/tutorial_dialog.dart';
import 'package:snapdog/features/settings/models/settings_state.dart';
import 'package:snapdog/features/settings/providers/settings_provider.dart';
import 'package:snapdog/features/settings/screens/settings_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundHapticHelper.soundEnabled = true;
    SoundHapticHelper.hapticsEnabled = true;
  });

  group('Milestone 5 Polish: Sound & Haptic Toggles', () {
    test('Sound toggle updates state and SoundHapticHelper', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).ensureInitialized();
      expect(container.read(settingsProvider).soundEnabled, isTrue);
      expect(SoundHapticHelper.soundEnabled, isTrue);

      await container.read(settingsProvider.notifier).toggleSound(false);

      expect(container.read(settingsProvider).soundEnabled, isFalse);
      expect(SoundHapticHelper.soundEnabled, isFalse);

      await container.read(settingsProvider.notifier).toggleSound(true);

      expect(container.read(settingsProvider).soundEnabled, isTrue);
      expect(SoundHapticHelper.soundEnabled, isTrue);
    });

    test('Haptic toggle updates state and SoundHapticHelper', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).ensureInitialized();
      expect(container.read(settingsProvider).hapticsEnabled, isTrue);
      expect(SoundHapticHelper.hapticsEnabled, isTrue);

      await container.read(settingsProvider.notifier).toggleHaptics(false);

      expect(container.read(settingsProvider).hapticsEnabled, isFalse);
      expect(SoundHapticHelper.hapticsEnabled, isFalse);

      await container.read(settingsProvider.notifier).toggleHaptics(true);

      expect(container.read(settingsProvider).hapticsEnabled, isTrue);
      expect(SoundHapticHelper.hapticsEnabled, isTrue);
    });

    test('SoundHapticHelper triggers safely without crashing when enabled or disabled', () {
      SoundHapticHelper.soundEnabled = true;
      SoundHapticHelper.hapticsEnabled = true;

      expect(() => SoundHapticHelper.buttonClick(), returnsNormally);
      expect(() => SoundHapticHelper.dogPlace(), returnsNormally);
      expect(() => SoundHapticHelper.crossMark(), returnsNormally);
      expect(() => SoundHapticHelper.dogRemove(), returnsNormally);
      expect(() => SoundHapticHelper.invalidPlacement(), returnsNormally);
      expect(() => SoundHapticHelper.hintUsed(), returnsNormally);
      expect(() => SoundHapticHelper.puzzleCompleted(), returnsNormally);
      expect(() => SoundHapticHelper.undoAction(), returnsNormally);

      SoundHapticHelper.soundEnabled = false;
      SoundHapticHelper.hapticsEnabled = false;

      expect(() => SoundHapticHelper.buttonClick(), returnsNormally);
      expect(() => SoundHapticHelper.dogPlace(), returnsNormally);
      expect(() => SoundHapticHelper.crossMark(), returnsNormally);
      expect(() => SoundHapticHelper.dogRemove(), returnsNormally);
      expect(() => SoundHapticHelper.invalidPlacement(), returnsNormally);
      expect(() => SoundHapticHelper.hintUsed(), returnsNormally);
      expect(() => SoundHapticHelper.puzzleCompleted(), returnsNormally);
      expect(() => SoundHapticHelper.undoAction(), returnsNormally);
    });
  });

  group('Milestone 5 Polish: Theme Switching & AppTheme', () {
    test('Theme switching updates isDarkMode state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).ensureInitialized();
      expect(container.read(settingsProvider).isDarkMode, isFalse);

      await container.read(settingsProvider.notifier).toggleDarkMode(true);
      expect(container.read(settingsProvider).isDarkMode, isTrue);

      await container.read(settingsProvider.notifier).toggleDarkMode(false);
      expect(container.read(settingsProvider).isDarkMode, isFalse);
    });

    testWidgets('App reacts to theme changes dynamically', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SnapDogApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.light);

      final BuildContext context = tester.element(find.byType(SnapDogApp));
      final container = ProviderScope.containerOf(context);
      await container.read(settingsProvider.notifier).toggleDarkMode(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final updatedApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(updatedApp.themeMode, ThemeMode.dark);
    });
  });

  group('Milestone 5 Polish: Onboarding & Tutorial Persistence', () {
    test('Onboarding persistence saves and retrieves properly', () async {
      expect(await SettingsRepository.hasCompletedOnboarding(), isFalse);

      await SettingsRepository.setOnboardingCompleted();
      expect(await SettingsRepository.hasCompletedOnboarding(), isTrue);
    });

    testWidgets('TutorialDialog renders 6 steps with skip and next', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TutorialDialog(
                onCompleted: () => completed = true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify step 1 dialog is shown
      expect(find.text('One Dog Per Row'), findsOneWidget);
      expect(find.text('STEP 1 OF 6'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Swipe to step 2
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('One Dog Per Column'), findsOneWidget);
      expect(find.text('STEP 2 OF 6'), findsOneWidget);

      // Tap Skip
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(completed, isTrue);
    });
  });

  group('Milestone 5 Polish: Settings Screen & Reset Progress Confirmation', () {
    testWidgets('Settings screen renders toggles, How to Play, and Reset dialog', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Puppy Settings'), findsOneWidget);
      expect(find.text('Sound Effects'), findsOneWidget);
      expect(find.text('Haptic Vibration'), findsOneWidget);
      expect(find.text('Game Experience'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('How to Play'), findsOneWidget);
      expect(find.text('Reset Game Progress'), findsOneWidget);

      // Tap Reset Game Progress to verify warning confirmation dialog
      await tester.tap(find.text('Reset Game Progress'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Reset All Progress?'), findsOneWidget);
      expect(find.textContaining('This will permanently delete all your completed puzzles'), findsOneWidget);
      expect(find.text('Keep Progress'), findsOneWidget);
      expect(find.text('Reset Everything'), findsOneWidget);

      // Cancel dismisses dialog without deleting
      await tester.tap(find.text('Keep Progress'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Reset All Progress?'), findsNothing);
    });

    test('resetAllProgress clears stored progression and daily challenge data', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('snapdog_puzzle_progression_v1', '{"test": 1}');
      await prefs.setString('snapdog_daily_challenge_v1', '{"streak": 5}');
      await prefs.setString('snapdog_game_stats', '{"wins": 10}');

      expect(prefs.containsKey('snapdog_puzzle_progression_v1'), isTrue);
      expect(prefs.containsKey('snapdog_daily_challenge_v1'), isTrue);
      expect(prefs.containsKey('snapdog_game_stats'), isTrue);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).resetAllProgress();

      expect(prefs.containsKey('snapdog_puzzle_progression_v1'), isFalse);
      expect(prefs.containsKey('snapdog_daily_challenge_v1'), isFalse);
      expect(prefs.containsKey('snapdog_game_stats'), isFalse);
    });
  });

  group('Milestone 5 Polish: Game Completion Screen & Best Time', () {
    testWidgets('GameCompletionScreen displays stats, new best time badge, and replay button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool nextPressed = false;
      bool replayPressed = false;
      bool homePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: GameCompletionScreen(
            timeSeconds: 75,
            hintsUsed: 1,
            mistakes: 2,
            bestTimeSeconds: 60,
            isNewBestTime: true,
            puzzleTitle: 'Puppy Park 1',
            onNextPuzzle: () => nextPressed = true,
            onReplay: () => replayPressed = true,
            onHome: () => homePressed = true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pawsome Victory!'), findsOneWidget);
      expect(find.text('All 10 dogs placed happily in Puppy Park 1!'), findsOneWidget);
      expect(find.text('New Personal Best Time!'), findsOneWidget);
      expect(find.text('01:15'), findsOneWidget); // Time: 75s
      expect(find.text('01:00'), findsOneWidget); // Best: 60s
      expect(find.text('1'), findsOneWidget); // Hints
      expect(find.text('2'), findsOneWidget); // Mistakes
      expect(find.text('Next Puzzle'), findsOneWidget);
      expect(find.text('Replay Puzzle'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);

      await tester.tap(find.text('Next Puzzle'));
      expect(nextPressed, isTrue);

      await tester.tap(find.text('Replay Puzzle'));
      expect(replayPressed, isTrue);

      await tester.tap(find.text('Back to Home'));
      expect(homePressed, isTrue);
    });
  });

  group('Milestone 5 Polish: Responsive Layouts across Screen Sizes', () {
    testWidgets('Board renders cleanly on small phone screen (320x568)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.textContaining('Puppy Park'), findsOneWidget);
    });

    testWidgets('Board renders cleanly on standard phone screen (390x844)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(GameScreen), findsOneWidget);
    });

    testWidgets('Board renders cleanly on large phone screen (480x1000)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(480, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(GameScreen), findsOneWidget);
    });
  });

  group('Milestone 5 Polish: Board Accessibility & Semantics', () {
    testWidgets('Board cells include descriptive semantic labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check cell semantic label format: "Row 1, Column 1"
      final cellSemanticFinder = find.bySemanticsLabel(RegExp(r'^Row 1, Column 1$'));
      expect(cellSemanticFinder, findsOneWidget);
    });
  });
}
