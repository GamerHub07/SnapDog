import 'package:flutter/material.dart';

class DailyChallengeRecord {
  final String dateKey; // 'YYYY-MM-DD'
  final String puzzleId;
  final int timeSeconds;
  final int hintsUsed;
  final int mistakes;
  final DateTime completedAt;

  const DailyChallengeRecord({
    required this.dateKey,
    required this.puzzleId,
    required this.timeSeconds,
    required this.hintsUsed,
    this.mistakes = 0,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'puzzleId': puzzleId,
      'timeSeconds': timeSeconds,
      'hintsUsed': hintsUsed,
      'mistakes': mistakes,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory DailyChallengeRecord.fromMap(Map<String, dynamic> map) {
    return DailyChallengeRecord(
      dateKey: map['dateKey'] as String,
      puzzleId: map['puzzleId'] as String,
      timeSeconds: map['timeSeconds'] as int? ?? 0,
      hintsUsed: map['hintsUsed'] as int? ?? 0,
      mistakes: map['mistakes'] as int? ?? 0,
      completedAt: DateTime.tryParse(map['completedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class DailyReward {
  final String id;
  final String title;
  final String description;
  final int streakDays;
  final String iconEmoji;
  final IconData materialIcon;

  const DailyReward({
    required this.id,
    required this.title,
    required this.description,
    required this.streakDays,
    required this.iconEmoji,
    required this.materialIcon,
  });
}

class DailyMilestones {
  static const reward3 = DailyReward(
    id: 'streak_3',
    title: 'Puppy Steps',
    description: 'Solve 3 daily challenges in a row',
    streakDays: 3,
    iconEmoji: '🥉',
    materialIcon: Icons.pets_rounded,
  );

  static const reward7 = DailyReward(
    id: 'streak_7',
    title: 'Good Dog',
    description: 'Solve 7 daily challenges in a row',
    streakDays: 7,
    iconEmoji: '🥈',
    materialIcon: Icons.military_tech_rounded,
  );

  static const reward30 = DailyReward(
    id: 'streak_30',
    title: 'Top Dog Champion',
    description: 'Solve 30 daily challenges in a row',
    streakDays: 30,
    iconEmoji: '🏆',
    materialIcon: Icons.emoji_events_rounded,
  );

  static const List<DailyReward> allRewards = [
    reward3,
    reward7,
    reward30,
  ];

  static DailyReward? getRewardForMilestone(int streak) {
    for (final reward in allRewards) {
      if (reward.streakDays == streak) return reward;
    }
    return null;
  }
}
