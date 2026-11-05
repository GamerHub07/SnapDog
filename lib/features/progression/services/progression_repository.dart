import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progression_state.dart';
import '../models/puzzle_progress.dart';

class ProgressionRepository {
  static const String _storageKey = 'snapdog_puzzle_progression_v2';
  static const String _legacyStorageKey = 'snapdog_puzzle_progression_v1';

  static Future<ProgressionState> loadProgression([SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      var raw = prefs.getString(_storageKey);
      raw ??= prefs.getString(_legacyStorageKey);

      if (raw != null) {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        final map = <String, PuzzleProgress>{};
        if (decoded['puzzleProgress'] is Map) {
          final entries = decoded['puzzleProgress'] as Map<String, dynamic>;
          for (final e in entries.entries) {
            map[e.key] = PuzzleProgress.fromMap(e.value as Map<String, dynamic>);
          }
        }

        InProgressPuzzleState? inProgress;
        if (decoded['inProgressState'] is Map) {
          try {
            inProgress = InProgressPuzzleState.fromMap(
              decoded['inProgressState'] as Map<String, dynamic>,
            );
          } catch (_) {}
        }

        final highest = (decoded['highestUnlockedLevel'] as int?) ?? 1;
        final current = (decoded['currentLevel'] as int?) ?? highest;

        return ProgressionState(
          puzzleProgress: map,
          highestUnlockedLevel: highest,
          currentLevel: current,
          inProgressState: inProgress,
          lastPlayedPuzzleId: decoded['lastPlayedPuzzleId'] as String?,
        );
      }
    } catch (_) {}
    return const ProgressionState();
  }

  static Future<void> saveProgression(ProgressionState state, [SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      final map = {
        'highestUnlockedLevel': state.highestUnlockedLevel,
        'currentLevel': state.currentLevel,
        'lastPlayedPuzzleId': state.lastPlayedPuzzleId,
        'inProgressState': state.inProgressState?.toMap(),
        'puzzleProgress': state.puzzleProgress.map(
          (k, v) => MapEntry(k, v.toMap()),
        ),
      };
      await prefs.setString(_storageKey, json.encode(map));
    } catch (_) {}
  }
}
