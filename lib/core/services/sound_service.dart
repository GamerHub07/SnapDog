import 'dart:io' show Platform;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Dedicated sound service handling gameplay sound effects for SnapDog.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  AudioPlayer? _player;
  bool _soundEnabled = true;
  double _volume = 1.0;

  // Sound asset constants
  static const String crossSoundAsset = 'audio/cross_pop.wav';
  static const String correctPlacementSoundAsset = 'audio/dog_chime.wav';
  static const String wrongPlacementSoundAsset = 'audio/wrong_bloop.wav';
  static const String undoSoundAsset = 'audio/undo_pop.wav';
  static const String hintSoundAsset = 'audio/hint_sparkle.wav';
  static const String completionSoundAsset = 'audio/puzzle_complete.wav';
  static const String buttonSoundAsset = 'audio/button_click.wav';

  // Testing hooks & verification
  String? lastPlayedSoundAsset;
  int playCount = 0;

  bool get soundEnabled => _soundEnabled;
  double get volume => _volume;

  bool get isTestEnvironment => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  void init({bool soundEnabled = true, double volume = 1.0}) {
    _soundEnabled = soundEnabled;
    _volume = volume.clamp(0.0, 1.0);
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    if (!isTestEnvironment || _player != null) {
      try {
        _player?.setVolume(_volume);
      } catch (_) {}
    }
  }

  AudioPlayer _getOrCreatePlayer() {
    return _player ??= AudioPlayer();
  }

  /// Sets a custom [AudioPlayer] instance (useful for unit testing or mocking).
  void setAudioPlayerForTesting(AudioPlayer? player) {
    _player = player;
  }

  void resetTestingState() {
    lastPlayedSoundAsset = null;
    playCount = 0;
  }

  Future<void> _playSound(String assetRelativePath) async {
    if (!_soundEnabled || _volume <= 0.0) return;

    lastPlayedSoundAsset = assetRelativePath;
    playCount++;

    // In unit test environment without a custom mocked AudioPlayer, avoid calling missing platform channels
    if (isTestEnvironment && _player == null) {
      return;
    }

    try {
      final player = _getOrCreatePlayer();
      // Stop previous playback to avoid overlapping distortion
      await player.stop();
      await player.setVolume(_volume);
      await player.play(AssetSource(assetRelativePath));
    } catch (_) {
      // Gracefully ignore missing platform implementation during headless runs
    }
  }

  /// 1. Cross marking: soft pop/click
  Future<void> playCrossSound() => _playSound(crossSoundAsset);

  /// 2. Correct dog placement: pleasant confirmation chime
  Future<void> playCorrectPlacementSound() => _playSound(correctPlacementSoundAsset);

  /// 3. Wrong dog placement: gentle descending bloop
  Future<void> playWrongPlacementSound() => _playSound(wrongPlacementSoundAsset);

  /// 4. Dog removal / undo: soft reverse pop
  Future<void> playUndoSound() => _playSound(undoSoundAsset);

  /// 5. Hint usage: magical sparkle sound
  Future<void> playHintSound() => _playSound(hintSoundAsset);

  /// 6. Puzzle completion: cheerful celebration sound
  Future<void> playCompletionSound() => _playSound(completionSoundAsset);

  /// 7. Button interactions: subtle UI click
  Future<void> playButtonSound() => _playSound(buttonSoundAsset);

  void dispose() {
    try {
      _player?.dispose();
    } catch (_) {}
    _player = null;
  }
}
