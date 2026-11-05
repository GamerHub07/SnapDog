import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/core/utils/streak_date_utils.dart';
import 'package:snapdog/features/statistics/models/game_stats.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SnapDog Streak Statistics & Calculation Tests', () {
    // 1. One game completed today -> 1-day streak
    test('1. One game completed today -> 1-day streak', () {
      final today = DateTime(2026, 11, 5, 14, 30);
      final completionDates = {
        StreakDateUtils.toCalendarDateString(today),
      };

      final streak = StreakDateUtils.calculateCurrentStreak(completionDates, today);
      expect(streak, equals(1));
    });

    // 2. 40 games completed today -> 1-day streak
    test('2. 40 games completed today -> 1-day streak', () async {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime(2026, 11, 5, 10, 0);

      // Simulate completing 40 games on the same date at different times
      for (int i = 0; i < 40; i++) {
        final time = today.add(Duration(minutes: i * 15));
        await StatsRepository.recordWin(
          timeSeconds: 45 + i,
          puzzleId: 'puzzle_${i + 1}',
          completionTime: time,
          customPrefs: prefs,
        );
      }

      final stats = await StatsRepository.loadStats(prefs, today);
      expect(stats.gamesPlayed, equals(40));
      expect(stats.gamesWon, equals(40));
      expect(stats.completionDates.length, equals(1));
      expect(stats.currentStreak, equals(1), reason: '40 games on same date must result in 1-day streak');
      expect(stats.bestStreak, equals(1));
    });

    // 3. Games completed on three consecutive days -> 3-day streak
    test('3. Games completed on three consecutive days -> 3-day streak', () {
      final day1 = DateTime(2026, 11, 3, 10, 0);
      final day2 = DateTime(2026, 11, 4, 11, 0);
      final day3 = DateTime(2026, 11, 5, 12, 0);

      final dates = {
        StreakDateUtils.toCalendarDateString(day1),
        StreakDateUtils.toCalendarDateString(day2),
        StreakDateUtils.toCalendarDateString(day3),
      };

      final streak = StreakDateUtils.calculateCurrentStreak(dates, day3);
      expect(streak, equals(3));
    });

    // 4. Multiple games on each of three consecutive days -> 3-day streak
    test('4. Multiple games on each of three consecutive days -> 3-day streak', () async {
      final prefs = await SharedPreferences.getInstance();
      final baseDate = DateTime(2026, 11, 3);

      for (int dayOffset = 0; dayOffset < 3; dayOffset++) {
        final date = baseDate.add(Duration(days: dayOffset));
        // Play 5 games each day
        for (int game = 0; game < 5; game++) {
          await StatsRepository.recordWin(
            timeSeconds: 60,
            puzzleId: 'puzzle_$game',
            completionTime: date.add(Duration(hours: 8 + game * 2)),
            customPrefs: prefs,
          );
        }
      }

      final today = baseDate.add(const Duration(days: 2));
      final stats = await StatsRepository.loadStats(prefs, today);

      expect(stats.gamesPlayed, equals(15));
      expect(stats.gamesWon, equals(15));
      expect(stats.completionDates.length, equals(3));
      expect(stats.currentStreak, equals(3));
      expect(stats.bestStreak, equals(3));
    });

    // 5. Today and yesterday completed -> 2-day streak
    test('5. Today and yesterday completed -> 2-day streak', () {
      final today = DateTime(2026, 11, 5, 9, 0);
      final yesterday = DateTime(2026, 11, 4, 18, 0);

      final dates = {
        StreakDateUtils.toCalendarDateString(yesterday),
        StreakDateUtils.toCalendarDateString(today),
      };

      final streak = StreakDateUtils.calculateCurrentStreak(dates, today);
      expect(streak, equals(2));
    });

    // 6. Today skipped but yesterday completed -> streak calculated from yesterday
    test('6. Today skipped but yesterday completed -> streak calculated from yesterday', () {
      final day1 = DateTime(2026, 11, 2, 10, 0);
      final day2 = DateTime(2026, 11, 3, 10, 0);
      final yesterday = DateTime(2026, 11, 4, 10, 0);
      final today = DateTime(2026, 11, 5, 12, 0); // Not completed today

      final dates = {
        StreakDateUtils.toCalendarDateString(day1),
        StreakDateUtils.toCalendarDateString(day2),
        StreakDateUtils.toCalendarDateString(yesterday),
      };

      // Today has not been played, but yesterday was -> streak is alive from yesterday
      final streak = StreakDateUtils.calculateCurrentStreak(dates, today);
      expect(streak, equals(3));
    });

    // 7. Both today and yesterday skipped -> 0-day current streak
    test('7. Both today and yesterday skipped -> 0-day current streak', () {
      final day1 = DateTime(2026, 11, 1, 10, 0);
      final day2 = DateTime(2026, 11, 2, 10, 0);
      final today = DateTime(2026, 11, 5, 12, 0); // Skipped Nov 3 and Nov 4

      final dates = {
        StreakDateUtils.toCalendarDateString(day1),
        StreakDateUtils.toCalendarDateString(day2),
      };

      final streak = StreakDateUtils.calculateCurrentStreak(dates, today);
      expect(streak, equals(0));
    });

    // 8. A missing day breaks the streak
    test('8. A missing day breaks the streak', () {
      final day1 = DateTime(2026, 11, 1);
      final day2 = DateTime(2026, 11, 2);
      // Day 3 (Nov 3) skipped!
      final day4 = DateTime(2026, 11, 4);
      final today = DateTime(2026, 11, 5);

      final dates = {
        StreakDateUtils.toCalendarDateString(day1),
        StreakDateUtils.toCalendarDateString(day2),
        StreakDateUtils.toCalendarDateString(day4),
        StreakDateUtils.toCalendarDateString(today),
      };

      // Starting from today and counting backwards: Nov 5 (1), Nov 4 (2), Nov 3 missing -> breaks!
      final currentStreak = StreakDateUtils.calculateCurrentStreak(dates, today);
      expect(currentStreak, equals(2));

      // Best streak was 2 (either Nov 1-2 or Nov 4-5)
      final bestStreak = StreakDateUtils.calculateBestStreak(dates);
      expect(bestStreak, equals(2));
    });

    // 9. Month and year boundaries
    test('9. Month and year boundaries', () {
      // Month boundary: Oct 31 to Nov 1
      final oct31 = DateTime(2026, 10, 31, 23, 0);
      final nov1 = DateTime(2026, 11, 1, 8, 0);
      final datesMonth = {
        StreakDateUtils.toCalendarDateString(oct31),
        StreakDateUtils.toCalendarDateString(nov1),
      };
      expect(StreakDateUtils.calculateCurrentStreak(datesMonth, nov1), equals(2));

      // Year boundary: Dec 31, 2025 to Jan 1, 2026
      final dec31 = DateTime(2025, 12, 31, 22, 0);
      final jan1 = DateTime(2026, 1, 1, 10, 0);
      final datesYear = {
        StreakDateUtils.toCalendarDateString(dec31),
        StreakDateUtils.toCalendarDateString(jan1),
      };
      expect(StreakDateUtils.calculateCurrentStreak(datesYear, jan1), equals(2));
      expect(StreakDateUtils.calculateBestStreak(datesYear), equals(2));
    });

    // 10. Leap-year dates
    test('10. Leap-year dates', () {
      // Leap year 2024: Feb 28 -> Feb 29 -> Mar 1
      final feb28 = DateTime(2024, 2, 28);
      final feb29 = DateTime(2024, 2, 29);
      final mar1 = DateTime(2024, 3, 1);

      final leapDates = {
        StreakDateUtils.toCalendarDateString(feb28),
        StreakDateUtils.toCalendarDateString(feb29),
        StreakDateUtils.toCalendarDateString(mar1),
      };

      expect(StreakDateUtils.calculateCurrentStreak(leapDates, mar1), equals(3));
      expect(StreakDateUtils.calculateBestStreak(leapDates), equals(3));

      // Non-leap year 2025: Feb 28 -> Mar 1
      final feb28NonLeap = DateTime(2025, 2, 28);
      final mar1NonLeap = DateTime(2025, 3, 1);
      final nonLeapDates = {
        StreakDateUtils.toCalendarDateString(feb28NonLeap),
        StreakDateUtils.toCalendarDateString(mar1NonLeap),
      };
      expect(StreakDateUtils.calculateCurrentStreak(nonLeapDates, mar1NonLeap), equals(2));
    });

    // 11. Multiple timestamps on the same calendar date
    test('11. Multiple timestamps on the same calendar date', () {
      final morning = DateTime(2026, 11, 5, 7, 15);
      final noon = DateTime(2026, 11, 5, 12, 30);
      final evening = DateTime(2026, 11, 5, 19, 45);
      final lateNight = DateTime(2026, 11, 5, 23, 59);

      final dateSet = <String>{};
      dateSet.add(StreakDateUtils.toCalendarDateString(morning));
      dateSet.add(StreakDateUtils.toCalendarDateString(noon));
      dateSet.add(StreakDateUtils.toCalendarDateString(evening));
      dateSet.add(StreakDateUtils.toCalendarDateString(lateNight));

      // Must collapse to exactly 1 unique date
      expect(dateSet.length, equals(1));
      expect(dateSet.first, equals('2026-11-05'));
      expect(StreakDateUtils.calculateCurrentStreak(dateSet, morning), equals(1));
    });

    // 12. Best streak calculated correctly
    test('12. Best streak calculated correctly', () {
      // 5-day streak in September, gap, then 2-day streak in November
      final dates = {
        '2026-09-10',
        '2026-09-11',
        '2026-09-12',
        '2026-09-13',
        '2026-09-14', // 5-day run
        '2026-11-04',
        '2026-11-05', // 2-day run
      };

      final today = DateTime(2026, 11, 5);
      expect(StreakDateUtils.calculateCurrentStreak(dates, today), equals(2));
      expect(StreakDateUtils.calculateBestStreak(dates), equals(5));
    });

    // 13. Existing historical records migrated without losing completed levels
    test('13. Existing historical records migrated without losing completed levels', () async {
      final prefs = await SharedPreferences.getInstance();

      // Setup legacy progression state with 3 completed puzzles on 2 distinct dates
      final legacyProgressionJson = json.encode({
        'highestUnlockedLevel': 4,
        'currentLevel': 4,
        'puzzleProgress': {
          'puzzle_1': {
            'puzzleId': 'puzzle_1',
            'isCompleted': true,
            'bestTimeSeconds': 42,
            'completedAt': '2026-11-03T10:00:00.000',
          },
          'puzzle_2': {
            'puzzleId': 'puzzle_2',
            'isCompleted': true,
            'bestTimeSeconds': 55,
            'completedAt': '2026-11-04T12:00:00.000',
          },
          'puzzle_3': {
            'puzzleId': 'puzzle_3',
            'isCompleted': true,
            'bestTimeSeconds': 70,
            'completedAt': '2026-11-04T15:30:00.000', // Same day as puzzle_2
          },
        },
      });
      await prefs.setString('snapdog_puzzle_progression_v2', legacyProgressionJson);

      // Setup legacy game stats with inflated streak number (e.g. 40 games played = 40 streak)
      final legacyStatsJson = json.encode({
        'gamesPlayed': 40,
        'gamesWon': 40,
        'currentStreak': 40, // Inflated!
        'bestStreak': 40, // Inflated!
        'bestTimeEasy': 42,
        'bestTimeMed': 55,
        'bestTimeHard': null,
      });
      await prefs.setString('snapdog_game_stats', legacyStatsJson);

      // Load stats with today = Nov 5 (so yesterday Nov 4 was completed)
      final today = DateTime(2026, 11, 5);
      final migratedStats = await StatsRepository.loadStats(prefs, today);

      // Verify historical data preserved:
      expect(migratedStats.gamesPlayed, equals(40));
      expect(migratedStats.gamesWon, equals(40));
      expect(migratedStats.bestTimeSeconds['puzzle_1'], equals(42));

      // Verify completion dates derived:
      expect(migratedStats.completionDates, containsAll(['2026-11-03', '2026-11-04']));
      expect(migratedStats.completionDates.length, equals(2)); // Nov 3 and Nov 4 (puzzle_3 deduplicated)

      // Verify streak corrected (not 40! Nov 3 and Nov 4 = 2-day streak):
      expect(migratedStats.currentStreak, equals(2));
      expect(migratedStats.bestStreak, equals(2));
    });

    // 14. App restart preserves the correct streak
    test('14. App restart preserves the correct streak', () async {
      final prefs = await SharedPreferences.getInstance();
      final day1 = DateTime(2026, 11, 3);
      final day2 = DateTime(2026, 11, 4);

      // First session: Record wins across 2 days
      await StatsRepository.recordWin(
        timeSeconds: 50,
        puzzleId: 'puzzle_1',
        completionTime: day1,
        customPrefs: prefs,
      );
      await StatsRepository.recordWin(
        timeSeconds: 60,
        puzzleId: 'puzzle_2',
        completionTime: day2,
        customPrefs: prefs,
      );

      // Simulate app restart: re-read from SharedPreferences
      final reloadedStats = await StatsRepository.loadStats(prefs, day2);
      expect(reloadedStats.currentStreak, equals(2));
      expect(reloadedStats.bestStreak, equals(2));
      expect(reloadedStats.completionDates.contains('2026-11-03'), isTrue);
      expect(reloadedStats.completionDates.contains('2026-11-04'), isTrue);
    });
  });
}
