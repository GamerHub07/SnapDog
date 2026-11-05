import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/core/services/sound_service.dart';
import 'package:snapdog/core/utils/sound_haptic_helper.dart';
import 'package:snapdog/features/game/screens/game_screen.dart';
import 'package:snapdog/features/game/widgets/game_over_dialog.dart';
import 'package:snapdog/features/game/widgets/hint_banner_widget.dart';
import 'package:snapdog/features/game/widgets/mistake_dialog.dart';
import 'package:snapdog/features/game/widgets/puzzle_board_widget.dart';
import 'package:snapdog/features/settings/models/settings_state.dart';
import 'package:snapdog/features/settings/screens/settings_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.instance.resetTestingState();
    SoundService.instance.init(soundEnabled: true, volume: 1.0);
    SoundHapticHelper.soundEnabled = true;
    SoundHapticHelper.hapticsEnabled = true;
  });

  group('SnapDog – Gameplay Dialog Fix & Audio Effects Tests', () {
    testWidgets('1. Mistake dialog does NOT change board position or size before, during, or after', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boardFinder = find.byType(PuzzleBoardWidget);
      expect(boardFinder, findsOneWidget);

      final rectBefore = tester.getRect(boardFinder);

      // (0, 0) is NOT part of the solution for puzzle 0 (solution row 0 is at (0, 7))
      // Double tap (0, 0) to place a wrong dog and trigger a mistake
      await tester.tap(find.byKey(const ValueKey('cell_0_0')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const ValueKey('cell_0_0')));
      await tester.pump();
      await tester.pumpAndSettle();

      // MistakeDialog is displayed as an overlay
      expect(find.byType(MistakeDialog), findsOneWidget);
      expect(find.text('Oops! Wrong Spot'), findsOneWidget);
      expect(find.descendant(of: find.byType(MistakeDialog), matching: find.text('Mistakes: 1/3')), findsOneWidget);

      // Verify board position & size are completely unchanged during dialog display
      final rectDuring = tester.getRect(boardFinder);
      expect(rectDuring, equals(rectBefore));

      // Dismiss dialog
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.byType(MistakeDialog), findsNothing);

      // Verify board position & size remain completely unchanged after dialog dismissal
      final rectAfter = tester.getRect(boardFinder);
      expect(rectAfter, equals(rectBefore));
    });

    testWidgets('2. Hint banner displays correctly without shifting layout', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boardFinder = find.byType(PuzzleBoardWidget);
      expect(boardFinder, findsOneWidget);

      // Tap Hint button
      await tester.tap(find.text('Hint'));
      await tester.pump();
      await tester.pumpAndSettle();

      // HintBannerWidget is displayed
      expect(find.byType(HintBannerWidget), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);

      // Verify board remains visible and does not overlap hint banner
      final bannerRect = tester.getRect(find.byType(HintBannerWidget));
      final boardRect = tester.getRect(boardFinder);
      expect(bannerRect.overlaps(boardRect), isFalse);

      // Dismiss hint
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.byType(HintBannerWidget), findsNothing);
    });

    testWidgets('3. Rapid taps cannot open duplicate dialogs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Hint button twice in rapid succession
      await tester.tap(find.text('Hint'));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(find.text('Hint'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Exactly ONE HintBannerWidget is open
      expect(find.byType(HintBannerWidget), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.byType(HintBannerWidget), findsNothing);
    });

    testWidgets('4. 3rd mistake shows GameOverDialog instead of regular MistakeDialog', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mistake 1 at (0, 0)
      await tester.tap(find.byKey(const ValueKey('cell_0_0')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const ValueKey('cell_0_0')));
      await tester.pumpAndSettle();
      expect(find.byType(MistakeDialog), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      // Mistake 2 at (0, 1)
      await tester.tap(find.byKey(const ValueKey('cell_0_1')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const ValueKey('cell_0_1')));
      await tester.pumpAndSettle();
      expect(find.byType(MistakeDialog), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      // Mistake 3 at (0, 2) -> Game Over!
      await tester.tap(find.byKey(const ValueKey('cell_0_2')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const ValueKey('cell_0_2')));
      await tester.pumpAndSettle();

      // Regular MistakeDialog should NOT be displayed on 3rd mistake
      expect(find.byType(MistakeDialog), findsNothing);

      // GameOverDialog must be displayed
      expect(find.byType(GameOverDialog), findsOneWidget);
      expect(find.text('Mistakes used: 3/3'), findsOneWidget);
    });

    test('5. SoundService plays correct sound asset for each specific gameplay interaction', () {
      final sound = SoundService.instance;
      sound.resetTestingState();

      // 1. Cross marking
      sound.playCrossSound();
      expect(sound.lastPlayedSoundAsset, equals(SoundService.crossSoundAsset));

      // 2. Correct dog placement
      sound.playCorrectPlacementSound();
      expect(sound.lastPlayedSoundAsset, equals(SoundService.correctPlacementSoundAsset));

      // 3. Wrong dog placement
      sound.playWrongPlacementSound();
      expect(sound.lastPlayedSoundAsset, equals(SoundService.wrongPlacementSoundAsset));

      // 4. Undo / dog remove
      sound.playUndoSound();
      expect(sound.lastPlayedSoundAsset, equals(SoundService.undoSoundAsset));

      // 5. Hint usage
      sound.playHintSound();
      expect(sound.lastPlayedSoundAsset, equals(SoundService.hintSoundAsset));

      // 6. Puzzle completion
      sound.playCompletionSound();
      expect(sound.lastPlayedSoundAsset, equals(SoundService.completionSoundAsset));

      // 7. Button interaction
      sound.playButtonSound();
      expect(sound.lastPlayedSoundAsset, equals(SoundService.buttonSoundAsset));

      expect(sound.playCount, equals(7));
    });

    test('6. Sound toggle and volume correctly mute audio playback', () {
      final sound = SoundService.instance;
      sound.resetTestingState();

      // When soundEnabled is false
      sound.setSoundEnabled(false);
      sound.playCrossSound();
      sound.playCorrectPlacementSound();
      expect(sound.playCount, equals(0));

      // Re-enable sound
      sound.setSoundEnabled(true);
      sound.playCrossSound();
      expect(sound.playCount, equals(1));

      // When volume is 0.0
      sound.setVolume(0.0);
      sound.playWrongPlacementSound();
      expect(sound.playCount, equals(1)); // Does not increment

      // Volume restored
      sound.setVolume(0.8);
      sound.playWrongPlacementSound();
      expect(sound.playCount, equals(2));
    });

    test('7. Muting sound does NOT disable haptic feedback', () {
      SoundHapticHelper.soundEnabled = false;
      SoundHapticHelper.hapticsEnabled = true;

      expect(SoundHapticHelper.soundEnabled, isFalse);
      expect(SoundHapticHelper.hapticsEnabled, isTrue);

      // Safe invocation without throwing
      expect(() => SoundHapticHelper.dogPlace(), returnsNormally);
      expect(() => SoundHapticHelper.crossMark(), returnsNormally);
      expect(() => SoundHapticHelper.invalidPlacement(), returnsNormally);

      // Verify haptics can still be independently toggled
      SoundHapticHelper.hapticsEnabled = false;
      expect(SoundHapticHelper.hapticsEnabled, isFalse);
    });

    test('8. Audio preferences persist in SettingsRepository', () async {
      final initial = await SettingsRepository.loadSettings();
      expect(initial.soundEnabled, isTrue);
      expect(initial.soundVolume, equals(1.0));

      // Update sound settings
      const updated = SettingsState(
        soundEnabled: false,
        soundVolume: 0.6,
        hapticsEnabled: true,
      );
      await SettingsRepository.saveSettings(updated);

      final reloaded = await SettingsRepository.loadSettings();
      expect(reloaded.soundEnabled, isFalse);
      expect(reloaded.soundVolume, closeTo(0.6, 0.01));
      expect(reloaded.hapticsEnabled, isTrue);
      expect(SoundService.instance.soundEnabled, isFalse);
      expect(SoundService.instance.volume, closeTo(0.6, 0.01));
    });

    testWidgets('9. SettingsScreen displays Sound Effects switch and Volume slider', (tester) async {
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
      expect(find.text('Sound Volume'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Drag slider to 50%
      await tester.drag(find.byType(Slider), const Offset(-100, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Switch sound off
      await tester.tap(find.widgetWithText(SwitchListTile, 'Sound Effects'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Sound is disabled
      expect(SoundService.instance.soundEnabled, isFalse);
    });
  });
}
