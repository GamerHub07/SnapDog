import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import 'dog_placement.dart';
import 'puzzle.dart';

/// Available 3D clay dog breeds for SnapDog.
enum DogBreed {
  beagle(
    id: 'beagle',
    displayName: 'Beagle',
    primaryColor: Color(0xFFDDA15E),
    accentColor: Color(0xFFBC6C25),
    assetPath: AppAssets.beagle,
  ),
  corgi(
    id: 'corgi',
    displayName: 'Corgi',
    primaryColor: Color(0xFFF4A261),
    accentColor: Color(0xFFE76F51),
    assetPath: AppAssets.corgi,
  ),
  goldenRetriever(
    id: 'golden_retriever',
    displayName: 'Golden Retriever',
    primaryColor: Color(0xFFEEBA4C),
    accentColor: Color(0xFFC78B1D),
    assetPath: AppAssets.goldenRetriever,
  ),
  husky(
    id: 'husky',
    displayName: 'Husky',
    primaryColor: Color(0xFF90A4AE),
    accentColor: Color(0xFF455A64),
    assetPath: AppAssets.husky,
  ),
  labrador(
    id: 'labrador',
    displayName: 'Labrador Retriever',
    primaryColor: Color(0xFFE07A5F),
    accentColor: Color(0xFFD45138),
    assetPath: AppAssets.labrador,
  ),
  pug(
    id: 'pug',
    displayName: 'Pug',
    primaryColor: Color(0xFFD4A373),
    accentColor: Color(0xFF382319),
    assetPath: AppAssets.pug,
  );

  /// Backwards-compatible alias for previously used shibaInu placeholder.
  static const DogBreed shibaInu = DogBreed.labrador;

  final String id;
  final String displayName;
  final Color primaryColor;
  final Color accentColor;
  final String assetPath;

  const DogBreed({
    required this.id,
    required this.displayName,
    required this.primaryColor,
    required this.accentColor,
    required this.assetPath,
  });

  bool get hasRasterAsset => true;
}

/// Helper that deterministically maps puzzle placements to dog breeds.
///
/// Guarantees:
/// 1. Exactly 10 dog placements mapped for standard 10x10 puzzle solutions.
/// 2. All 6 initial breeds are represented, with 4 repeats for a balanced 10-dog set.
/// 3. The assignment is deterministic: the same puzzle always gets the exact same breed layout.
/// 4. Does NOT affect puzzle validation, placement correctness, or solver logic.
class DogBreedAssignment {
  final Map<DogPlacement, DogBreed> _placementToBreed;
  final List<DogBreed> _orderedBreeds;

  const DogBreedAssignment._(
    this._placementToBreed,
    this._orderedBreeds,
  );

  /// Ordered list of breeds for each of the 10 solution dogs.
  List<DogBreed> get orderedBreeds => _orderedBreeds;

  /// Returns the assigned breed for a dog placed at [row, col], or defaults to [DogBreed.corgi].
  DogBreed getBreedAt(int row, int col) {
    return _placementToBreed[DogPlacement(row, col)] ?? DogBreed.corgi;
  }

  /// Factory that deterministically computes breed assignments for a given [Puzzle].
  factory DogBreedAssignment.forPuzzle(Puzzle puzzle) {
    // Sort solution placements by (row, col) for consistent baseline order
    final sortedPlacements = List<DogPlacement>.from(puzzle.solution)
      ..sort((a, b) {
        if (a.row != b.row) return a.row.compareTo(b.row);
        return a.col.compareTo(b.col);
      });

    final placementCount = sortedPlacements.length;
    final breeds = DogBreed.values;

    // Build base distribution ensuring all 6 breeds are included
    final assignedList = <DogBreed>[];
    for (int i = 0; i < placementCount; i++) {
      assignedList.add(breeds[i % breeds.length]);
    }

    // Deterministic pseudo-random shuffle seeded by puzzle.id and solution positions
    int seed = puzzle.id.hashCode.abs();
    for (final p in sortedPlacements) {
      seed = (seed * 31 + p.row * 10 + p.col) & 0x7FFFFFFF;
    }

    // Knuth shuffle using deterministic LCG
    int lcgState = seed == 0 ? 123456789 : seed;
    int nextRand(int max) {
      lcgState = (lcgState * 1103515245 + 12345) & 0x7FFFFFFF;
      return lcgState % max;
    }

    for (int i = assignedList.length - 1; i > 0; i--) {
      final j = nextRand(i + 1);
      final temp = assignedList[i];
      assignedList[i] = assignedList[j];
      assignedList[j] = temp;
    }

    final map = <DogPlacement, DogBreed>{};
    for (int i = 0; i < sortedPlacements.length; i++) {
      map[sortedPlacements[i]] = assignedList[i];
    }

    return DogBreedAssignment._(
      map,
      List.unmodifiable(assignedList),
    );
  }
}
