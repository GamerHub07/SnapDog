import 'dart:convert';
import 'dart:math';
import '../models/puzzle.dart';

/// Manages mixed difficulty progression for SnapDog levels.
///
/// Ensures a balanced casual puzzle experience:
/// - Target distribution over a rolling window: ~50% EASY, ~35% MEDIUM, ~15% HARD.
/// - Hard rule: Max 1 consecutive HARD (never two HARD puzzles back-to-back).
/// - Hard rule: Max 3 consecutive EASY (never more than three EASY puzzles in a row).
/// - No static repeating 3-level or 6-level pattern.
/// - Deterministic for identical history and level numbers.
/// - Persistable across app restarts.
class DifficultyScheduler {
  static const double targetRatioEasy = 0.50;
  static const double targetRatioMedium = 0.35;
  static const double targetRatioHard = 0.15;
  static const int rollingWindowSize = 20;

  final Map<int, Difficulty> _scheduledLevels = {};

  DifficultyScheduler();

  DifficultyScheduler.fromMap(Map<int, Difficulty> saved) {
    _scheduledLevels.addAll(saved);
  }

  /// Returns the scheduled difficulty for [levelNumber].
  ///
  /// For handcrafted levels (1..9), returns their canonical difficulty.
  /// For procedural levels (10+), consults previously recorded scheduling or
  /// deterministically computes the next difficulty from recent history.
  Difficulty getDifficultyForLevel(int levelNumber) {
    if (levelNumber <= 0) levelNumber = 1;

    // Handcrafted levels 1..9 retain fixed difficulties
    if (levelNumber <= 3) return Difficulty.easy;
    if (levelNumber <= 6) return Difficulty.medium;
    if (levelNumber <= 9) return Difficulty.hard;

    // Check if already scheduled and persisted
    if (_scheduledLevels.containsKey(levelNumber)) {
      return _scheduledLevels[levelNumber]!;
    }

    // Collect historical sequence up to levelNumber - 1
    final history = <Difficulty>[];
    for (int l = 10; l < levelNumber; l++) {
      if (_scheduledLevels.containsKey(l)) {
        history.add(_scheduledLevels[l]!);
      }
    }

    final diff = scheduleNext(levelNumber, history);
    _scheduledLevels[levelNumber] = diff;
    return diff;
  }

  /// Records a confirmed or generated level's difficulty.
  void recordLevelDifficulty(int levelNumber, Difficulty difficulty) {
    _scheduledLevels[levelNumber] = difficulty;
  }

  /// Pure deterministic scheduling function given [levelNumber] and recent [history].
  static Difficulty scheduleNext(int levelNumber, List<Difficulty> history) {
    if (levelNumber <= 3) return Difficulty.easy;
    if (levelNumber <= 6) return Difficulty.medium;
    if (levelNumber <= 9) return Difficulty.hard;

    // Rolling window of recent history
    final windowStart = max(0, history.length - rollingWindowSize);
    final window = history.sublist(windowStart);

    // Evaluate constraints:
    // 1. Max consecutive HARD is 1: If immediately preceding level was HARD, HARD is disallowed.
    final allowHard = window.isEmpty || window.last != Difficulty.hard;

    // 2. Max consecutive EASY is 3: If previous 3 levels were all EASY, EASY is disallowed.
    bool allowEasy = true;
    if (window.length >= 3) {
      if (window[window.length - 1] == Difficulty.easy &&
          window[window.length - 2] == Difficulty.easy &&
          window[window.length - 3] == Difficulty.easy) {
        allowEasy = false;
      }
    }

    // Calculate current rolling counts
    int countEasy = 0;
    int countMed = 0;
    int countHard = 0;
    for (final d in window) {
      switch (d) {
        case Difficulty.easy:
          countEasy++;
          break;
        case Difficulty.medium:
          countMed++;
          break;
        case Difficulty.hard:
          countHard++;
          break;
      }
    }

    final total = max(1, window.length);
    final freqEasy = countEasy / total;
    final freqMed = countMed / total;
    final freqHard = countHard / total;

    // Calculate deficits (target - current)
    final deficitEasy = targetRatioEasy - freqEasy;
    final deficitMed = targetRatioMedium - freqMed;
    final deficitHard = targetRatioHard - freqHard;

    // Calculate dynamic weights
    double weightEasy = allowEasy ? max(0.05, targetRatioEasy + 2.0 * deficitEasy) : 0.0;
    double weightMed = max(0.05, targetRatioMedium + 2.0 * deficitMed);
    double weightHard = allowHard ? max(0.02, targetRatioHard + 2.0 * deficitHard) : 0.0;

    // Ensure at least one option is positive
    final totalWeight = weightEasy + weightMed + weightHard;
    assert(totalWeight > 0.0);

    // Deterministic selection based on levelNumber and history hash
    final seed = _hashLevelAndHistory(levelNumber, history);
    final rng = Random(seed);
    final pick = rng.nextDouble() * totalWeight;

    if (pick < weightEasy) {
      return Difficulty.easy;
    } else if (pick < weightEasy + weightMed) {
      return Difficulty.medium;
    } else {
      return Difficulty.hard;
    }
  }

  static int _hashLevelAndHistory(int levelNumber, List<Difficulty> history) {
    int h = levelNumber * 1000003;
    final start = max(0, history.length - 10);
    for (int i = start; i < history.length; i++) {
      h = (h * 31 + history[i].index + 1) & 0x7FFFFFFF;
    }
    return h;
  }

  /// Serializes scheduling map to JSON string.
  String toJson() {
    final map = <String, String>{};
    for (final entry in _scheduledLevels.entries) {
      map[entry.key.toString()] = entry.value.name;
    }
    return json.encode(map);
  }

  /// Deserializes scheduling map from JSON string.
  factory DifficultyScheduler.fromJson(String jsonStr) {
    try {
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      final map = <int, Difficulty>{};
      for (final entry in decoded.entries) {
        final lvl = int.tryParse(entry.key);
        final diff = Difficulty.values.where((d) => d.name == entry.value).firstOrNull;
        if (lvl != null && diff != null) {
          map[lvl] = diff;
        }
      }
      return DifficultyScheduler.fromMap(map);
    } catch (_) {
      return DifficultyScheduler();
    }
  }

  /// Resets internal scheduled history (useful in tests).
  void clear() {
    _scheduledLevels.clear();
  }
}
