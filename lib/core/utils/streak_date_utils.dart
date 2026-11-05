/// Utility class for timezone-safe calendar date manipulation and streak calculations.
///
/// Rules:
/// 1. Tracks unique local calendar dates ('YYYY-MM-DD').
/// 2. Multiple completions on the same date count as only ONE active day.
/// 3. Current streak:
///    - If completed today, count consecutive completed dates backwards from today.
///    - If completed yesterday (but not today), count backwards from yesterday.
///    - If completed neither today nor yesterday, current streak is 0.
///    - Missing a calendar day breaks the streak.
/// 4. Best streak:
///    - Maximum consecutive sequence of unique calendar dates ever recorded.
/// 5. Safely handles month transitions, year transitions, and leap years.
class StreakDateUtils {
  StreakDateUtils._();

  /// Converts a [DateTime] into a local calendar date string 'YYYY-MM-DD'.
  static String toCalendarDateString(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parses a 'YYYY-MM-DD' calendar date string back to local midnight [DateTime].
  static DateTime parseCalendarDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  /// Normalizes a [DateTime] to local calendar date at midnight (00:00:00).
  static DateTime normalizeDate(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Returns the calendar date immediately preceding [date].
  /// Dart's DateTime constructor automatically handles month/year rollbacks and leap years.
  static DateTime previousDay(DateTime date) {
    final norm = normalizeDate(date);
    return DateTime(norm.year, norm.month, norm.day - 1);
  }

  /// Returns the calendar date immediately following [date].
  static DateTime nextDay(DateTime date) {
    final norm = normalizeDate(date);
    return DateTime(norm.year, norm.month, norm.day + 1);
  }

  /// Checks if two [DateTime] instances fall on the exact same local calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  /// Calculates the current active streak from a collection of completion dates.
  ///
  /// [completionDates] contains 'YYYY-MM-DD' date strings.
  /// [relativeTo] is the reference date (defaults to `DateTime.now()`).
  static int calculateCurrentStreak(
    Set<String> completionDates, [
    DateTime? relativeTo,
  ]) {
    if (completionDates.isEmpty) return 0;

    final today = normalizeDate(relativeTo ?? DateTime.now());
    final todayStr = toCalendarDateString(today);

    final yesterday = previousDay(today);
    final yesterdayStr = toCalendarDateString(yesterday);

    DateTime checkDate;
    if (completionDates.contains(todayStr)) {
      // Completed today -> count backwards from today
      checkDate = today;
    } else if (completionDates.contains(yesterdayStr)) {
      // Completed yesterday but not today -> count backwards from yesterday
      checkDate = yesterday;
    } else {
      // Completed neither today nor yesterday -> streak broken
      return 0;
    }

    int streak = 0;
    while (true) {
      final key = toCalendarDateString(checkDate);
      if (completionDates.contains(key)) {
        streak++;
        checkDate = previousDay(checkDate);
      } else {
        break;
      }
    }
    return streak;
  }

  /// Calculates the longest (best) streak of consecutive calendar days
  /// in the given [completionDates].
  static int calculateBestStreak(Set<String> completionDates) {
    if (completionDates.isEmpty) return 0;

    final sortedDates = completionDates
        .map(parseCalendarDate)
        .toList()
      ..sort();

    int maxStreak = 1;
    int currentRun = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final prev = sortedDates[i - 1];
      final curr = sortedDates[i];

      final expected = nextDay(prev);
      if (isSameDay(curr, expected)) {
        currentRun++;
        if (currentRun > maxStreak) {
          maxStreak = currentRun;
        }
      } else if (!isSameDay(curr, prev)) {
        // Gap of at least one calendar day
        currentRun = 1;
      }
    }

    return maxStreak;
  }
}
