import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../daily_challenge/providers/daily_challenge_provider.dart';
import '../../progression/providers/progression_provider.dart';
import '../models/settings_state.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<SettingsState> {
  bool _disposed = false;
  Future<void>? _initFuture;

  @override
  SettingsState build() {
    ref.onDispose(() {
      _disposed = true;
    });

    _initFuture = _loadInitialSettings();
    return const SettingsState();
  }

  Future<void> ensureInitialized() async {
    await _initFuture;
  }

  Future<void> _loadInitialSettings() async {
    final loaded = await SettingsRepository.loadSettings();
    if (!_disposed) {
      state = loaded;
    }
  }

  Future<void> toggleSound(bool enabled) async {
    await _initFuture;
    final updated = state.copyWith(soundEnabled: enabled);
    state = updated;
    await SettingsRepository.saveSettings(updated);
  }

  Future<void> setSoundVolume(double volume) async {
    await _initFuture;
    final updated = state.copyWith(soundVolume: volume.clamp(0.0, 1.0));
    state = updated;
    await SettingsRepository.saveSettings(updated);
  }

  Future<void> toggleHaptics(bool enabled) async {
    await _initFuture;
    final updated = state.copyWith(hapticsEnabled: enabled);
    state = updated;
    await SettingsRepository.saveSettings(updated);
  }

  Future<void> toggleDarkMode(bool isDark) async {
    await _initFuture;
    final updated = state.copyWith(isDarkMode: isDark);
    state = updated;
    await SettingsRepository.saveSettings(updated);
  }

  Future<void> completeOnboarding() async {
    await _initFuture;
    final updated = state.copyWith(hasCompletedOnboarding: true);
    state = updated;
    await SettingsRepository.saveSettings(updated);
  }

  /// Resets all player progress, completed puzzles, streaks, and game stats,
  /// then reloads the providers so the game returns to its fresh state.
  Future<void> resetAllProgress() async {
    await _initFuture;
    await SettingsRepository.resetAllGameData();
    // Invalidate progression and daily challenge so they reload their initial empty state
    ref.invalidate(progressionProvider);
    ref.invalidate(dailyChallengeProvider);
  }
}
