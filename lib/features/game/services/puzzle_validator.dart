import '../models/dog_placement.dart';
import '../models/puzzle.dart';

enum PlacementRuleViolation {
  outOfBounds,
  duplicateCell,
  sameRow,
  sameColumn,
  sameRegion,
  touching,
}

class PlacementValidationResult {
  final bool isValid;
  final PlacementRuleViolation? violation;
  final String? message;
  final Set<DogPlacement> conflictingDogs;

  const PlacementValidationResult.valid()
      : isValid = true,
        violation = null,
        message = null,
        conflictingDogs = const {};

  const PlacementValidationResult.invalid({
    required this.violation,
    required this.message,
    this.conflictingDogs = const {},
  }) : isValid = false;
}

/// Reusable validation engine for 10x10 SnapDog dog-placement logic puzzles.
class PuzzleValidator {
  static const int requiredDogCount = 10;

  /// Checks if coordinates are within the 10x10 puzzle board bounds.
  static bool isCoordinateInBounds(int row, int col) {
    return row >= 0 && row < 10 && col >= 0 && col < 10;
  }

  /// Rule 1: Every row must contain at most 1 dog (or exactly 1 if complete).
  /// Checks whether [row] contains at most 1 dog among [placements].
  static bool isRowValid(List<DogPlacement> placements, int row) {
    if (row < 0 || row >= 10) return false;
    int count = 0;
    for (final p in placements) {
      if (p.row == row) {
        count++;
        if (count > 1) return false;
      }
    }
    return true;
  }

  /// Rule 2: Every column must contain at most 1 dog (or exactly 1 if complete).
  /// Checks whether [col] contains at most 1 dog among [placements].
  static bool isColumnValid(List<DogPlacement> placements, int col) {
    if (col < 0 || col >= 10) return false;
    int count = 0;
    for (final p in placements) {
      if (p.col == col) {
        count++;
        if (count > 1) return false;
      }
    }
    return true;
  }

  /// Rule 3: Every color region must contain at most 1 dog.
  /// Checks whether [regionId] contains at most 1 dog among [placements].
  /// Validates bounds before accessing the region map to avoid RangeErrors.
  static bool isColorRegionValid(
    Puzzle puzzle,
    List<DogPlacement> placements,
    int regionId,
  ) {
    if (regionId < 0 || regionId >= 10) return false;
    int count = 0;
    for (final p in placements) {
      if (!isCoordinateInBounds(p.row, p.col)) return false;
      if (puzzle.getRegionAt(p.row, p.col) == regionId) {
        count++;
        if (count > 1) return false;
      }
    }
    return true;
  }

  /// Restriction: Two dogs cannot touch horizontally, vertically, or diagonally.
  /// Each dog blocks all 8 surrounding neighbors.
  static bool areDogsNotTouching(List<DogPlacement> placements) {
    for (int i = 0; i < placements.length; i++) {
      for (int j = i + 1; j < placements.length; j++) {
        final p1 = placements[i];
        final p2 = placements[j];
        final dr = (p1.row - p2.row).abs();
        final dc = (p1.col - p2.col).abs();
        if (dr <= 1 && dc <= 1) {
          return false;
        }
      }
    }
    return true;
  }

  /// Validates a potential new placement against the current placements and puzzle rules.
  /// Returns a detailed [PlacementValidationResult] explaining any rule conflict.
  static PlacementValidationResult validateNewPlacement(
    Puzzle puzzle,
    List<DogPlacement> placements,
    DogPlacement newPlacement,
  ) {
    if (!isCoordinateInBounds(newPlacement.row, newPlacement.col)) {
      return const PlacementValidationResult.invalid(
        violation: PlacementRuleViolation.outOfBounds,
        message: 'Placement is outside board boundaries!',
      );
    }

    // 1. Check duplicate cell
    for (final p in placements) {
      if (p.row == newPlacement.row && p.col == newPlacement.col) {
        return PlacementValidationResult.invalid(
          violation: PlacementRuleViolation.duplicateCell,
          message: 'A pup is already sitting here!',
          conflictingDogs: {p},
        );
      }
    }

    // 2. Check touching (horizontal, vertical, diagonal)
    final touchingDogs = <DogPlacement>{};
    for (final p in placements) {
      final dr = (p.row - newPlacement.row).abs();
      final dc = (p.col - newPlacement.col).abs();
      if (dr <= 1 && dc <= 1) {
        touchingDogs.add(p);
      }
    }
    if (touchingDogs.isNotEmpty) {
      return PlacementValidationResult.invalid(
        violation: PlacementRuleViolation.touching,
        message: 'Pups need space! Dogs cannot touch, even diagonally.',
        conflictingDogs: touchingDogs,
      );
    }

    // 3. Check same row
    for (final p in placements) {
      if (p.row == newPlacement.row) {
        return PlacementValidationResult.invalid(
          violation: PlacementRuleViolation.sameRow,
          message: 'Row ${newPlacement.row + 1} already has a puppy!',
          conflictingDogs: {p},
        );
      }
    }

    // 4. Check same column
    for (final p in placements) {
      if (p.col == newPlacement.col) {
        return PlacementValidationResult.invalid(
          violation: PlacementRuleViolation.sameColumn,
          message: 'Column ${newPlacement.col + 1} already has a puppy!',
          conflictingDogs: {p},
        );
      }
    }

    // 5. Check same color region
    final newRegion = puzzle.getRegionAt(newPlacement.row, newPlacement.col);
    for (final p in placements) {
      if (isCoordinateInBounds(p.row, p.col) &&
          puzzle.getRegionAt(p.row, p.col) == newRegion) {
        return PlacementValidationResult.invalid(
          violation: PlacementRuleViolation.sameRegion,
          message: 'This color area already has a happy pup!',
          conflictingDogs: {p},
        );
      }
    }

    return const PlacementValidationResult.valid();
  }

