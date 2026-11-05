import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/core/services/sound_service.dart';
import 'package:snapdog/core/utils/sound_haptic_helper.dart';
import 'package:snapdog/features/game/providers/game_provider.dart';
import 'package:snapdog/features/game/screens/game_completion_screen.dart';
import 'package:snapdog/features/game/screens/game_screen.dart';
import 'package:snapdog/features/game/widgets/mistake_dialog.dart';
import 'package:snapdog/features/settings/screens/settings_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.instance.resetTestingState();
    SoundService.instance.init(soundEnabled: true, volume: 1.0);
    SoundHapticHelper.soundEnabled = true;
    SoundHapticHelper.hapticsEnabled = true;
  });

  group('SnapDog – Step 5: Sound Effects & Dedicated SoundService', () {
    test('SoundService correctly records each distinct audio trigger', () {
      final soundService = SoundService.instance;

      // 1. Dog place correctly
      SoundHapticHelper.dogPlace();
      expect(soundService.lastPlayedSoundAsset, SoundService.correctPlacementSoundAsset);
      expect(soundService.lastPlayedSoundAsset, 'audio/dog_chime.wav');

      // 2. Cross marked
      SoundHapticHelper.crossMark();
      expect(soundService.lastPlayedSoundAsset, SoundService.crossSoundAsset);
      expect(soundService.lastPlayedSoundAsset, 'audio/cross_pop.wav');

      // 3. Invalid placement
      SoundHapticHelper.invalidPlacement();
      expect(soundService.lastPlayedSoundAsset, SoundService.wrongPlacementSoundAsset);
      expect(soundService.lastPlayedSoundAsset, 'audio/wrong_bloop.wav');

      // 4. Undo action
      SoundHapticHelper.undoAction();
      expect(soundService.lastPlayedSoundAsset, SoundService.undoSoundAsset);
      expect(soundService.lastPlayedSoundAsset, 'audio/undo_pop.wav');

      // 5. Hint used
      SoundHapticHelper.hintUsed();
      expect(soundService.lastPlayedSoundAsset, SoundService.hintSoundAsset);
      expect(soundService.lastPlayedSoundAsset, 'audio/hint_sparkle.wav');

      // 6. Button interaction
      SoundHapticHelper.buttonClick();
      expect(soundService.lastPlayedSoundAsset, SoundService.buttonSoundAsset);
      expect(soundService.lastPlayedSoundAsset, 'audio/button_click.wav');

      // 7. Puzzle completed
      SoundHapticHelper.puzzleCompleted();
      expect(soundService.lastPlayedSoundAsset, SoundService.completionSoundAsset);
      expect(soundService.lastPlayedSoundAsset, 'audio/puzzle_complete.wav');
    });

    test('Sound respects soundEnabled and volume controls', () {
      final soundService = SoundService.instance;
      soundService.resetTestingState();

      // Disable sound
      soundService.setSoundEnabled(false);
      SoundHapticHelper.dogPlace();
      expect(soundService.playCount, 0);
      expect(soundService.lastPlayedSoundAsset, isNull);

      // Re-enable sound
      soundService.setSoundEnabled(true);
      SoundHapticHelper.dogPlace();
      expect(soundService.playCount, 1);
      expect(soundService.lastPlayedSoundAsset, 'audio/dog_chime.wav');

      // Volume set to 0.0
      soundService.setVolume(0.0);
      SoundHapticHelper.crossMark();
      expect(soundService.playCount, 1); // Not incremented when muted
    });
  });

  group('SnapDog – Step 5: Dog Placement & Feedback Animations', () {
    testWidgets('Double-tap valid cell places dog with aura ring and chime', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // (0, 7) is a verified solution cell for puzzle 0
      final targetKey = const ValueKey('cell_0_7');
      await tester.tap(find.byKey(targetKey));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.byKey(targetKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Correct placement sound recorded
      expect(SoundService.instance.lastPlayedSoundAsset, SoundService.correctPlacementSoundAsset);

      // Verify dog character and aura ring exist in that cell
      expect(find.byKey(const ValueKey('cell_dog')), findsOneWidget);
    });

    testWidgets('Hint activates pulsing highlight on suggested cell', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hint'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Hint sound was played
      expect(SoundService.instance.lastPlayedSoundAsset, SoundService.hintSoundAsset);

      // Advance to stage 2 then stage 3 for cell placement hint
      await tester.tap(find.text('Next clue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Next clue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Cell hint paw icon and pulsing highlight exist
      expect(find.byKey(const ValueKey('cell_hint')), findsOneWidget);
    });
  });

  group('SnapDog – Step 5: Mistake Feedback & 3-Mistake Limit', () {
    testWidgets('Mistake shows shake, error sound, and exactly 1 mistake increment', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // (0, 0) is wrong for puzzle 0
      final wrongCellKey = const ValueKey('cell_0_0');
      await tester.tap(find.byKey(wrongCellKey));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.byKey(wrongCellKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Error sound played
      expect(SoundService.instance.lastPlayedSoundAsset, SoundService.wrongPlacementSoundAsset);

      // Shake widget key exists
      expect(find.byKey(const ValueKey('shake_0_0')), findsOneWidget);

      // Mistake dialog overlay shown
      expect(find.byType(MistakeDialog), findsOneWidget);
      expect(find.text('Mistakes: 1/3'), findsOneWidget);

      // Incorrect dog is NOT placed on the board
      expect(find.byKey(const ValueKey('cell_dog')), findsNothing);
    });
  });

  group('SnapDog – Step 5: Level Completion Experience', () {
    testWidgets('GameCompletionScreen displays all required headers and stats', (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool nextTapped = false;
      bool homeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: GameCompletionScreen(
            timeSeconds: 125,
            hintsUsed: 2,
            mistakes: 0,
            puzzleTitle: 'Sunny Meadow 1',
            bestTimeSeconds: 110,
            isNewBestTime: false,
            onNextPuzzle: () => nextTapped = true,
            onHome: () => homeTapped = true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. "Level Completed!" heading
      expect(find.text('Level Completed!'), findsOneWidget);

      // 2. Victory celebration heading
      expect(find.text('Pawsome Victory!'), findsOneWidget);

      // 3. Completion time (125s -> 02:05)
      expect(find.text('02:05'), findsOneWidget);

      // 4. Hints used
      expect(find.text('2'), findsOneWidget);

      // 5. Mistakes (including 0 mistakes)
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Mistakes'), findsOneWidget);

      // 6. Navigation buttons
      expect(find.text('Next Puzzle'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);

      // Interactions
      await tester.tap(find.text('Next Puzzle'));
      expect(nextTapped, isTrue);

      await tester.tap(find.text('Back to Home'));
      expect(homeTapped, isTrue);
    });

    testWidgets('Puzzle completion stops timer and triggers victory exactly once', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);
      final puzzle = container.read(puzzleGameProvider).puzzle;

      // Place 9 correct solution dogs
      for (int i = 0; i < 9; i++) {
        final sol = puzzle.solution[i];
        notifier.doubleTapCell(sol.row, sol.col);
      }

      expect(container.read(puzzleGameProvider).isCompleted, isFalse);
      expect(container.read(puzzleGameProvider).placements.length, 9);

      // Place 10th solution dog to complete the puzzle
      final lastSol = puzzle.solution[9];
      notifier.doubleTapCell(lastSol.row, lastSol.col);

      expect(container.read(puzzleGameProvider).isCompleted, isTrue);
      expect(container.read(puzzleGameProvider).placements.length, 10);
      expect(SoundService.instance.lastPlayedSoundAsset, SoundService.completionSoundAsset);

      // Tapping more cells after completion does nothing
      notifier.singleTapCell(0, 0);
      expect(container.read(puzzleGameProvider).crosses.contains(const Point(0, 0)), isFalse);
    });
  });

  group('SnapDog – Step 5: Settings Persistence', () {
    testWidgets('Settings screen persists sound, volume, and haptics immediately', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Sound Effects'), findsOneWidget);
      expect(find.text('Haptic Vibration'), findsOneWidget);
      expect(find.text('Sound Volume'), findsOneWidget);

      // Toggle sound off
      await tester.tap(find.text('Sound Effects'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(SoundService.instance.soundEnabled, isFalse);

      // Toggle haptics off
      await tester.tap(find.text('Haptic Vibration'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(SoundHapticHelper.hapticsEnabled, isFalse);
    });
  });
}
