import 'dog_placement.dart';

/// Difficulty tiers for SnapDog puzzles.
enum Difficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  final String label;
  const Difficulty(this.label);

  static Difficulty fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'medium':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      case 'easy':
      default:
        return Difficulty.easy;
    }
  }
}

/// Represents a 10x10 puzzle definition with color regions and verified solution.
class Puzzle {
  final String id;
  final String title;
  final Difficulty difficulty;
  final int levelNumber;
  final List<List<int>> regionMap;
  final List<DogPlacement> solution;

  const Puzzle({
    required this.id,
    required this.title,
    this.difficulty = Difficulty.easy,
    String? difficultyLabel,
    this.levelNumber = 1,
    required this.regionMap,
    required this.solution,
  });

  String get difficultyLabel => difficulty.label;

  int get size => regionMap.length;

  int getRegionAt(int row, int col) => regionMap[row][col];

  Puzzle copyWith({
    String? id,
    String? title,
    Difficulty? difficulty,
    int? levelNumber,
    List<List<int>>? regionMap,
    List<DogPlacement>? solution,
  }) {
    return Puzzle(
      id: id ?? this.id,
      title: title ?? this.title,
      difficulty: difficulty ?? this.difficulty,
      levelNumber: levelNumber ?? this.levelNumber,
      regionMap: regionMap ?? this.regionMap,
      solution: solution ?? this.solution,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'difficulty': difficulty.name,
        'levelNumber': levelNumber,
        'regionMap': regionMap,
        'solution': solution.map((p) => {'row': p.row, 'col': p.col}).toList(),
      };

  factory Puzzle.fromMap(Map<String, dynamic> map) {
    final rawSolution = (map['solution'] as List<dynamic>?) ?? [];
    final rawRegionMap = (map['regionMap'] as List<dynamic>?) ?? [];

    return Puzzle(
      id: (map['id'] as String?) ?? 'puzzle_1',
      title: (map['title'] as String?) ?? 'Puzzle',
      difficulty: Difficulty.fromString(map['difficulty'] as String?),
      levelNumber: (map['levelNumber'] as int?) ?? 1,
      regionMap: rawRegionMap
          .map((row) => (row as List<dynamic>).map((e) => e as int).toList())
          .toList(),
      solution: rawSolution
          .map((p) => DogPlacement((p as Map)['row'] as int, p['col'] as int))
          .toList(),
    );
  }
}
