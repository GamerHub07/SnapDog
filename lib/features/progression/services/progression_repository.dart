import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progression_state.dart';
import '../models/puzzle_progress.dart';

class ProgressionRepository {
  static const String _storageKey = 'snapdog_puzzle_progression_v1';

  static Future<ProgressionState> loadProgression([SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        final map = <String, PuzzleProgress>{};
        if (decoded['puzzleProgress'] is Map) {
          final entries = decoded['puzzleProgress'] as Map<String, dynamic>;
          for (final e in entries.entries) {
            map[e.key] = PuzzleProgress.fromMap(e.value as Map<String, dynamic>);
          }
        }
        return ProgressionState(
          puzzleProgress: map,
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
        'lastPlayedPuzzleId': state.lastPlayedPuzzleId,
        'puzzleProgress': state.puzzleProgress.map(
          (k, v) => MapEntry(k, v.toMap()),
        ),
      };
      await prefs.setString(_storageKey, json.encode(map));
    } catch (_) {}
  }
}
