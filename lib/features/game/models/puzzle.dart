import 'dog_placement.dart';

/// Difficulty tiers for SnapDog puzzles.
enum Difficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  final String label;
  const Difficulty(this.label);
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
}
