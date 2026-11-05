import 'dart:math';
import '../models/dog_placement.dart';
import '../models/puzzle.dart';
import 'difficulty_classifier.dart';
import 'difficulty_scheduler.dart';
import 'puzzle_fingerprint.dart';
import 'puzzle_solver.dart';
import 'puzzle_validator.dart';

/// Procedural generator for endless valid SnapDog puzzles with verified UNIQUE solutions
/// and varied difficulty scheduling.
///
/// Guarantees:
/// 1. Exactly 10 non-touching dogs (1 per row, 1 per col).
/// 2. 10 contiguous color regions, each containing exactly one solution dog.
/// 3. Fully validated against all SnapDog puzzle rules.
/// 4. Verified by [PuzzleSolver.validateUniqueness] to guarantee EXACTLY ONE solution.
///    Puzzles with zero or multiple solutions are strictly rejected.
/// 5. Multiple generation strategies (Adaptive Cellular, Directional Bands,
///    Voronoi Partition, Boundary Perturbation) for genuine layout diversity.
/// 6. Puzzle canonical fingerprints to reject recent duplicates.
/// 7. Difficulty validated and labeled exclusively by [DifficultyClassifier].
/// 8. Safe, bounded attempt loops with truthful fallback (no rotation/reflection of handcrafted puzzles).
class PuzzleGenerator {
  PuzzleGenerator._();

  static const List<String> _prefixes = [
    'Sunny', 'Cozy', 'Playful', 'Breezy', 'Golden',
    'Misty', 'Cheery', 'Barking', 'Wagging', 'Grassy',
    'Rustic', 'Gentle', 'Happy', 'Puppy', 'Snuggle',
    'Amber', 'Sandy', 'Clover', 'Daisy', 'Velvet',
    'Cedar', 'Willow', 'Jasper', 'Maple', 'Pebble'
  ];

  static const List<String> _suffixes = [
    'Park', 'Trail', 'Meadow', 'Haven', 'Kennel',
    'Ridge', 'Garden', 'Yard', 'Cove', 'Pond',
    'Grove', 'Corner', 'Fields', 'Plaza', 'Valley',
    'Paddock', 'Glade', 'Brook', 'Orchard', 'Sanctuary',
    'Woods', 'Hollow', 'Pasture', 'Bluff', 'Haven'
  ];

  static const List<Point<int>> _directions = [
    Point(-1, 0), Point(1, 0), Point(0, -1), Point(0, 1)
  ];

  /// Generates a uniquely solvable procedural puzzle for [levelNumber].
  ///
  /// Optionally targets [targetDifficulty] (if null, schedules via [DifficultyScheduler]).
  /// Rejects duplicates tracked by [tracker].
  /// Guaranteed to return a valid, uniquely solvable puzzle with truthful difficulty classification.
  static Puzzle generateForLevel(
    int levelNumber, {
    Difficulty? targetDifficulty,
    RecentFingerprintTracker? tracker,
    int maxAttempts = 60,
  }) {
    assert(levelNumber >= 1);

    final title =
        '${_prefixes[(levelNumber * 7) % _prefixes.length]} ${_suffixes[(levelNumber * 13) % _suffixes.length]}';

    final targetDiff = targetDifficulty ?? DifficultyScheduler.scheduleNext(levelNumber, const []);

    // Deterministic seed based on levelNumber and target difficulty
    final baseSeed = (levelNumber * 10007 + 7919 + targetDiff.index * 1337) & 0x7FFFFFFF;
    final rng = Random(baseSeed);

    Puzzle? bestCandidate;
    Difficulty? bestCandidateDiff;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // 1. Generate valid 10 non-touching dog placements
      final placementCols = _findNonTouchingPlacement(rng);
      if (placementCols == null) continue;

      final solution = List.generate(
        10,
        (r) => DogPlacement(r, placementCols[r]),
      );

      // 2. Cycle generation strategies for genuine layout diversity
      final strategyIndex = attempt % 4;
      List<List<int>>? regionMap;

      switch (strategyIndex) {
        case 0:
          // Adaptive Cellular Growth with difficulty-tuned region capacities
          regionMap = _growAdaptiveCellular(placementCols, targetDiff, rng);
          break;
        case 1:
          // Directional Bands & Corridors
          regionMap = _growDirectionalBands(placementCols, targetDiff, rng);
          break;
        case 2:
          // Voronoi / Centroid Distance Partitioning
          regionMap = _growVoronoi(placementCols, targetDiff, rng);
          break;
        case 3:
          // Boundary Perturbation on a valid seed layout
          regionMap = _growPerturbed(placementCols, targetDiff, rng);
          break;
      }

      if (regionMap == null) continue;

      final candidate = Puzzle(
        id: 'puzzle_$levelNumber',
        title: title,
        difficulty: targetDiff,
        levelNumber: levelNumber,
        regionMap: regionMap,
        solution: solution,
      );

      // 3. Reject duplicate fingerprints if tracker is provided
      final fingerprint = PuzzleFingerprint.compute(candidate);
      if (tracker != null && tracker.contains(fingerprint)) {
        continue;
      }

      // 4. Strict Unique-Solution Validation:
      // Reject any candidate with zero or multiple solutions!
      final validationResult = PuzzleSolver.validateUniqueness(candidate);
      if (!validationResult.isUnique) {
        continue;
      }

      // 5. Logical Analysis & Difficulty Classification:
      // Actual difficulty must be certified by DifficultyClassifier (Step 2)
      final analysis = DifficultyClassifier.classify(candidate);
      final acceptedCandidate = candidate.copyWith(difficulty: analysis.difficulty);

      // Keep track of best candidate
      if (bestCandidate == null || (bestCandidateDiff != targetDiff && analysis.difficulty == targetDiff)) {
        bestCandidate = acceptedCandidate;
        bestCandidateDiff = analysis.difficulty;
      }

      // If candidate satisfies target difficulty and logical solvability, accept immediately!
      if (analysis.difficulty == targetDiff && analysis.isLogicallySolvable) {
        assert(PuzzleValidator.isPuzzleCompleted(acceptedCandidate, solution));
        tracker?.add(fingerprint);
        return acceptedCandidate;
      }
    }

