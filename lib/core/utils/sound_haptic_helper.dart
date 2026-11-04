import 'package:flutter/services.dart';

/// Helper for haptics and game audio cues throughout SnapDog.
class SoundHapticHelper {
  SoundHapticHelper._();

  static bool hapticsEnabled = true;
  static bool soundEnabled = true;

  // --- Sound Effects ---

  /// Played on interactive button taps
  static void buttonClick() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Played when placing a dog on the board
  static void dogPlace() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Played when marking or unmarking a cross (×)
  static void crossMark() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Played when removing a dog from the board
  static void dogRemove() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Played on invalid placement or rule conflict
  static void invalidPlacement() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Played when requesting a hint
  static void hintUsed() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Played on puzzle completion victory
  static void puzzleCompleted() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Played on undo action
  static void undoAction() {
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
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
