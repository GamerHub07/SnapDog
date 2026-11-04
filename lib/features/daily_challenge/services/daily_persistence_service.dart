import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_challenge_record.dart';
import '../models/daily_challenge_state.dart';

class DailyPersistenceService {
  static const String _storageKey = 'snapdog_daily_challenge_v1';

  static Future<DailyChallengeState> loadDailyState([SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final decoded = json.decode(raw) as Map<String, dynamic>;

        final historyMap = <String, DailyChallengeRecord>{};
        if (decoded['history'] is Map) {
          final entries = decoded['history'] as Map<String, dynamic>;
          for (final e in entries.entries) {
            historyMap[e.key] = DailyChallengeRecord.fromMap(e.value as Map<String, dynamic>);
          }
        }

        final rewards = <String>{};
        if (decoded['earnedRewardIds'] is List) {
          for (final id in decoded['earnedRewardIds'] as List) {
            rewards.add(id.toString());
          }
        }

        return DailyChallengeState(
          currentStreak: decoded['currentStreak'] as int? ?? 0,
          longestStreak: decoded['longestStreak'] as int? ?? 0,
          lastCompletedDateKey: decoded['lastCompletedDateKey'] as String?,
          history: historyMap,
          earnedRewardIds: rewards,
        );
      }
    } catch (_) {}
    return const DailyChallengeState();
  }

  static Future<void> saveDailyState(DailyChallengeState state, [SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      final map = {
        'currentStreak': state.currentStreak,
        'longestStreak': state.longestStreak,
        'lastCompletedDateKey': state.lastCompletedDateKey,
        'earnedRewardIds': state.earnedRewardIds.toList(),
        'history': state.history.map(
          (k, v) => MapEntry(k, v.toMap()),
        ),
      };
      await prefs.setString(_storageKey, json.encode(map));
    } catch (_) {}
  }
}
