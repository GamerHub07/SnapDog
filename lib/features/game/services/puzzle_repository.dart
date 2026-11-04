import '../models/dog_placement.dart';
import '../models/puzzle.dart';

class PuzzleRepository {
  static final List<Puzzle> puzzles = [
    // -------------------------------------------------------------
    // EASY PUZZLES (Levels 1 - 3)
    // -------------------------------------------------------------
    // Puzzle 1: Puppy Park (Easy - Level 1)
    Puzzle(
      id: 'puzzle_1',
      title: 'Puppy Park',
      difficulty: Difficulty.easy,
      levelNumber: 1,
      regionMap: [
        [1, 1, 1, 1, 1, 4, 4, 0, 0, 4],
        [7, 7, 1, 1, 1, 4, 4, 4, 4, 4],
        [7, 7, 7, 1, 1, 2, 4, 4, 4, 3],
        [7, 7, 7, 7, 4, 4, 4, 4, 4, 3],
        [7, 7, 7, 7, 8, 4, 4, 4, 4, 4],
        [5, 7, 7, 7, 8, 4, 4, 4, 4, 4],
        [7, 7, 7, 7, 8, 8, 4, 4, 6, 4],
        [7, 7, 7, 7, 8, 8, 8, 4, 4, 4],
        [7, 7, 7, 8, 8, 8, 8, 4, 4, 4],
        [7, 9, 8, 8, 8, 8, 8, 8, 4, 4],
      ],
      solution: const [
        DogPlacement(0, 7),
        DogPlacement(1, 3),
        DogPlacement(2, 5),
        DogPlacement(3, 9),
        DogPlacement(4, 6),
        DogPlacement(5, 0),
        DogPlacement(6, 8),
        DogPlacement(7, 2),
        DogPlacement(8, 4),
        DogPlacement(9, 1),
      ],
    ),

    // Puzzle 2: Sunny Garden (Easy - Level 2)
    Puzzle(
      id: 'puzzle_2',
      title: 'Sunny Garden',
      difficulty: Difficulty.easy,
      levelNumber: 2,
      regionMap: [
        [1, 1, 1, 2, 2, 0, 2, 2, 2, 2],
        [1, 1, 1, 2, 2, 2, 2, 2, 2, 2],
        [1, 1, 2, 2, 2, 2, 2, 2, 2, 2],
        [1, 3, 2, 2, 2, 2, 2, 2, 2, 2],
        [3, 3, 2, 4, 2, 2, 2, 2, 2, 6],
        [3, 3, 8, 8, 8, 2, 5, 7, 6, 6],
        [3, 8, 8, 8, 8, 7, 7, 7, 6, 6],
        [3, 8, 8, 8, 8, 8, 7, 7, 6, 6],
        [3, 8, 8, 8, 8, 8, 7, 7, 7, 6],
        [8, 8, 8, 8, 8, 8, 7, 7, 9, 6],
      ],
      solution: const [
        DogPlacement(0, 5),
        DogPlacement(1, 0),
        DogPlacement(2, 4),
        DogPlacement(3, 1),
        DogPlacement(4, 3),
        DogPlacement(5, 6),
        DogPlacement(6, 9),
        DogPlacement(7, 7),
        DogPlacement(8, 2),
        DogPlacement(9, 8),
      ],
    ),

    // Puzzle 3: Cozy Kennel (Easy - Level 3)
    Puzzle(
      id: 'puzzle_3',
      title: 'Cozy Kennel',
      difficulty: Difficulty.easy,
      levelNumber: 3,
      regionMap: [
        [3, 3, 3, 3, 3, 3, 0, 0, 0, 0],
        [3, 3, 3, 1, 3, 3, 3, 0, 0, 0],
        [2, 3, 3, 3, 3, 3, 3, 0, 0, 0],
        [6, 3, 3, 3, 3, 3, 3, 3, 8, 8],
        [6, 4, 3, 3, 3, 3, 3, 8, 8, 8],
        [6, 6, 6, 3, 3, 3, 5, 8, 8, 8],
        [6, 6, 6, 6, 3, 3, 8, 8, 8, 8],
        [6, 6, 6, 6, 8, 8, 8, 8, 8, 7],
        [6, 8, 8, 8, 8, 8, 8, 8, 8, 8],
        [6, 8, 8, 8, 8, 9, 8, 8, 8, 8],
      ],
      solution: const [
        DogPlacement(0, 8),
        DogPlacement(1, 3),
        DogPlacement(2, 0),
        DogPlacement(3, 4),
        DogPlacement(4, 1),
        DogPlacement(5, 6),
        DogPlacement(6, 2),
        DogPlacement(7, 9),
        DogPlacement(8, 7),
        DogPlacement(9, 5),
      ],
    ),

    // -------------------------------------------------------------
    // MEDIUM PUZZLES (Levels 1 - 3)
    // -------------------------------------------------------------
    // Puzzle 4: Daisy Meadow (Medium - Level 1)
    Puzzle(
      id: 'puzzle_4',
      title: 'Daisy Meadow',
      difficulty: Difficulty.medium,
      levelNumber: 1,
      regionMap: [
        [0, 0, 0, 4, 4, 3, 3, 3, 3, 3],
        [0, 2, 4, 4, 4, 3, 3, 3, 3, 1],
        [4, 2, 4, 4, 4, 4, 4, 3, 3, 3],
        [4, 4, 4, 4, 4, 4, 4, 3, 3, 3],
        [4, 4, 4, 4, 4, 4, 4, 4, 3, 3],
        [7, 4, 4, 4, 4, 7, 4, 5, 7, 7],
        [7, 7, 7, 7, 6, 7, 7, 7, 7, 7],
        [7, 7, 7, 7, 7, 7, 7, 7, 7, 7],
        [7, 7, 8, 7, 7, 7, 7, 7, 7, 7],
        [7, 7, 7, 7, 9, 9, 9, 9, 9, 9],
      ],
      solution: const [
        DogPlacement(0, 0),
        DogPlacement(1, 9),
        DogPlacement(2, 1),
        DogPlacement(3, 8),
        DogPlacement(4, 3),
        DogPlacement(5, 7),
        DogPlacement(6, 4),
        DogPlacement(7, 6),
        DogPlacement(8, 2),
        DogPlacement(9, 5),
      ],
    ),

    // Puzzle 5: Breezy Trail (Medium - Level 2)
    Puzzle(
      id: 'puzzle_5',
      title: 'Breezy Trail',
      difficulty: Difficulty.medium,
      levelNumber: 2,
      regionMap: [
        [1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
        [1, 1, 1, 1, 1, 0, 0, 0, 0, 0],
        [1, 1, 1, 1, 2, 2, 0, 0, 0, 8],
        [1, 4, 4, 1, 2, 2, 2, 0, 3, 8],
        [4, 4, 4, 4, 2, 2, 2, 8, 8, 8],
        [4, 4, 4, 4, 2, 5, 9, 8, 8, 8],
        [6, 4, 4, 4, 9, 9, 9, 8, 8, 8],
        [4, 4, 4, 4, 9, 9, 9, 7, 8, 8],
        [4, 4, 4, 4, 9, 9, 9, 8, 8, 8],
        [4, 4, 4, 4, 9, 9, 9, 9, 8, 8],
      ],
      solution: const [
        DogPlacement(0, 3),
        DogPlacement(1, 1),
        DogPlacement(2, 4),
        DogPlacement(3, 8),
        DogPlacement(4, 2),
        DogPlacement(5, 5),
        DogPlacement(6, 0),
        DogPlacement(7, 7),
        DogPlacement(8, 9),
        DogPlacement(9, 6),
      ],
    ),

    // Puzzle 6: Playful Paws (Medium - Level 3)
    Puzzle(
      id: 'puzzle_6',
      title: 'Playful Paws',
      difficulty: Difficulty.medium,
      levelNumber: 3,
      regionMap: [
        [0, 0, 0, 3, 3, 3, 2, 2, 2, 2],
        [0, 0, 3, 3, 3, 1, 2, 2, 2, 2],
        [3, 3, 3, 3, 3, 3, 2, 2, 2, 2],
        [3, 3, 3, 3, 3, 3, 2, 2, 2, 2],
        [5, 5, 5, 3, 3, 5, 5, 4, 2, 2],
        [5, 5, 5, 5, 5, 5, 5, 5, 2, 2],
        [5, 5, 6, 5, 5, 5, 5, 5, 9, 9],
        [5, 5, 6, 6, 7, 7, 9, 9, 9, 9],
        [5, 5, 6, 6, 7, 9, 9, 9, 9, 8],
        [5, 6, 6, 6, 9, 9, 9, 9, 9, 9],
      ],
      solution: const [
        DogPlacement(0, 1),
        DogPlacement(1, 5),
        DogPlacement(2, 8),
        DogPlacement(3, 3),
        DogPlacement(4, 7),
        DogPlacement(5, 0),
        DogPlacement(6, 2),
        DogPlacement(7, 4),
        DogPlacement(8, 9),
        DogPlacement(9, 6),
      ],
    ),

    // -------------------------------------------------------------
    // HARD PUZZLES (Levels 1 - 3)
    // -------------------------------------------------------------
    // Puzzle 7: Sunny Backyard (Hard - Level 1)
    Puzzle(
      id: 'puzzle_7',
      title: 'Sunny Backyard',
      difficulty: Difficulty.hard,
      levelNumber: 1,
      regionMap: [
        [2, 0, 0, 1, 2, 2, 2, 2, 2, 2],
        [2, 2, 2, 1, 2, 2, 2, 2, 2, 2],
        [2, 2, 2, 2, 2, 2, 2, 2, 2, 2],
        [3, 2, 2, 2, 2, 2, 2, 2, 2, 2],
        [3, 2, 2, 2, 2, 2, 4, 2, 2, 2],
        [5, 5, 5, 2, 2, 2, 6, 6, 6, 6],
        [2, 2, 2, 2, 2, 6, 6, 6, 6, 6],
        [2, 2, 2, 2, 7, 6, 6, 6, 6, 6],
        [2, 2, 2, 2, 6, 6, 6, 6, 8, 8],
        [2, 2, 2, 2, 6, 6, 6, 9, 8, 8],
      ],
      solution: const [
        DogPlacement(0, 1),
        DogPlacement(1, 3),
        DogPlacement(2, 5),
        DogPlacement(3, 0),
        DogPlacement(4, 6),
        DogPlacement(5, 2),
        DogPlacement(6, 8),
        DogPlacement(7, 4),
        DogPlacement(8, 9),
        DogPlacement(9, 7),
      ],
    ),

    // Puzzle 8: Bark Ridge (Hard - Level 2)
    Puzzle(
      id: 'puzzle_8',
      title: 'Bark Ridge',
      difficulty: Difficulty.hard,
      levelNumber: 2,
      regionMap: [
        [0, 1, 1, 3, 5, 5, 5, 5, 5, 2],
        [1, 1, 1, 3, 5, 5, 5, 5, 5, 2],
        [1, 3, 3, 3, 5, 5, 5, 5, 4, 2],
        [1, 3, 3, 3, 5, 5, 5, 5, 4, 4],
        [5, 5, 5, 5, 5, 5, 6, 6, 4, 4],
        [5, 5, 5, 5, 5, 5, 6, 6, 6, 4],
        [8, 8, 5, 5, 5, 6, 6, 6, 6, 6],
        [8, 8, 8, 5, 5, 7, 6, 6, 6, 6],
        [8, 8, 8, 5, 5, 5, 9, 6, 6, 6],
        [8, 8, 5, 5, 5, 9, 9, 9, 6, 6],
      ],
      solution: const [
        DogPlacement(0, 0),
        DogPlacement(1, 2),
        DogPlacement(2, 9),
        DogPlacement(3, 3),
        DogPlacement(4, 8),
        DogPlacement(5, 4),
        DogPlacement(6, 7),
        DogPlacement(7, 5),
        DogPlacement(8, 1),
        DogPlacement(9, 6),
      ],
    ),

    // Puzzle 9: Golden Haven (Hard - Level 3)
    Puzzle(
      id: 'puzzle_9',
      title: 'Golden Haven',
      difficulty: Difficulty.hard,
      levelNumber: 3,
      regionMap: [
        [3, 3, 3, 1, 1, 1, 1, 0, 0, 0],
        [3, 3, 3, 3, 1, 1, 1, 1, 0, 0],
        [3, 3, 3, 3, 1, 1, 1, 1, 1, 2],
        [3, 3, 3, 1, 1, 1, 1, 1, 1, 1],
        [3, 3, 3, 3, 4, 5, 5, 1, 1, 1],
        [3, 3, 3, 5, 5, 5, 5, 5, 1, 5],
        [7, 3, 6, 5, 5, 5, 5, 5, 5, 5],
        [7, 7, 8, 5, 5, 5, 5, 5, 5, 5],
        [7, 7, 8, 8, 5, 5, 5, 5, 5, 5],
        [7, 7, 8, 8, 5, 5, 5, 5, 9, 9],
      ],
      solution: const [
        DogPlacement(0, 7),
        DogPlacement(1, 5),
        DogPlacement(2, 9),
        DogPlacement(3, 1),
        DogPlacement(4, 4),
        DogPlacement(5, 6),
        DogPlacement(6, 2),
        DogPlacement(7, 0),
        DogPlacement(8, 3),
        DogPlacement(9, 8),
      ],
    ),
  ];

  static int get totalCount => puzzles.length;

  static Puzzle getPuzzleByIndex(int index) {
    if (puzzles.isEmpty) throw StateError('No puzzles in repository');
    return puzzles[index % puzzles.length];
  }

  static int getPuzzleIndex(Puzzle puzzle) {
    return puzzles.indexWhere((p) => p.id == puzzle.id);
  }

  static Puzzle getPuzzleById(String id) {
    return puzzles.firstWhere(
      (p) => p.id == id,
      orElse: () => puzzles.first,
    );
  }

  static List<Puzzle> getPuzzlesByDifficulty(Difficulty difficulty) {
    return puzzles.where((p) => p.difficulty == difficulty).toList();
  }
}
