import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/core/utils/sound_haptic_helper.dart';

class SettingsState {
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool isDarkMode;
  final bool hasCompletedOnboarding;

  const SettingsState({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.isDarkMode = false,
    this.hasCompletedOnboarding = false,
  });

  String get themeLabel => isDarkMode ? 'Dark Cozy' : 'Warm Cream (Default)';

  SettingsState copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? isDarkMode,
    bool? hasCompletedOnboarding,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

class SettingsRepository {
  static const _soundKey = 'snapdog_sound';
  static const _hapticsKey = 'snapdog_haptics';
  static const _darkModeKey = 'snapdog_dark_mode';
  static const _onboardingKey = 'snapdog_onboarding_completed';

  static Future<SettingsState> loadSettings([SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      final sound = prefs.getBool(_soundKey) ?? true;
      final haptics = prefs.getBool(_hapticsKey) ?? true;
      final darkMode = prefs.getBool(_darkModeKey) ?? false;
      final onboarding = prefs.getBool(_onboardingKey) ?? false;

      SoundHapticHelper.soundEnabled = sound;
      SoundHapticHelper.hapticsEnabled = haptics;

      return SettingsState(
        soundEnabled: sound,
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
      await prefs.setBool(_hapticsKey, settings.hapticsEnabled);
      await prefs.setBool(_darkModeKey, settings.isDarkMode);
      await prefs.setBool(_onboardingKey, settings.hasCompletedOnboarding);

      SoundHapticHelper.soundEnabled = settings.soundEnabled;
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
      await prefs.remove('snapdog_puzzle_progression_v1');
      await prefs.remove('snapdog_daily_challenge_v1');
      await prefs.remove('snapdog_game_stats');
      // Keep user preferences (sound, haptics, theme, onboarding) intact unless desired
    } catch (_) {}
  }
}
