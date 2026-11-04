import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameStats {
  final int gamesPlayed;
  final int gamesWon;
  final int currentStreak;
  final int bestStreak;
  final Map<String, int?> bestTimeSeconds;

  const GameStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.bestTimeSeconds = const {
      'puzzle_1': null,
      'puzzle_2': null,
      'puzzle_3': null,
    },
  });

  double get winRate =>
      gamesPlayed == 0 ? 0.0 : (gamesWon / gamesPlayed) * 100.0;

  GameStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? currentStreak,
    int? bestStreak,
    Map<String, int?>? bestTimeSeconds,
  }) {
    return GameStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'bestTimeEasy': bestTimeSeconds['puzzle_1'],
      'bestTimeMed': bestTimeSeconds['puzzle_2'],
      'bestTimeHard': bestTimeSeconds['puzzle_3'],
    };
  }

  factory GameStats.fromMap(Map<String, dynamic> map) {
    return GameStats(
      gamesPlayed: map['gamesPlayed'] as int? ?? 0,
      gamesWon: map['gamesWon'] as int? ?? 0,
      currentStreak: map['currentStreak'] as int? ?? 0,
      bestStreak: map['bestStreak'] as int? ?? 0,
      bestTimeSeconds: {
        'puzzle_1': map['bestTimeEasy'] as int?,
        'puzzle_2': map['bestTimeMed'] as int?,
        'puzzle_3': map['bestTimeHard'] as int?,
      },
    );
  }

  String toJson() => json.encode(toMap());

  factory GameStats.fromJson(String source) =>
      GameStats.fromMap(json.decode(source) as Map<String, dynamic>);
}

class StatsRepository {
  static const String _key = 'snapdog_game_stats';

  static Future<GameStats> loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_key);
      if (data != null) {
        return GameStats.fromJson(data);
      }
    } catch (_) {
      // Ignore and return defaults
    }
    return const GameStats();
  }

  static Future<void> saveStats(GameStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, stats.toJson());
    } catch (_) {
      // Ignore
    }
  }
}