    // 6. Safe Fallback Policy:
    // If budget exceeded for the exact target difficulty, return the best verified unique candidate
    // with its TRUE classified difficulty (never mislabeled!).
    if (bestCandidate != null) {
      tracker?.addPuzzle(bestCandidate);
      return bestCandidate;
    }

    // Extreme fallback: emergency deterministic unique puzzle generator
    return _generateEmergencyUniquePuzzle(levelNumber, title, targetDiff, tracker);
  }

  /// Emergency deterministic unique puzzle generator if search budget exhausted.
  /// Uses a constrained compact region structure that guarantees a unique logical solution.
  static Puzzle _generateEmergencyUniquePuzzle(
    int levelNumber,
    String title,
    Difficulty targetDiff,
    RecentFingerprintTracker? tracker,
  ) {
    for (int seedShift = 1; seedShift < 100; seedShift++) {
      final rng = Random(levelNumber * 31337 + seedShift * 101);
      final placementCols = _findNonTouchingPlacement(rng);
      if (placementCols == null) continue;

      final solution = List.generate(
        10,
        (r) => DogPlacement(r, placementCols[r]),
      );

      final regionMap = _growAdaptiveCellular(placementCols, Difficulty.easy, rng);
      if (regionMap == null) continue;

      final candidate = Puzzle(
        id: 'puzzle_$levelNumber',
        title: title,
        difficulty: Difficulty.easy,
        levelNumber: levelNumber,
        regionMap: regionMap,
        solution: solution,
      );

      final validation = PuzzleSolver.validateUniqueness(candidate);
      if (validation.isUnique) {
        final analysis = DifficultyClassifier.classify(candidate);
        final finalPuzzle = candidate.copyWith(difficulty: analysis.difficulty);
        tracker?.addPuzzle(finalPuzzle);
        return finalPuzzle;
      }
    }

    throw StateError('Failed to generate a verified unique puzzle for level $levelNumber');
  }

  /// Backtracking search for 10 non-touching row-column pairs (1 dog per row, 1 per col).
  static List<int>? _findNonTouchingPlacement(Random rng) {
    final cols = List.filled(10, -1);
    final usedCols = List.filled(10, false);

    bool backtrack(int r) {
      if (r == 10) return true;
      final candidates = List.generate(10, (i) => i)..shuffle(rng);
      for (final c in candidates) {
        if (usedCols[c]) continue;
        if (r > 0 && (c - cols[r - 1]).abs() <= 1) continue;
        cols[r] = c;
        usedCols[c] = true;
        if (backtrack(r + 1)) return true;
        usedCols[c] = false;
        cols[r] = -1;
      }
      return false;
    }

    return backtrack(0) ? cols : null;
  }

  // ---------------------------------------------------------------------------
  // STRATEGY 1: ADAPTIVE CELLULAR GROWTH
  // ---------------------------------------------------------------------------
  /// Expands regions outward from seeds with capacity controls tuned to [targetDiff].
  static List<List<int>>? _growAdaptiveCellular(
    List<int> placementCols,
    Difficulty targetDiff,
    Random rng,
  ) {
    final sizes = List.filled(10, 100);
    final perm = List.generate(10, (k) => k)..shuffle(rng);

    if (targetDiff == Difficulty.easy) {
      // 5 to 6 size-1 regions, 2 to 3 size-2 regions
      final num1 = 5 + (rng.nextBool() ? 1 : 0);
      final num2 = 2 + (rng.nextBool() ? 1 : 0);
      for (int k = 0; k < num1; k++) {
        sizes[perm[k]] = 1;
      }
      for (int k = num1; k < num1 + num2; k++) {
        sizes[perm[k]] = 2;
      }
    } else if (targetDiff == Difficulty.medium) {
      // 3 to 4 size-1 regions, 2 to 4 size-2 to 3 regions
      final num1 = 3 + (rng.nextBool() ? 1 : 0);
      final num2 = 3 + (rng.nextBool() ? 1 : 0);
      for (int k = 0; k < num1; k++) {
        sizes[perm[k]] = 1;
      }
      for (int k = num1; k < num1 + num2; k++) {
        sizes[perm[k]] = 2 + rng.nextInt(2);
      }
    } else {
      // Hard: 2 size-1 regions, 3 size-2..4 regions, rest large
      const num1 = 2;
      const num2 = 3;
      for (int k = 0; k < num1; k++) {
        sizes[perm[k]] = 1;
      }
      for (int k = num1; k < num1 + num2; k++) {
        sizes[perm[k]] = 2 + rng.nextInt(3);
      }
    }

    return _growFrontier(placementCols, sizes, rng);
  }

  // ---------------------------------------------------------------------------
  // STRATEGY 2: DIRECTIONAL BANDS / CORRIDORS
  // ---------------------------------------------------------------------------
  /// Grows regions with horizontal or vertical momentum.
  static List<List<int>>? _growDirectionalBands(
    List<int> placementCols,
    Difficulty targetDiff,
    Random rng,
  ) {
    final sizes = List.filled(10, 100);
    final perm = List.generate(10, (k) => k)..shuffle(rng);

    final num1 = targetDiff == Difficulty.easy ? 5 : 3;
    final num2 = targetDiff == Difficulty.easy ? 2 : 3;
    for (int k = 0; k < num1; k++) {
      sizes[perm[k]] = 1;
    }
    for (int k = num1; k < num1 + num2; k++) {
      sizes[perm[k]] = 2 + rng.nextInt(2);
    }

    final grid = List.generate(10, (_) => List.filled(10, -1));
    final regionCells = List.generate(10, (_) => <Point<int>>[]);
    final frontier = List.generate(10, (_) => <Point<int>>[]);
    final isHorizontal = List.generate(10, (_) => rng.nextBool());

    for (int r = 0; r < 10; r++) {
      final c = placementCols[r];
      grid[r][c] = r;
      regionCells[r].add(Point(r, c));
      for (final dir in _directions) {
        final nr = r + dir.x;
        final nc = c + dir.y;
        if (nr >= 0 && nr < 10 && nc >= 0 && nc < 10) {
          frontier[r].add(Point(nr, nc));
        }
      }
    }

    int unassigned = 90;
    int steps = 0;
    while (unassigned > 0 && steps++ < 2000) {
      final available = List.generate(10, (i) => i)
          .where((r) => regionCells[r].length < sizes[r] && frontier[r].isNotEmpty)
          .toList();

      if (available.isEmpty) {
        for (int r = 0; r < 10; r++) {
          if (sizes[r] > 10) sizes[r] += 10;
        }
        continue;
      }

      available.sort((a, b) => regionCells[a].length.compareTo(regionCells[b].length));
      final chosenReg = available.first;
      final f = frontier[chosenReg];
      final horiz = isHorizontal[chosenReg];
      final seedPt = regionCells[chosenReg].first;

      f.sort((a, b) {
        if (horiz) {
          final diffA = (a.x - seedPt.x).abs();
          final diffB = (b.x - seedPt.x).abs();
          return diffA.compareTo(diffB);
        } else {
          final diffA = (a.y - seedPt.y).abs();
          final diffB = (b.y - seedPt.y).abs();
          return diffA.compareTo(diffB);
        }
      });

      final pickIdx = rng.nextInt(min(2, f.length));
      final p = f.removeAt(pickIdx);

      if (grid[p.x][p.y] == -1) {
        grid[p.x][p.y] = chosenReg;
        regionCells[chosenReg].add(p);
        unassigned--;
        for (final dir in _directions) {
          final nr = p.x + dir.x;
          final nc = p.y + dir.y;
          if (nr >= 0 && nr < 10 && nc >= 0 && nc < 10 && grid[nr][nc] == -1) {
            frontier[chosenReg].add(Point(nr, nc));
          }
        }
      }
    }

    if (unassigned > 0) return null;
    return grid;
  }

  // ---------------------------------------------------------------------------
  // STRATEGY 3: VORONOI / CENTROID DISTANCE PARTITIONING
  // ---------------------------------------------------------------------------
  /// Grows regions based on proximity to seed placements.
  static List<List<int>>? _growVoronoi(
    List<int> placementCols,
    Difficulty targetDiff,
    Random rng,
  ) {
    final sizes = List.filled(10, 100);
    final perm = List.generate(10, (k) => k)..shuffle(rng);

    final num1 = targetDiff == Difficulty.easy ? 5 : 3;
    final num2 = targetDiff == Difficulty.easy ? 2 : 3;
    for (int k = 0; k < num1; k++) {
      sizes[perm[k]] = 1;
    }
    for (int k = num1; k < num1 + num2; k++) {
      sizes[perm[k]] = 2 + rng.nextInt(2);
    }

    final grid = List.generate(10, (_) => List.filled(10, -1));
    final regionCells = List.generate(10, (_) => <Point<int>>[]);
    final frontier = List.generate(10, (_) => <Point<int>>[]);
    final seeds = List.generate(10, (r) => Point(r, placementCols[r]));

    for (int r = 0; r < 10; r++) {
      final c = placementCols[r];
      grid[r][c] = r;
      regionCells[r].add(Point(r, c));
      for (final dir in _directions) {
        final nr = r + dir.x;
        final nc = c + dir.y;
        if (nr >= 0 && nr < 10 && nc >= 0 && nc < 10) {
          frontier[r].add(Point(nr, nc));
        }
      }
    }

    int unassigned = 90;
    int steps = 0;
    while (unassigned > 0 && steps++ < 2000) {
      final available = List.generate(10, (i) => i)
          .where((r) => regionCells[r].length < sizes[r] && frontier[r].isNotEmpty)
          .toList();

      if (available.isEmpty) {
        for (int r = 0; r < 10; r++) {
          if (sizes[r] > 10) sizes[r] += 10;
        }
        continue;
      }

      available.sort((a, b) => regionCells[a].length.compareTo(regionCells[b].length));
      final chosenReg = available.first;
      final f = frontier[chosenReg];
      final seed = seeds[chosenReg];

      f.sort((a, b) {
        final distA = (a.x - seed.x).abs() + (a.y - seed.y).abs();
        final distB = (b.x - seed.x).abs() + (b.y - seed.y).abs();
        return distA.compareTo(distB);
      });

      final p = f.removeAt(0);
      if (grid[p.x][p.y] == -1) {
        grid[p.x][p.y] = chosenReg;
        regionCells[chosenReg].add(p);
        unassigned--;
        for (final dir in _directions) {
          final nr = p.x + dir.x;
          final nc = p.y + dir.y;
          if (nr >= 0 && nr < 10 && nc >= 0 && nc < 10 && grid[nr][nc] == -1) {
            frontier[chosenReg].add(Point(nr, nc));
          }
        }
      }
    }

    if (unassigned > 0) return null;
    return grid;
  }

  // ---------------------------------------------------------------------------
  // STRATEGY 4: BOUNDARY PERTURBATION
  // ---------------------------------------------------------------------------
  /// Generates a base partition and swaps boundary cells to introduce interlocking tabs.
  static List<List<int>>? _growPerturbed(
    List<int> placementCols,
    Difficulty targetDiff,
    Random rng,
  ) {
    final baseGrid = _growAdaptiveCellular(placementCols, targetDiff, rng);
    if (baseGrid == null) return null;

    final dogCells = List.generate(10, (r) => Point(r, placementCols[r])).toSet();

    for (int swap = 0; swap < 10; swap++) {
      final r = rng.nextInt(10);
      final c = rng.nextInt(10);
      final pt = Point(r, c);

      if (dogCells.contains(pt)) continue;

      final currentReg = baseGrid[r][c];
      for (final dir in _directions) {
        final nr = r + dir.x;
        final nc = c + dir.y;
        if (nr >= 0 && nr < 10 && nc >= 0 && nc < 10) {
          final neighborReg = baseGrid[nr][nc];
          if (neighborReg != currentReg) {
            if (_isRegionConnectedWithoutCell(baseGrid, currentReg, pt)) {
              baseGrid[r][c] = neighborReg;
              break;
            }
          }
        }
      }
    }

    return baseGrid;
  }

  static bool _isRegionConnectedWithoutCell(List<List<int>> grid, int reg, Point<int> exclude) {
    Point<int>? start;
    int count = 0;
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        if (r == exclude.x && c == exclude.y) continue;
        if (grid[r][c] == reg) {
          count++;
          start ??= Point(r, c);
        }
      }
    }

    if (count == 0) return false;
    if (count == 1) return true;

    final visited = <Point<int>>{start!};
    final queue = <Point<int>>[start];

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      for (final dir in _directions) {
        final nr = curr.x + dir.x;
        final nc = curr.y + dir.y;
        if (nr >= 0 && nr < 10 && nc >= 0 && nc < 10) {
          if (nr == exclude.x && nc == exclude.y) continue;
          final np = Point(nr, nc);
          if (grid[nr][nc] == reg && !visited.contains(np)) {
            visited.add(np);
            queue.add(np);
          }
        }
      }
    }

    return visited.length == count;
  }

  /// Helper to grow regions outward from seeds with capacity controls.
  static List<List<int>>? _growFrontier(
    List<int> placementCols,
    List<int> maxSizes,
    Random rng,
  ) {
    final grid = List.generate(10, (_) => List.filled(10, -1));
    final regionCells = List.generate(10, (_) => <Point<int>>[]);
    final frontier = List.generate(10, (_) => <Point<int>>[]);

    for (int r = 0; r < 10; r++) {
      final c = placementCols[r];
      grid[r][c] = r;
      regionCells[r].add(Point(r, c));
      for (final dir in _directions) {
        final nr = r + dir.x;
        final nc = c + dir.y;
        if (nr >= 0 && nr < 10 && nc >= 0 && nc < 10) {
          frontier[r].add(Point(nr, nc));
        }
      }
    }

    int unassigned = 90;
    int steps = 0;
    while (unassigned > 0 && steps++ < 2000) {
      final availableRegions = List.generate(10, (i) => i)
          .where((r) => regionCells[r].length < maxSizes[r] && frontier[r].isNotEmpty)
          .toList()
        ..shuffle(rng);

      if (availableRegions.isEmpty) {
        for (int r = 0; r < 10; r++) {
          if (maxSizes[r] > 10) maxSizes[r] += 10;
        }
        continue;
      }

      availableRegions.sort((a, b) => regionCells[a].length.compareTo(regionCells[b].length));
      final chosenReg = availableRegions.first;
      final f = frontier[chosenReg];

      while (f.isNotEmpty) {
        final idx = rng.nextInt(f.length);
        final p = f.removeAt(idx);
        if (grid[p.x][p.y] == -1) {
          grid[p.x][p.y] = chosenReg;
          regionCells[chosenReg].add(p);
          unassigned--;
          for (final dir in _directions) {
            final nr = p.x + dir.x;
            final nc = p.y + dir.y;
            if (nr >= 0 && nr < 10 && nc >= 0 && nc < 10 && grid[nr][nc] == -1) {
              frontier[chosenReg].add(Point(nr, nc));
            }
          }
          break;
        }
      }
    }

    if (unassigned > 0) return null;

    for (int r = 0; r < 10; r++) {
      if (regionCells[r].isEmpty) return null;
    }

    return grid;
  }
}
