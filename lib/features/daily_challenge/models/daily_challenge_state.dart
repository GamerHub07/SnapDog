import 'daily_challenge_record.dart';

class DailyChallengeState {
  final int currentStreak;
  final int longestStreak;
  final String? lastCompletedDateKey;
  final Map<String, DailyChallengeRecord> history;
  final Set<String> earnedRewardIds;

  const DailyChallengeState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDateKey,
    this.history = const {},
    this.earnedRewardIds = const {},
  });

  /// Normalizes a [DateTime] to calendar date key 'YYYY-MM-DD'.
  static String formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parses 'YYYY-MM-DD' back to midnight [DateTime].
  static DateTime parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  /// Normalizes a [DateTime] to local midnight (00:00:00).
  static DateTime normalizeDate(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  /// Calculates the effective streak active on [today].
  /// If the challenge was completed today or yesterday, streak is alive.
  /// If yesterday was missed and challenge not completed today, returns 0.
  int getEffectiveStreak(DateTime today) {
    if (lastCompletedDateKey == null || currentStreak == 0) return 0;

    final todayKey = formatDateKey(today);
    if (lastCompletedDateKey == todayKey) {
      return currentStreak;
    }

    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final yesterdayKey = formatDateKey(yesterday);
    if (lastCompletedDateKey == yesterdayKey) {
      return currentStreak;
    }

    return 0; // Missed yesterday or earlier
  }

  /// Checks if a challenge has been successfully completed on [date].
  bool isCompletedOn(DateTime date) {
    final key = formatDateKey(date);
    return history.containsKey(key);
  }

  /// Retrieves the completion record for [date], if any.
  DailyChallengeRecord? getRecord(DateTime date) {
    final key = formatDateKey(date);
    return history[key];
  }

  /// Checks if a reward milestone has been earned.
  bool isRewardEarned(String rewardId) => earnedRewardIds.contains(rewardId);

  DailyChallengeState copyWith({
    int? currentStreak,
    int? longestStreak,
    String? lastCompletedDateKey,
    Map<String, DailyChallengeRecord>? history,
    Set<String>? earnedRewardIds,
  }) {
    return DailyChallengeState(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDateKey: lastCompletedDateKey ?? this.lastCompletedDateKey,
      history: history ?? this.history,
      earnedRewardIds: earnedRewardIds ?? this.earnedRewardIds,
    );
  }
}
