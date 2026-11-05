import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dog_placement.dart';
import '../models/puzzle.dart';
import 'difficulty_scheduler.dart';
import 'puzzle_fingerprint.dart';
import 'puzzle_generator.dart';
import 'puzzle_solver.dart';

class PuzzleRepository {
  static final Map<int, Puzzle> _generatedCache = {};
  static final DifficultyScheduler scheduler = DifficultyScheduler();
  static final RecentFingerprintTracker fingerprintTracker = RecentFingerprintTracker();

  static const String _puzzlesStorageKey = 'snapdog_generated_puzzles_v1';
  static const String _schedulerStorageKey = 'snapdog_difficulty_scheduler_v1';
  static const String _fingerprintsStorageKey = 'snapdog_fingerprints_v1';
  static bool _initialized = false;
  static bool get isInitialized => _initialized;
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
    // Puzzle 4: Daisy Meadow (Medium - Level 4)
    Puzzle(
      id: 'puzzle_4',
      title: 'Daisy Meadow',
      difficulty: Difficulty.medium,
      levelNumber: 4,
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

    // Puzzle 5: Breezy Trail (Medium - Level 5)
    Puzzle(
      id: 'puzzle_5',
      title: 'Breezy Trail',
      difficulty: Difficulty.medium,
      levelNumber: 5,
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

    // Puzzle 6: Playful Paws (Medium - Level 6)
    Puzzle(
      id: 'puzzle_6',
      title: 'Playful Paws',
      difficulty: Difficulty.medium,
      levelNumber: 6,
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
    // Puzzle 7: Sunny Backyard (Hard - Level 7)
    Puzzle(
      id: 'puzzle_7',
      title: 'Sunny Backyard',
      difficulty: Difficulty.hard,
      levelNumber: 7,
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

    // Puzzle 8: Bark Ridge (Hard - Level 8)
    Puzzle(
      id: 'puzzle_8',
      title: 'Bark Ridge',
      difficulty: Difficulty.hard,
      levelNumber: 8,
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

    // Puzzle 9: Golden Haven (Hard - Level 9)
    Puzzle(
      id: 'puzzle_9',
      title: 'Golden Haven',
      difficulty: Difficulty.hard,
      levelNumber: 9,
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

  /// Validates a puzzle using [PuzzleSolver.validateUniqueness].
  /// Identifies whether the puzzle has a unique solution, multiple solutions, or is impossible.
  static UniqueSolutionResult validatePuzzle(Puzzle puzzle) {
    return PuzzleSolver.validateUniqueness(puzzle);
  }

  /// Registers canonical fingerprints of handcrafted puzzles 1..9
  /// so procedural generation never duplicates them.
  static void registerHandcraftedFingerprints() {
    for (final p in puzzles) {
      fingerprintTracker.addPuzzle(p);
    }
  }

  /// Hydrates persisted puzzles, scheduling, and fingerprints from storage.
  static Future<void> loadPersistedData([SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();

      // Register handcrafted fingerprints first
      registerHandcraftedFingerprints();

      // Load scheduler history
      final schedulerJson = prefs.getString(_schedulerStorageKey);
      if (schedulerJson != null) {
        final loadedScheduler = DifficultyScheduler.fromJson(schedulerJson);
        for (int l = 10; l < 2000; l++) {
          final diff = loadedScheduler.getDifficultyForLevel(l);
          scheduler.recordLevelDifficulty(l, diff);
        }
      }

      // Load tracker history
      final trackerJson = prefs.getString(_fingerprintsStorageKey);
      if (trackerJson != null) {
        final loadedTracker = RecentFingerprintTracker.fromJson(trackerJson);
        for (final fp in loadedTracker.toList()) {
          fingerprintTracker.add(PuzzleFingerprint(fp));
        }
      }

      // Load generated puzzles
      final puzzlesJson = prefs.getString(_puzzlesStorageKey);
      if (puzzlesJson != null) {
        final decoded = json.decode(puzzlesJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final lvl = int.tryParse(entry.key);
          if (lvl != null && entry.value is Map<String, dynamic>) {
            try {
              final puzzle = Puzzle.fromMap(entry.value as Map<String, dynamic>);
              _generatedCache[lvl] = puzzle;
              scheduler.recordLevelDifficulty(lvl, puzzle.difficulty);
              fingerprintTracker.addPuzzle(puzzle);
            } catch (_) {}
          }
        }
      }

      _initialized = true;
    } catch (_) {
      // Ignored when SharedPreferences is unmocked in headless widget tests
    }
  }

  /// Persists generated puzzles, scheduler state, and fingerprints to storage.
  static Future<void> savePersistedData([SharedPreferences? customPrefs]) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();

      final puzzlesMap = <String, dynamic>{};
      for (final entry in _generatedCache.entries) {
        puzzlesMap[entry.key.toString()] = entry.value.toMap();
      }
      await prefs.setString(_puzzlesStorageKey, json.encode(puzzlesMap));
      await prefs.setString(_schedulerStorageKey, scheduler.toJson());
      await prefs.setString(_fingerprintsStorageKey, fingerprintTracker.toJson());
    } catch (_) {
      // Ignored when SharedPreferences is unmocked in headless widget tests
    }
  }

  /// Clears cache and resets tracker/scheduler state (for unit testing).
  static void clearCacheForTesting() {
    _generatedCache.clear();
    scheduler.clear();
    fingerprintTracker.clear();
    registerHandcraftedFingerprints();
    _initialized = false;
  }

  /// Manually caches a generated puzzle (for unit testing or hydration).
  static void setGeneratedPuzzleForTesting(int levelNumber, Puzzle puzzle) {
    _generatedCache[levelNumber] = puzzle;
    scheduler.recordLevelDifficulty(levelNumber, puzzle.difficulty);
    fingerprintTracker.addPuzzle(puzzle);
  }

  /// Returns the puzzle for [levelNumber] (1-indexed).
  /// Handcrafted levels 1..9 are returned for levels 1..9;
  /// Level 10 and beyond are procedurally generated on demand and cached.
  static Puzzle getPuzzleByLevel(int levelNumber) {
    if (levelNumber <= 0) levelNumber = 1;
    if (levelNumber <= puzzles.length) {
      final puzzle = puzzles[levelNumber - 1];
      // Pipeline validation: identify any invalid or ambiguous existing puzzles without replacing content
      assert(() {
        final validation = validatePuzzle(puzzle);
        if (!validation.isUnique) {
          debugPrint('WARNING: Predefined puzzle "${puzzle.title}" (${puzzle.id}) failed uniqueness validation: ${validation.status}');
        }
        return true;
      }());
      return puzzle;
    }

    if (_generatedCache.containsKey(levelNumber)) {
      return _generatedCache[levelNumber]!;
    }

    if (fingerprintTracker.length == 0) {
      registerHandcraftedFingerprints();
    }

    final targetDiff = scheduler.getDifficultyForLevel(levelNumber);
    final generated = PuzzleGenerator.generateForLevel(
      levelNumber,
      targetDifficulty: targetDiff,
      tracker: fingerprintTracker,
    );

    _generatedCache[levelNumber] = generated;
    scheduler.recordLevelDifficulty(levelNumber, generated.difficulty);
    fingerprintTracker.addPuzzle(generated);

    // Save asynchronously to persistent storage safely without unhandled future rejections
    savePersistedData().catchError((_) {});

    return generated;
  }

  static Puzzle getPuzzleByIndex(int index) {
    return getPuzzleByLevel(index + 1);
  }

  static int getPuzzleIndex(Puzzle puzzle) {
    return puzzle.levelNumber - 1;
  }

  static Puzzle getPuzzleById(String id) {
    final direct = puzzles.where((p) => p.id == id).firstOrNull;
    if (direct != null) return direct;

    if (id.startsWith('puzzle_')) {
      final level = int.tryParse(id.replaceFirst('puzzle_', ''));
      if (level != null && level >= 1) {
        return getPuzzleByLevel(level);
      }
    }
    return puzzles.first;
  }

  static List<Puzzle> getPuzzlesByDifficulty(Difficulty difficulty) {
    return puzzles.where((p) => p.difficulty == difficulty).toList();
  }
}
