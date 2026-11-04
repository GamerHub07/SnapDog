import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/features/daily_challenge/models/daily_challenge_record.dart';
import 'package:snapdog/features/daily_challenge/models/daily_challenge_state.dart';
import 'package:snapdog/features/daily_challenge/providers/daily_challenge_provider.dart';
import 'package:snapdog/features/daily_challenge/services/daily_persistence_service.dart';
import 'package:snapdog/features/daily_challenge/services/daily_puzzle_scheduler.dart';
import 'package:snapdog/features/daily_challenge/services/daily_share_helper.dart';
import 'package:snapdog/features/game/services/puzzle_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SnapDog – Milestone 4: Daily Challenge & Rewards', () {
    test('1. Same date always produces the same daily puzzle', () {
      final date1 = DateTime(2026, 10, 31, 8, 30);
      final date2 = DateTime(2026, 10, 31, 22, 15);

      final puzzle1 = DailyPuzzleScheduler.getPuzzleForDate(date1);
      final puzzle2 = DailyPuzzleScheduler.getPuzzleForDate(date2);

      expect(puzzle1.id, equals(puzzle2.id));
      expect(puzzle1.title, equals(puzzle2.title));

      // Also across multiple invocations
      for (int i = 0; i < 10; i++) {
        expect(DailyPuzzleScheduler.getPuzzleForDate(date1).id, equals(puzzle1.id));
      }
    });

    test('2. Different dates can produce different puzzles', () {
      final puzzleOct30 = DailyPuzzleScheduler.getPuzzleForDate(DateTime(2026, 10, 30));
      final puzzleOct31 = DailyPuzzleScheduler.getPuzzleForDate(DateTime(2026, 10, 31));
      final puzzleNov1 = DailyPuzzleScheduler.getPuzzleForDate(DateTime(2026, 11, 1));

      // Adjacent days cycle through puzzles
      expect(puzzleOct30.id, isNot(equals(puzzleOct31.id)));
      expect(puzzleOct31.id, isNot(equals(puzzleNov1.id)));
    });

    test('3. Completing today\'s puzzle increases the streak', () async {
      final fixedDate = DateTime(2026, 10, 31);
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => fixedDate),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(dailyChallengeProvider.notifier);
      final puzzle = DailyPuzzleScheduler.getPuzzleForDate(fixedDate);

      expect(container.read(dailyChallengeProvider).currentStreak, equals(0));

      final result = await notifier.recordDailyCompletion(
        puzzle: puzzle,
        timeSeconds: 150,
        hintsUsed: 1,
        mistakes: 0,
      );

      expect(result.isSuccess, isTrue);
      expect(result.isFirstCompletion, isTrue);
      expect(result.streakDays, equals(1));
      expect(container.read(dailyChallengeProvider).currentStreak, equals(1));
      expect(container.read(dailyChallengeProvider).longestStreak, equals(1));
      expect(container.read(dailyChallengeProvider).isCompletedOn(fixedDate), isTrue);
    });

    test('4. Completing twice on the same date does not increase the streak twice', () async {
      final fixedDate = DateTime(2026, 10, 31);
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => fixedDate),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(dailyChallengeProvider.notifier);
      final puzzle = DailyPuzzleScheduler.getPuzzleForDate(fixedDate);

      // Attempt 1
      final res1 = await notifier.recordDailyCompletion(
        puzzle: puzzle,
        timeSeconds: 120,
        hintsUsed: 0,
        mistakes: 0,
      );
      expect(res1.isFirstCompletion, isTrue);
      expect(res1.streakDays, equals(1));
      expect(container.read(dailyChallengeProvider).currentStreak, equals(1));

      // Attempt 2 on the same calendar day (Replay)
      final res2 = await notifier.recordDailyCompletion(
        puzzle: puzzle,
        timeSeconds: 90,
        hintsUsed: 0,
        mistakes: 0,
      );
      expect(res2.isSuccess, isTrue);
      expect(res2.isFirstCompletion, isFalse);
      expect(res2.streakDays, equals(1)); // Streak NOT increased!
      expect(container.read(dailyChallengeProvider).currentStreak, equals(1));

      // Original record is preserved
      final record = container.read(dailyChallengeProvider).getRecord(fixedDate);
      expect(record?.timeSeconds, equals(120));
    });

    test('5. Consecutive dates increase the streak', () async {
      var currentDate = DateTime(2026, 10, 29);
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => currentDate),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(dailyChallengeProvider.notifier);

      // Day 1: Oct 29
      await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(currentDate),
        timeSeconds: 100,
        hintsUsed: 0,
      );
      expect(container.read(dailyChallengeProvider).currentStreak, equals(1));

      // Day 2: Oct 30
      currentDate = DateTime(2026, 10, 30);
      await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(currentDate),
        timeSeconds: 110,
        hintsUsed: 0,
        completionDate: currentDate,
      );
      expect(container.read(dailyChallengeProvider).currentStreak, equals(2));

      // Day 3: Oct 31
      currentDate = DateTime(2026, 10, 31);
      final res3 = await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(currentDate),
        timeSeconds: 105,
        hintsUsed: 0,
        completionDate: currentDate,
      );
      expect(res3.streakDays, equals(3));
      expect(container.read(dailyChallengeProvider).currentStreak, equals(3));
      expect(container.read(dailyChallengeProvider).longestStreak, equals(3));
    });

    test('6. Missing a day resets the current streak', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(dailyChallengeProvider.notifier);

      // Day 1: Oct 25 (streak = 1)
      await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(DateTime(2026, 10, 25)),
        timeSeconds: 100,
        hintsUsed: 0,
        completionDate: DateTime(2026, 10, 25),
      );
      // Day 2: Oct 26 (streak = 2)
      await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(DateTime(2026, 10, 26)),
        timeSeconds: 100,
        hintsUsed: 0,
        completionDate: DateTime(2026, 10, 26),
      );
      expect(container.read(dailyChallengeProvider).currentStreak, equals(2));

      // Player misses Oct 27!
      // On Oct 28, player plays again
      final res = await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(DateTime(2026, 10, 28)),
        timeSeconds: 120,
        hintsUsed: 0,
        completionDate: DateTime(2026, 10, 28),
      );

      // Streak resets back to 1
      expect(res.streakDays, equals(1));
      expect(container.read(dailyChallengeProvider).currentStreak, equals(1));
    });

    test('7. Longest streak is preserved after a reset', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(dailyChallengeProvider.notifier);

      // Build a 4-day streak
      for (int day = 1; day <= 4; day++) {
        await notifier.recordDailyCompletion(
          puzzle: DailyPuzzleScheduler.getPuzzleForDate(DateTime(2026, 5, day)),
          timeSeconds: 100,
          hintsUsed: 0,
          completionDate: DateTime(2026, 5, day),
        );
      }
      expect(container.read(dailyChallengeProvider).currentStreak, equals(4));
      expect(container.read(dailyChallengeProvider).longestStreak, equals(4));

      // Miss 3 days, then solve on Day 8
      await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(DateTime(2026, 5, 8)),
        timeSeconds: 100,
        hintsUsed: 0,
        completionDate: DateTime(2026, 5, 8),
      );

      // Current streak is reset to 1, but longest streak remains 4
      expect(container.read(dailyChallengeProvider).currentStreak, equals(1));
      expect(container.read(dailyChallengeProvider).longestStreak, equals(4));
    });

    test('8. Month and year boundaries work correctly', () async {
      var simulatedDate = DateTime(2026, 12, 31);
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => simulatedDate),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(dailyChallengeProvider.notifier);

      // Year boundary: Dec 31, 2026 -> Jan 1, 2027
      await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(simulatedDate),
        timeSeconds: 100,
        hintsUsed: 0,
        completionDate: simulatedDate,
      );
      expect(container.read(dailyChallengeProvider).currentStreak, equals(1));

      simulatedDate = DateTime(2027, 1, 1);
      await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(simulatedDate),
        timeSeconds: 100,
        hintsUsed: 0,
        completionDate: simulatedDate,
      );
      expect(container.read(dailyChallengeProvider).currentStreak, equals(2));

      // Month boundary: Feb 28, 2027 -> March 1, 2027
      simulatedDate = DateTime(2027, 2, 28);
      await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(simulatedDate),
        timeSeconds: 100,
        hintsUsed: 0,
        completionDate: simulatedDate,
      );
      // Gap between Jan 1 and Feb 28 resets to 1
      expect(container.read(dailyChallengeProvider).currentStreak, equals(1));

      // Consecutive: March 1
      simulatedDate = DateTime(2027, 3, 1);
      await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(simulatedDate),
        timeSeconds: 100,
        hintsUsed: 0,
        completionDate: simulatedDate,
      );
      expect(container.read(dailyChallengeProvider).currentStreak, equals(2));
    });

    test('9. Rewards are granted only once per milestone', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(dailyChallengeProvider.notifier);

      // Day 1 & Day 2: No rewards
      await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(DateTime(2026, 1, 1)),
        timeSeconds: 100,
        hintsUsed: 0,
        completionDate: DateTime(2026, 1, 1),
      );
      await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(DateTime(2026, 1, 2)),
        timeSeconds: 100,
        hintsUsed: 0,
        completionDate: DateTime(2026, 1, 2),
      );
      expect(container.read(dailyChallengeProvider).earnedRewardIds, isEmpty);

      // Day 3: Streak 3 -> Reward 3 unlocked
      final res3 = await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(DateTime(2026, 1, 3)),
        timeSeconds: 100,
        hintsUsed: 0,
        completionDate: DateTime(2026, 1, 3),
      );
      expect(res3.newlyUnlockedRewards.length, equals(1));
      expect(res3.newlyUnlockedRewards.first.id, equals('streak_3'));
      expect(container.read(dailyChallengeProvider).isRewardEarned('streak_3'), isTrue);

      // Day 4: Streak 4 -> Reward 3 is NOT granted again
      final res4 = await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(DateTime(2026, 1, 4)),
        timeSeconds: 100,
        hintsUsed: 0,
        completionDate: DateTime(2026, 1, 4),
      );
      expect(res4.newlyUnlockedRewards, isEmpty);
      expect(container.read(dailyChallengeProvider).earnedRewardIds.length, equals(1));
    });

    test('10. Future challenges cannot be played', () async {
      final today = DateTime(2026, 10, 31);
      final tomorrow = DateTime(2026, 11, 1);
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => today),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(dailyChallengeProvider.notifier);

      expect(notifier.isFutureDate(tomorrow), isTrue);
      expect(notifier.canPlayDate(tomorrow), isFalse);

      final result = await notifier.recordDailyCompletion(
        puzzle: DailyPuzzleScheduler.getPuzzleForDate(tomorrow),
        timeSeconds: 100,
        hintsUsed: 0,
        completionDate: tomorrow,
      );

      expect(result.isSuccess, isFalse);
      expect(container.read(dailyChallengeProvider).isCompletedOn(tomorrow), isFalse);
      expect(container.read(dailyChallengeProvider).currentStreak, equals(0));
    });

    test('11. Previous results can be viewed without changing streaks', () async {
      final today = DateTime(2026, 10, 31);
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => today),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(dailyChallengeProvider.notifier);
      final puzzle = DailyPuzzleScheduler.getPuzzleForDate(today);

      await notifier.recordDailyCompletion(
        puzzle: puzzle,
        timeSeconds: 215,
        hintsUsed: 2,
        mistakes: 1,
        completionDate: today,
      );

      final stateBefore = container.read(dailyChallengeProvider);
      expect(stateBefore.currentStreak, equals(1));

      // View result for today
      final record = stateBefore.getRecord(today);
      expect(record, isNotNull);
      expect(record?.timeSeconds, equals(215));
      expect(record?.hintsUsed, equals(2));
      expect(record?.mistakes, equals(1));

      // Streak remains unchanged
      final stateAfter = container.read(dailyChallengeProvider);
      expect(stateAfter.currentStreak, equals(stateBefore.currentStreak));
      expect(stateAfter.longestStreak, equals(stateBefore.longestStreak));
    });

    test('12. Persistence survives app restart', () async {
      final mockPrefs = <String, Object>{};
      SharedPreferences.setMockInitialValues(mockPrefs);

      final date = DateTime(2026, 10, 31);
      final testPuzzle = PuzzleRepository.puzzles.first;

      // Session 1: complete challenge and persist
      final state1 = DailyChallengeState(
        currentStreak: 5,
        longestStreak: 8,
        lastCompletedDateKey: DailyChallengeState.formatDateKey(date),
        history: {
          DailyChallengeState.formatDateKey(date): DailyChallengeRecord(
            dateKey: DailyChallengeState.formatDateKey(date),
            puzzleId: testPuzzle.id,
            timeSeconds: 180,
            hintsUsed: 1,
            mistakes: 0,
            completedAt: date,
          ),
        },
        earnedRewardIds: {'streak_3'},
      );

      await DailyPersistenceService.saveDailyState(state1);

      // Session 2: Fresh reload simulating cold app restart
      final restoredState = await DailyPersistenceService.loadDailyState();

      expect(restoredState.currentStreak, equals(5));
      expect(restoredState.longestStreak, equals(8));
      expect(restoredState.lastCompletedDateKey, equals('2026-10-31'));
      expect(restoredState.isCompletedOn(date), isTrue);
      expect(restoredState.isRewardEarned('streak_3'), isTrue);
      expect(restoredState.isRewardEarned('streak_7'), isFalse);

      final record = restoredState.getRecord(date);
      expect(record?.puzzleId, equals(testPuzzle.id));
      expect(record?.timeSeconds, equals(180));
      expect(record?.hintsUsed, equals(1));
    });

    test('13. DailyShareHelper formats share text accurately', () {
      final date = DateTime(2026, 10, 31);
      final shareText = DailyShareHelper.generateShareText(
        date: date,
        timeSeconds: 272, // 4 mins 32 secs
        hintsUsed: 1,
        streakDays: 7,
      );

      expect(shareText, contains('🐶 SnapDog Daily Challenge'));
      expect(shareText, contains('📅 31 Oct 2026'));
      expect(shareText, contains('⏱️ Time: 04:32'));
      expect(shareText, contains('💡 Hints: 1'));
      expect(shareText, contains('🔥 Streak: 7 days'));
      expect(shareText, contains('Can you solve today\'s puzzle?'));
    });
  });
}
