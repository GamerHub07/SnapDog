import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/core/services/sound_service.dart';
import 'package:snapdog/core/utils/sound_haptic_helper.dart';

class SettingsState {
  final bool soundEnabled;
  final double soundVolume; // 0.0 to 1.0
  final bool hapticsEnabled;
  final bool isDarkMode;
  final bool hasCompletedOnboarding;

  const SettingsState({
    this.soundEnabled = true,
    this.soundVolume = 1.0,
    this.hapticsEnabled = true,
    this.isDarkMode = false,
    this.hasCompletedOnboarding = false,
  });

  String get themeLabel => isDarkMode ? 'Dark Cozy' : 'Warm Cream (Default)';

  SettingsState copyWith({
    bool? soundEnabled,
    double? soundVolume,
    bool? hapticsEnabled,
    bool? isDarkMode,
    bool? hasCompletedOnboarding,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

class SettingsRepository {
  static const _soundKey = 'snapdog_sound';
  static const _soundVolumeKey = 'snapdog_sound_volume';
  static const _hapticsKey = 'snapdog_haptics';
  static const _darkModeKey = 'snapdog_dark_mode';
  static const _onboardingKey = 'snapdog_onboarding_completed';

  static Future<SettingsState> loadSettings([SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      final sound = prefs.getBool(_soundKey) ?? true;
      final soundVolume = prefs.getDouble(_soundVolumeKey) ?? 1.0;
      final haptics = prefs.getBool(_hapticsKey) ?? true;
      final darkMode = prefs.getBool(_darkModeKey) ?? false;
      final onboarding = prefs.getBool(_onboardingKey) ?? false;

      SoundService.instance.init(soundEnabled: sound, volume: soundVolume);
      SoundHapticHelper.hapticsEnabled = haptics;

      return SettingsState(
        soundEnabled: sound,
        soundVolume: soundVolume,
        hapticsEnabled: haptics,
        isDarkMode: darkMode,
        hasCompletedOnboarding: onboarding,
      );
    } catch (_) {
      return const SettingsState();
    }
  }

  static Future<void> saveSettings(SettingsState settings, [SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      await prefs.setBool(_soundKey, settings.soundEnabled);
      await prefs.setDouble(_soundVolumeKey, settings.soundVolume);
      await prefs.setBool(_hapticsKey, settings.hapticsEnabled);
      await prefs.setBool(_darkModeKey, settings.isDarkMode);
      await prefs.setBool(_onboardingKey, settings.hasCompletedOnboarding);

      SoundService.instance.setSoundEnabled(settings.soundEnabled);
      SoundService.instance.setVolume(settings.soundVolume);
      SoundHapticHelper.hapticsEnabled = settings.hapticsEnabled;
    } catch (_) {}
  }

  static Future<void> setOnboardingCompleted([SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } catch (_) {}
  }

  static Future<bool> hasCompletedOnboarding([SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> resetAllGameData([SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      // Clear game progression, daily challenge, and stats keys
      await prefs.remove('snapdog_puzzle_progression_v2');
      await prefs.remove('snapdog_puzzle_progression_v1');
      await prefs.remove('snapdog_daily_challenge_v1');
      await prefs.remove('snapdog_game_stats');
      await prefs.remove('snapdog_generated_puzzles_v1');
      await prefs.remove('snapdog_difficulty_scheduler_v1');
      await prefs.remove('snapdog_fingerprints_v1');
      // Keep user preferences (sound, volume, haptics, theme, onboarding) intact unless desired
    } catch (_) {}
  }
}
