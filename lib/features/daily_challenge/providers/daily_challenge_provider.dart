import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/models/puzzle.dart';
import '../models/daily_challenge_record.dart';
import '../models/daily_challenge_state.dart';
import '../services/daily_persistence_service.dart';

/// Injectable clock provider for testing and deterministic calendar simulation.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final dailyChallengeProvider =
    NotifierProvider<DailyChallengeNotifier, DailyChallengeState>(
  DailyChallengeNotifier.new,
);

class DailyCompletionResult {
  final bool isSuccess;
  final bool isFirstCompletion;
  final int streakDays;
  final int longestStreakDays;
  final List<DailyReward> newlyUnlockedRewards;

  const DailyCompletionResult({
    required this.isSuccess,
    required this.isFirstCompletion,
    required this.streakDays,
    required this.longestStreakDays,
    this.newlyUnlockedRewards = const [],
  });
}

class DailyChallengeNotifier extends Notifier<DailyChallengeState> {
  bool _disposed = false;

  @override
  DailyChallengeState build() {
    ref.onDispose(() {
      _disposed = true;
    });

    _loadInitialState();
    return const DailyChallengeState();
  }

  Future<void> _loadInitialState() async {
    final loaded = await DailyPersistenceService.loadDailyState();
    if (!_disposed) {
      state = loaded;
    }
  }

  /// Current calendar date provided by the injectable clock.
  DateTime get currentDate => ref.read(clockProvider)();

  /// Normalized local midnight DateTime.
  DateTime get normalizedCurrentDate {
    final now = currentDate;
    return DateTime(now.year, now.month, now.day);
  }

  /// Whether a given [date] is in the future relative to current clock date.
  bool isFutureDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.isAfter(normalizedCurrentDate);
  }

  /// Whether a player can play the challenge for [date].
  /// Future dates cannot be played.
  bool canPlayDate(DateTime date) {
    return !isFutureDate(date);
  }

  /// Records completion of a daily challenge.
  ///
  /// - Only calendar days on or before today are valid.
  /// - First completion for [date] updates the streak and awards milestone rewards.
  /// - Replaying on the same date does NOT increase streak or change the original result.
  /// - Consecutive calendar days increase streak. Missing a day resets the current streak.
  /// - Longest streak is preserved.
  /// - Rewards are granted only once.
  Future<DailyCompletionResult> recordDailyCompletion({
    required Puzzle puzzle,
    required int timeSeconds,
    required int hintsUsed,
    int mistakes = 0,
    DateTime? completionDate,
  }) async {
    final date = completionDate ?? currentDate;
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Reject future dates (Requirement 9)
    if (isFutureDate(normalizedDate)) {
      return DailyCompletionResult(
        isSuccess: false,
        isFirstCompletion: false,
        streakDays: state.getEffectiveStreak(normalizedCurrentDate),
        longestStreakDays: state.longestStreak,
      );
    }

    final dateKey = DailyChallengeState.formatDateKey(normalizedDate);

    // If already completed on this date, replaying does not change streak or original record
    if (state.history.containsKey(dateKey)) {
      return DailyCompletionResult(
        isSuccess: true,
        isFirstCompletion: false,
        streakDays: state.getEffectiveStreak(normalizedCurrentDate),
        longestStreakDays: state.longestStreak,
      );
    }

    // Calculate streak
    int newStreak;
    final lastKey = state.lastCompletedDateKey;
    if (lastKey == null) {
      // First ever daily completion
      newStreak = 1;
    } else {
      final lastDate = DailyChallengeState.parseDateKey(lastKey);
      final yesterday = DateTime(normalizedDate.year, normalizedDate.month, normalizedDate.day - 1);

      if (lastDate == yesterday) {
        // Consecutive calendar day
        newStreak = state.currentStreak + 1;
      } else {
        // Gap or missed day -> reset current streak to 1
        newStreak = 1;
      }
    }

    final newLongestStreak = math.max(state.longestStreak, newStreak);

    // Check milestone rewards (3, 7, 30 days)
    final newlyUnlockedRewards = <DailyReward>[];
    final updatedEarnedRewards = Set<String>.from(state.earnedRewardIds);

    for (final reward in DailyMilestones.allRewards) {
      if (newStreak >= reward.streakDays && !updatedEarnedRewards.contains(reward.id)) {
        updatedEarnedRewards.add(reward.id);
        newlyUnlockedRewards.add(reward);
      }
    }

    final record = DailyChallengeRecord(
      dateKey: dateKey,
      puzzleId: puzzle.id,
      timeSeconds: timeSeconds,
      hintsUsed: hintsUsed,
      mistakes: mistakes,
      completedAt: date,
    );

    final nextHistory = Map<String, DailyChallengeRecord>.from(state.history)..[dateKey] = record;

    final nextState = state.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastCompletedDateKey: dateKey,
      history: nextHistory,
      earnedRewardIds: updatedEarnedRewards,
    );

    state = nextState;
    await DailyPersistenceService.saveDailyState(nextState);

    return DailyCompletionResult(
      isSuccess: true,
      isFirstCompletion: true,
      streakDays: newStreak,
      longestStreakDays: newLongestStreak,
      newlyUnlockedRewards: newlyUnlockedRewards,
    );
  }
}
