/// Stores individual puzzle progress, best records, and completion statistics.
class PuzzleProgress {
  final String puzzleId;
  final bool isCompleted;
  final int? bestTimeSeconds;
  final int lastTimeSeconds;
  final int hintsUsed;
  final int mistakes;
  final DateTime? completedAt;

  const PuzzleProgress({
    required this.puzzleId,
    this.isCompleted = false,
    this.bestTimeSeconds,
    this.lastTimeSeconds = 0,
    this.hintsUsed = 0,
    this.mistakes = 0,
    this.completedAt,
  });

  PuzzleProgress copyWith({
    String? puzzleId,
    bool? isCompleted,
    int? bestTimeSeconds,
    int? lastTimeSeconds,
    int? hintsUsed,
    int? mistakes,
    DateTime? completedAt,
  }) {
    return PuzzleProgress(
      puzzleId: puzzleId ?? this.puzzleId,
      isCompleted: isCompleted ?? this.isCompleted,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
      lastTimeSeconds: lastTimeSeconds ?? this.lastTimeSeconds,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      mistakes: mistakes ?? this.mistakes,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'puzzleId': puzzleId,
      'isCompleted': isCompleted,
      'bestTimeSeconds': bestTimeSeconds,
      'lastTimeSeconds': lastTimeSeconds,
      'hintsUsed': hintsUsed,
      'mistakes': mistakes,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory PuzzleProgress.fromMap(Map<String, dynamic> map) {
    return PuzzleProgress(
      puzzleId: map['puzzleId'] as String,
      isCompleted: map['isCompleted'] as bool? ?? false,
      bestTimeSeconds: map['bestTimeSeconds'] as int?,
      lastTimeSeconds: map['lastTimeSeconds'] as int? ?? 0,
      hintsUsed: map['hintsUsed'] as int? ?? 0,
      mistakes: map['mistakes'] as int? ?? 0,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'] as String)
          : null,
    );
  }
}
