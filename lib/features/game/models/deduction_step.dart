import 'dart:math';
import '../models/dog_placement.dart';
import '../models/puzzle.dart';

/// The deduction technique applied in a logical step.
enum DeductionTechnique {
  /// Elimination of cells in the same row, column, region, or 8-neighborhood of a placed dog.
  basicElimination,

  /// Row has only one remaining candidate cell for its dog.
  nakedSingleRow,

  /// Column has only one remaining candidate cell that can hold its dog.
  hiddenSingleColumn,

  /// Color region has only one remaining candidate cell that can hold its dog.
  hiddenSingleRegion,

  /// Line-Region reduction: All remaining candidates for a color region lie in a single row or column,
  /// eliminating all other candidates in that row or column.
  pointingRegionToLine,

  /// Region-Line reduction: All remaining candidates for a row or column lie within a single color region,
  /// eliminating all other candidates in that color region.
  pointingLineToRegion,

  /// Mutual adjacency: All candidate cells of a unit share a common neighboring cell;
  /// that neighboring cell can never contain a dog because any placement in the unit would touch it.
  mutualAdjacency,

  /// Controlled look-ahead: Assuming a candidate cell holds a dog leads to an immediate contradiction
  /// (an empty row, column, or region), proving that candidate cannot hold a dog.
  lookAheadContradiction,
}

/// The unit type affected by a deduction step.
enum UnitType {
  row,
  column,
  region,
  cell,
}

/// A single step in a structured deduction trace.
class DeductionStep {
  final int stepNumber;
  final DeductionTechnique technique;
  final UnitType unitType;
  final int? unitIndex;
  final List<Point<int>> candidatesBefore;
  final List<Point<int>> eliminatedCandidates;
  final List<Point<int>> remainingCandidates;
  final DogPlacement? forcedPlacement;
  final String explanation;

  const DeductionStep({
    required this.stepNumber,
    required this.technique,
    required this.unitType,
    this.unitIndex,
    required this.candidatesBefore,
    required this.eliminatedCandidates,
    required this.remainingCandidates,
    this.forcedPlacement,
    required this.explanation,
  });

  @override
  String toString() =>
      'Step $stepNumber [${technique.name}]: $explanation${forcedPlacement != null ? " -> Placed dog at (${forcedPlacement!.row}, ${forcedPlacement!.col})" : ""}';
}

/// Result of running the logical deduction engine on a puzzle.
class DeductionResult {
  final bool isSolved;
  final List<DogPlacement> placements;
  final List<DeductionStep> steps;
  final Difficulty difficulty;
  final int difficultyScore;
  final bool requiresLookAhead;
  final bool stalled;
  final int remainingPlacementsNeeded;
  final Set<DeductionTechnique> techniquesUsed;

  const DeductionResult({
    required this.isSolved,
    required this.placements,
    required this.steps,
    required this.difficulty,
    required this.difficultyScore,
    required this.requiresLookAhead,
    required this.stalled,
    required this.remainingPlacementsNeeded,
    required this.techniquesUsed,
  });

  @override
  String toString() =>
      'DeductionResult(isSolved: $isSolved, difficulty: ${difficulty.name}, score: $difficultyScore, steps: ${steps.length}, lookAhead: $requiresLookAhead, stalled: $stalled)';
}
