import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/streak_date_utils.dart';

class GameStats {
  final int gamesPlayed;
  final int gamesWon;
  final int currentStreak;
  final int bestStreak;
  final Set<String> completionDates;
  final Map<String, int?> bestTimeSeconds;

  const GameStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.completionDates = const {},
    this.bestTimeSeconds = const {
      'puzzle_1': null,
      'puzzle_2': null,
      'puzzle_3': null,
    },
  });

  double get winRate =>
      gamesPlayed == 0 ? 0.0 : (gamesWon / gamesPlayed) * 100.0;

  /// Calculates the effective active streak relative to [relativeTo] (defaults to now).
  int getEffectiveStreak([DateTime? relativeTo]) =>
      StreakDateUtils.calculateCurrentStreak(completionDates, relativeTo);

  /// Calculates the best (longest) streak across all completion dates.
  int getEffectiveBestStreak() =>
      StreakDateUtils.calculateBestStreak(completionDates);

  GameStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? currentStreak,
    int? bestStreak,
    Set<String>? completionDates,
    Map<String, int?>? bestTimeSeconds,
  }) {
    return GameStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      completionDates: completionDates ?? this.completionDates,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'completionDates': (completionDates.toList()..sort()),
      'bestTimeEasy': bestTimeSeconds['puzzle_1'],
      'bestTimeMed': bestTimeSeconds['puzzle_2'],
      'bestTimeHard': bestTimeSeconds['puzzle_3'],
    };
  }

  factory GameStats.fromMap(Map<String, dynamic> map, [DateTime? relativeTo]) {
    final rawDates = map['completionDates'] as List<dynamic>?;
    final parsedDates = rawDates != null
        ? rawDates.map((e) => e.toString()).toSet()
        : <String>{};

    final int calcCurrent;
    final int calcBest;

    if (parsedDates.isNotEmpty) {
      calcCurrent = StreakDateUtils.calculateCurrentStreak(parsedDates, relativeTo);
      calcBest = max(
        map['bestStreak'] as int? ?? 0,
        StreakDateUtils.calculateBestStreak(parsedDates),
      );
    } else {
      // If legacy map had numbers but no dates, we will handle migration in StatsRepository
      calcCurrent = 0;
      calcBest = 0;
    }

    return GameStats(
      gamesPlayed: map['gamesPlayed'] as int? ?? 0,
      gamesWon: map['gamesWon'] as int? ?? 0,
      currentStreak: calcCurrent,
      bestStreak: calcBest,
      completionDates: parsedDates,
      bestTimeSeconds: {
        'puzzle_1': map['bestTimeEasy'] as int?,
        'puzzle_2': map['bestTimeMed'] as int?,
        'puzzle_3': map['bestTimeHard'] as int?,
      },
    );
  }

  String toJson() => json.encode(toMap());

  factory GameStats.fromJson(String source, [DateTime? relativeTo]) =>
      GameStats.fromMap(json.decode(source) as Map<String, dynamic>, relativeTo);
}

class StatsRepository {
  static const String _key = 'snapdog_game_stats';

