import 'dart:math';
import 'deduction_step.dart';

/// The progressive stage of a hint in SnapDog's Puzzle Intelligence System.
enum HintStage {
  /// Stage 1: Constraint Guidance.
  /// Identifies an unresolved row, column, or color region and explains the constraint.
  /// Does not reveal the exact dog position.
  guidance,

  /// Stage 2: Logical Elimination.
  /// Explains a real deduction from the Step 2 deduction engine and highlights eliminated candidate cells.
  elimination,

  /// Stage 3: Exact Placement.
  /// Identifies a genuinely forced dog placement from the deduction engine. Never auto-places.
  placement,
}

/// An immutable representation of a progressive, explanation-based hint.
class ProgressiveHint {
  /// The current stage of this hint (guidance, elimination, or placement).
  final HintStage stage;

  /// Compact title for the hint (e.g. "Row Constraint", "Region Elimination", "Puppy Found!").
  final String title;

  /// User-friendly explanation message suitable for display in the hint overlay.
  final String message;

  /// Technical explanation or deduction trace note.
  final String explanation;

  /// The affected unit type (row, column, region, or cell).
  final UnitType? unitType;

  /// The index of the affected unit (0-based row, column, or region index).
  final int? unitIndex;

  /// Specific board cells to highlight subtly for this hint stage.
  final Set<Point<int>> highlightedCells;

  /// Subtly highlighted row (0-based), if applicable.
  final int? highlightedRow;

  /// Subtly highlighted column (0-based), if applicable.
  final int? highlightedCol;

  /// Subtly highlighted color region (0-based), if applicable.
  final int? highlightedRegion;

  /// The exact forced dog placement cell (revealed ONLY in Stage 3).
  final Point<int>? targetCell;

  /// Number of dogs remaining to be placed on the board.
  final int remainingDogsNeeded;

  /// The underlying deduction technique from Step 2, if applicable.
  final DeductionTechnique? technique;

  /// Cells that can be logically eliminated by this deduction step (Stage 2).
  final List<Point<int>> eliminatedCandidates;

  /// Whether this deduction relied on controlled look-ahead contradiction rather than direct singles.
  final bool isLookAhead;

  /// Whether the puzzle is already completely solved.
  final bool isSolved;

  /// Whether the deduction engine was unable to find a forward human-explainable deduction.
  final bool isStalled;

  const ProgressiveHint({
    required this.stage,
    required this.title,
    required this.message,
    required this.explanation,
    this.unitType,
    this.unitIndex,
    this.highlightedCells = const {},
    this.highlightedRow,
    this.highlightedCol,
    this.highlightedRegion,
    this.targetCell,
    required this.remainingDogsNeeded,
    this.technique,
    this.eliminatedCandidates = const [],
    this.isLookAhead = false,
    this.isSolved = false,
    this.isStalled = false,
  });

  /// Creates a copy of this hint with specified field overrides.
  ProgressiveHint copyWith({
    HintStage? stage,
    String? title,
    String? message,
    String? explanation,
    UnitType? unitType,
    int? unitIndex,
    Set<Point<int>>? highlightedCells,
    int? highlightedRow,
    int? highlightedCol,
    int? highlightedRegion,
    Point<int>? targetCell,
    int? remainingDogsNeeded,
    DeductionTechnique? technique,
    List<Point<int>>? eliminatedCandidates,
    bool? isLookAhead,
    bool? isSolved,
    bool? isStalled,
  }) {
    return ProgressiveHint(
      stage: stage ?? this.stage,
      title: title ?? this.title,
      message: message ?? this.message,
      explanation: explanation ?? this.explanation,
      unitType: unitType ?? this.unitType,
      unitIndex: unitIndex ?? this.unitIndex,
      highlightedCells: highlightedCells ?? this.highlightedCells,
      highlightedRow: highlightedRow ?? this.highlightedRow,
      highlightedCol: highlightedCol ?? this.highlightedCol,
      highlightedRegion: highlightedRegion ?? this.highlightedRegion,
      targetCell: targetCell ?? this.targetCell,
      remainingDogsNeeded: remainingDogsNeeded ?? this.remainingDogsNeeded,
      technique: technique ?? this.technique,
      eliminatedCandidates: eliminatedCandidates ?? this.eliminatedCandidates,
      isLookAhead: isLookAhead ?? this.isLookAhead,
      isSolved: isSolved ?? this.isSolved,
      isStalled: isStalled ?? this.isStalled,
    );
  }

  @override
  String toString() =>
      'ProgressiveHint(stage: ${stage.name}, title: "$title", target: $targetCell, remaining: $remainingDogsNeeded)';
}