  /// Checks if [newPlacement] is valid to add to [placements] without violating any rules.
  /// Validates coordinates before accessing region maps to avoid RangeErrors.
  static bool isPlacementValid(
    Puzzle puzzle,
    List<DogPlacement> placements,
    DogPlacement newPlacement,
  ) {
    if (!isCoordinateInBounds(newPlacement.row, newPlacement.col)) {
      return false;
    }

    final newRegion = puzzle.getRegionAt(newPlacement.row, newPlacement.col);

    for (final p in placements) {
      if (!isCoordinateInBounds(p.row, p.col)) {
        return false;
      }
      // Duplicate cell
      if (p.row == newPlacement.row && p.col == newPlacement.col) {
        return false;
      }
      // Duplicate row
      if (p.row == newPlacement.row) {
        return false;
      }
      // Duplicate col
      if (p.col == newPlacement.col) {
        return false;
      }
      // Duplicate region
      if (puzzle.getRegionAt(p.row, p.col) == newRegion) {
        return false;
      }
      // Touching horizontally, vertically, or diagonally
      final dr = (p.row - newPlacement.row).abs();
      final dc = (p.col - newPlacement.col).abs();
      if (dr <= 1 && dc <= 1) {
        return false;
      }
    }

    return true;
  }

  /// Identifies all placements currently involved in any rule conflict.
  /// Validates coordinates safely so out-of-bounds placements never throw exceptions.
  static Set<DogPlacement> findClashingPlacements(
    Puzzle puzzle,
    List<DogPlacement> placements,
  ) {
    final clashes = <DogPlacement>{};

    for (int i = 0; i < placements.length; i++) {
      final p1 = placements[i];
      final bool p1InBounds = isCoordinateInBounds(p1.row, p1.col);
      if (!p1InBounds) {
        clashes.add(p1);
      }

      for (int j = i + 1; j < placements.length; j++) {
        final p2 = placements[j];
        final bool p2InBounds = isCoordinateInBounds(p2.row, p2.col);
        if (!p2InBounds) {
          clashes.add(p2);
        }

        final bool sameRow = p1.row == p2.row;
        final bool sameCol = p1.col == p2.col;
        final bool sameRegion = p1InBounds &&
            p2InBounds &&
            puzzle.getRegionAt(p1.row, p1.col) ==
                puzzle.getRegionAt(p2.row, p2.col);
        final bool touching =
            (p1.row - p2.row).abs() <= 1 && (p1.col - p2.col).abs() <= 1;

        if (sameRow || sameCol || sameRegion || touching || !p1InBounds || !p2InBounds) {
          clashes.add(p1);
          clashes.add(p2);
        }
      }
    }

    return clashes;
  }

  /// A puzzle is completed when:
  /// 1. Exactly 10 dogs are placed.
  /// 2. All coordinates are within bounds [0..9].
  /// 3. All positions are unique.
  /// 4. Exactly one dog in every row (0..9).
  /// 5. Exactly one dog in every column (0..9).
  /// 6. Exactly one dog in every color region (0..9).
  /// 7. No two dogs touch horizontally, vertically, or diagonally.
  static bool isPuzzleCompleted(Puzzle puzzle, List<DogPlacement> placements) {
    // 1. Exactly 10 dogs
    if (placements.length != requiredDogCount) return false;

    // 2. All coordinates are within bounds
    for (final p in placements) {
      if (!isCoordinateInBounds(p.row, p.col)) return false;
    }

    // 3. All positions are unique
    if (placements.toSet().length != requiredDogCount) return false;

    // 4. Exactly one dog per row (0..9)
    final rows = placements.map((p) => p.row).toSet();
    if (rows.length != requiredDogCount) return false;
    for (int r = 0; r < requiredDogCount; r++) {
      if (!rows.contains(r)) return false;
    }

    // 5. Exactly one dog per column (0..9)
    final cols = placements.map((p) => p.col).toSet();
    if (cols.length != requiredDogCount) return false;
    for (int c = 0; c < requiredDogCount; c++) {
      if (!cols.contains(c)) return false;
    }

    // 6. Exactly one dog per color region (0..9)
    final regions =
        placements.map((p) => puzzle.getRegionAt(p.row, p.col)).toSet();
    if (regions.length != requiredDogCount) return false;
    for (int reg = 0; reg < requiredDogCount; reg++) {
      if (!regions.contains(reg)) return false;
    }

    // 7. No horizontal, vertical or diagonal touching
    if (!areDogsNotTouching(placements)) return false;

    return true;
  }
}
