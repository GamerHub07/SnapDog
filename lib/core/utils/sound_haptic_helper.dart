import 'package:flutter/services.dart';
import '../services/sound_service.dart';

/// Helper for haptics and game audio cues throughout SnapDog.
class SoundHapticHelper {
  SoundHapticHelper._();

  static bool hapticsEnabled = true;

  static bool get soundEnabled => SoundService.instance.soundEnabled;
  static set soundEnabled(bool value) => SoundService.instance.setSoundEnabled(value);

  // --- Sound Effects & Haptics ---

  /// Played on interactive button taps
  static void buttonClick() {
    SoundService.instance.playButtonSound();
  }

  /// Played when placing a dog correctly on the board
  static void dogPlace() {
    SoundService.instance.playCorrectPlacementSound();
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Played when marking or unmarking a cross (×)
  static void crossMark() {
    SoundService.instance.playCrossSound();
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Played when removing a dog from the board
  static void dogRemove() {
    SoundService.instance.playUndoSound();
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Played on invalid placement or rule conflict
  static void invalidPlacement() {
    SoundService.instance.playWrongPlacementSound();
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Played when requesting a hint
  static void hintUsed() {
    SoundService.instance.playHintSound();
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Played on puzzle completion victory
  static void puzzleCompleted() {
    SoundService.instance.playCompletionSound();
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Played on undo action
  static void undoAction() {
    SoundService.instance.playUndoSound();
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  // --- Backward-Compatible Haptic Aliases ---
  static void lightTap() => crossMark();
  static void selectionClick() => undoAction();
  static void errorVibrate() => invalidPlacement();
  static void successVibrate() => puzzleCompleted();
}