  /// Loads stats from SharedPreferences and ensures streaks are calculated
  /// dynamically relative to [now] (defaults to DateTime.now()).
  ///
  /// Migrates historical data if `completionDates` is empty or missing by deriving
  /// unique calendar dates from completed puzzles in ProgressionRepository.
  static Future<GameStats> loadStats([SharedPreferences? customPrefs, DateTime? now]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      final data = prefs.getString(_key);
      GameStats stats;
      bool hadPersistedDates = false;

      if (data != null) {
        final decoded = json.decode(data) as Map<String, dynamic>;
        hadPersistedDates = decoded.containsKey('completionDates') &&
            (decoded['completionDates'] as List<dynamic>?)?.isNotEmpty == true;
        stats = GameStats.fromMap(decoded, now);
      } else {
        stats = const GameStats();
      }

      // Migration: If no completionDates are saved yet in stats, inspect progression records
      if (!hadPersistedDates) {
        final migratedDates = await _deriveCompletionDatesFromProgression(prefs);
        if (migratedDates.isNotEmpty) {
          final effectiveCurrent = StreakDateUtils.calculateCurrentStreak(migratedDates, now);
          final effectiveBest = StreakDateUtils.calculateBestStreak(migratedDates);
          stats = stats.copyWith(
            completionDates: migratedDates,
            currentStreak: effectiveCurrent,
            bestStreak: effectiveBest,
          );
          await saveStats(stats, prefs);
        }
      } else {
        // Ensure current streak is up-to-date relative to current date
        final effectiveCurrent = StreakDateUtils.calculateCurrentStreak(stats.completionDates, now);
        final effectiveBest = max(stats.bestStreak, StreakDateUtils.calculateBestStreak(stats.completionDates));
        if (effectiveCurrent != stats.currentStreak || effectiveBest != stats.bestStreak) {
          stats = stats.copyWith(
            currentStreak: effectiveCurrent,
            bestStreak: effectiveBest,
          );
        }
      }

      return stats;
    } catch (_) {
      // In headless testing or on error, return safe fallback
      return const GameStats();
    }
  }

  /// Derives unique completion dates from existing progression records without deleting history.
  static Future<Set<String>> _deriveCompletionDatesFromProgression(SharedPreferences prefs) async {
    final dates = <String>{};
    try {
      var raw = prefs.getString('snapdog_puzzle_progression_v2');
      raw ??= prefs.getString('snapdog_puzzle_progression_v1');
      if (raw != null) {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        if (decoded['puzzleProgress'] is Map) {
          final entries = decoded['puzzleProgress'] as Map<String, dynamic>;
          for (final val in entries.values) {
            if (val is Map<String, dynamic>) {
              final isCompleted = val['isCompleted'] as bool? ?? false;
              final completedAtStr = val['completedAt'] as String?;
              if (isCompleted && completedAtStr != null) {
                final dt = DateTime.tryParse(completedAtStr);
                if (dt != null) {
                  dates.add(StreakDateUtils.toCalendarDateString(dt));
                }
              }
            }
          }
        }
      }
    } catch (_) {}
    return dates;
  }

  /// Records a puzzle completion win.
  /// Deduplicates completions on the same date so multiple games on the same day
  /// only increment gamesPlayed/gamesWon, without inflating the day streak.
  static Future<GameStats> recordWin({
    required int timeSeconds,
    required String puzzleId,
    DateTime? completionTime,
    SharedPreferences? customPrefs,
  }) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      final now = completionTime ?? DateTime.now();
      final todayStr = StreakDateUtils.toCalendarDateString(now);

      final currentStats = await loadStats(prefs, now);
      final newDates = Set<String>.from(currentStats.completionDates)..add(todayStr);

      final newCurrentStreak = StreakDateUtils.calculateCurrentStreak(newDates, now);
      final newBestStreak = max(currentStats.bestStreak, StreakDateUtils.calculateBestStreak(newDates));

      final updatedBestTimes = Map<String, int?>.from(currentStats.bestTimeSeconds);
      final currentBest = updatedBestTimes[puzzleId];
      if (currentBest == null || timeSeconds < currentBest) {
        updatedBestTimes[puzzleId] = timeSeconds;
      }

      final updated = currentStats.copyWith(
        gamesPlayed: currentStats.gamesPlayed + 1,
        gamesWon: currentStats.gamesWon + 1,
        currentStreak: newCurrentStreak,
        bestStreak: newBestStreak,
        completionDates: newDates,
        bestTimeSeconds: updatedBestTimes,
      );

      await saveStats(updated, prefs);
      return updated;
    } catch (_) {
      return const GameStats();
    }
  }

  static Future<void> saveStats(GameStats stats, [SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_key, stats.toJson());
    } catch (_) {
      // Ignore in headless test environments
    }
  }
}
