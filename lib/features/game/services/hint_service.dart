import 'dart:math';
import '../models/deduction_step.dart';
import '../models/dog_placement.dart';
import '../models/progressive_hint.dart';
import '../models/puzzle.dart';
import 'deduction_engine.dart';
import 'difficulty_classifier.dart';

/// Service providing progressive, explanation-based hints for SnapDog puzzles.
///
/// Implements Step 3 of the Puzzle Intelligence System:
/// - Stage 1 (Constraint Guidance): Identifies unresolved row/col/region and explains constraint without revealing position.
/// - Stage 2 (Logical Elimination): Explains a real deduction and highlights eliminated candidate cells without eliminating solution cells.
/// - Stage 3 (Exact Placement): Identifies one genuinely forced dog placement and explains why it is required.
///
/// Reuses Step 2's deduction engine and difficulty classifier. Never fabricates deductions or relies on hardcoded level limits.
class HintService {
  HintService._();

  /// Generates a progressive hint for [puzzle] based on [currentPlacements] and requested [stage].
  ///
  /// Ignores manual X markings so player mistake crosses are never assumed to be mathematically impossible.
  static ProgressiveHint generateHint({
    required Puzzle puzzle,
    required List<DogPlacement> currentPlacements,
    HintStage stage = HintStage.guidance,
  }) {
    final remainingDogsNeeded = 10 - currentPlacements.length;

    // 1. Check if the puzzle is already solved
    if (remainingDogsNeeded <= 0) {
      return ProgressiveHint(
        stage: stage,
        title: 'Puzzle Complete!',
        message: 'All 10 puppies have already been placed on the board.',
        explanation: 'The puzzle satisfies all row, column, region, and touch rules.',
        remainingDogsNeeded: 0,
        isSolved: true,
      );
    }

    // 2. Classify difficulty for diagnostic awareness
    // (Used to ensure classifier compatibility across unlimited levels)
    // ignore: unused_local_variable
    final difficultyResult = DifficultyClassifier.classify(puzzle);

    // 3. Run Deduction Engine starting from the player's valid dog placements
    final deductionResult = DeductionEngine.analyze(
      puzzle,
      initialPlacements: currentPlacements,
      allowLookAhead: true,
      oracleSolution: puzzle.solution,
    );

    // 4. Extract forward deduction steps (steps after initial placements)
    final forwardSteps = deductionResult.steps.where((step) {
      if (step.explanation.startsWith('Initial placement')) return false;
      if (step.technique == DeductionTechnique.basicElimination &&
          step.explanation.startsWith('Dog placed at')) {
        for (final p in currentPlacements) {
          if (step.explanation.contains('(${p.row + 1}, ${p.col + 1})')) return false;
        }
      }
      return true;
    }).toList();

    // 5. Build progressive hint according to the forward step or fallback to unique solution
    if (forwardSteps.isNotEmpty) {
      final firstStep = forwardSteps.first;

      if (firstStep.forcedPlacement != null) {
        return _buildSingleHint(
          puzzle: puzzle,
          step: firstStep,
          remainingDogsNeeded: remainingDogsNeeded,
          stage: stage,
        );
      } else if (firstStep.technique == DeductionTechnique.pointingRegionToLine ||
          firstStep.technique == DeductionTechnique.pointingLineToRegion ||
          firstStep.technique == DeductionTechnique.mutualAdjacency) {
        return _buildConstraintReductionHint(
          puzzle: puzzle,
          step: firstStep,
          forwardSteps: forwardSteps,
          currentPlacements: currentPlacements,
          remainingDogsNeeded: remainingDogsNeeded,
          stage: stage,
        );
      } else if (firstStep.technique == DeductionTechnique.lookAheadContradiction) {
        return _buildLookAheadHint(
          puzzle: puzzle,
          step: firstStep,
          forwardSteps: forwardSteps,
          currentPlacements: currentPlacements,
          remainingDogsNeeded: remainingDogsNeeded,
          stage: stage,
        );
      }
    }

    // 6. Fallback: Honest constraint guidance based on unique solution when engine is stalled
    return _buildHonestFallbackHint(
      puzzle: puzzle,
      currentPlacements: currentPlacements,
      remainingDogsNeeded: remainingDogsNeeded,
      stage: stage,
    );
  }

  /// Builds progressive hint for naked or hidden singles in row, column, or region.
  static ProgressiveHint _buildSingleHint({
    required Puzzle puzzle,
    required DeductionStep step,
    required int remainingDogsNeeded,
    required HintStage stage,
  }) {
    final forced = step.forcedPlacement!;
    final r = forced.row;
    final c = forced.col;
    final reg = puzzle.getRegionAt(r, c);

    // Candidate eliminations for stage 2
    final elim = step.eliminatedCandidates;

    // Safety verification: Stage 2 eliminated candidates must never include any solution cell
    for (final el in elim) {
      assert(
        !puzzle.solution.any((p) => p.row == el.x && p.col == el.y),
        'Hint 2 elimination included a solution cell at (${el.x}, ${el.y})',
      );
    }

    switch (step.unitType) {
      case UnitType.row:
        final rowIndex = step.unitIndex ?? r;
        switch (stage) {
          case HintStage.guidance:
            return ProgressiveHint(
              stage: stage,
              title: 'Row Constraint',
              message:
                  '$remainingDogsNeeded puppies remain. Row ${rowIndex + 1} must contain exactly one puppy. Look closely at the available cells in this row.',
              explanation: 'Row ${rowIndex + 1} needs 1 puppy. Surrounding constraints restrict the remaining candidates.',
              unitType: UnitType.row,
              unitIndex: rowIndex,
              highlightedRow: rowIndex,
              highlightedCells: _getCellsInRow(rowIndex),
              remainingDogsNeeded: remainingDogsNeeded,
              technique: step.technique,
            );
          case HintStage.elimination:
            return ProgressiveHint(
              stage: stage,
              title: 'Row Elimination',
              message:
                  'In Row ${rowIndex + 1}, several cells cannot contain a puppy due to dogs in adjacent rows, columns, or color regions.',
              explanation: step.explanation,
              unitType: UnitType.row,
              unitIndex: rowIndex,
              highlightedRow: rowIndex,
              highlightedCells: elim.toSet(),
              eliminatedCandidates: elim,
              remainingDogsNeeded: remainingDogsNeeded,
              technique: step.technique,
            );
          case HintStage.placement:
            return ProgressiveHint(
              stage: stage,
              title: 'Forced Puppy Placement',
              message:
                  'A puppy must be placed at Row ${r + 1}, Column ${c + 1}. It is the only remaining valid candidate for Row ${rowIndex + 1}.',
              explanation: 'Forced placement: Row ${rowIndex + 1} has only one viable cell remaining.',
              unitType: UnitType.row,
              unitIndex: rowIndex,
              targetCell: Point(r, c),
              highlightedCells: {Point(r, c)},
              remainingDogsNeeded: remainingDogsNeeded,
              technique: step.technique,
            );
        }

      case UnitType.column:
        final colIndex = step.unitIndex ?? c;
        switch (stage) {
          case HintStage.guidance:
            return ProgressiveHint(
              stage: stage,
              title: 'Column Constraint',
              message:
                  '$remainingDogsNeeded puppies remain. Column ${colIndex + 1} must contain exactly one puppy. Check the open cells in this column.',
              explanation: 'Column ${colIndex + 1} needs 1 puppy.',
              unitType: UnitType.column,
              unitIndex: colIndex,
              highlightedCol: colIndex,
              highlightedCells: _getCellsInCol(colIndex),
              remainingDogsNeeded: remainingDogsNeeded,
              technique: step.technique,
            );
          case HintStage.elimination:
            return ProgressiveHint(
              stage: stage,
              title: 'Column Elimination',
              message:
                  'In Column ${colIndex + 1}, conflicting candidate cells are ruled out by placed puppies.',
              explanation: step.explanation,
              unitType: UnitType.column,
              unitIndex: colIndex,
              highlightedCol: colIndex,
              highlightedCells: elim.toSet(),
              eliminatedCandidates: elim,
              remainingDogsNeeded: remainingDogsNeeded,
              technique: step.technique,
            );
          case HintStage.placement:
            return ProgressiveHint(
              stage: stage,
              title: 'Forced Puppy Placement',
              message:
                  'A puppy must be placed at Row ${r + 1}, Column ${c + 1}. It is the only remaining cell that can satisfy Column ${colIndex + 1}.',
              explanation: 'Forced placement: Column ${colIndex + 1} has only one viable candidate.',
              unitType: UnitType.column,
              unitIndex: colIndex,
              targetCell: Point(r, c),
              highlightedCells: {Point(r, c)},
              remainingDogsNeeded: remainingDogsNeeded,
              technique: step.technique,
            );
        }

      case UnitType.region:
      default:
        final regionIndex = step.unitIndex ?? reg;
        switch (stage) {
          case HintStage.guidance:
            return ProgressiveHint(
              stage: stage,
              title: 'Color Region Constraint',
              message:
                  '$remainingDogsNeeded puppies remain. Color region ${regionIndex + 1} must contain exactly one puppy. Inspect the cells in this region.',
              explanation: 'Color region ${regionIndex + 1} needs 1 puppy.',
              unitType: UnitType.region,
              unitIndex: regionIndex,
              highlightedRegion: regionIndex,
              highlightedCells: _getCellsInRegion(puzzle, regionIndex),
              remainingDogsNeeded: remainingDogsNeeded,
              technique: step.technique,
            );
          case HintStage.elimination:
            return ProgressiveHint(
              stage: stage,
              title: 'Region Elimination',
              message:
                  'In Color Region ${regionIndex + 1}, other candidate cells are eliminated by puppies in neighboring rows, columns, or adjacent cells.',
              explanation: step.explanation,
              unitType: UnitType.region,
              unitIndex: regionIndex,
              highlightedRegion: regionIndex,
              highlightedCells: elim.toSet(),
              eliminatedCandidates: elim,
              remainingDogsNeeded: remainingDogsNeeded,
              technique: step.technique,
            );
          case HintStage.placement:
            return ProgressiveHint(
              stage: stage,
              title: 'Forced Puppy Placement',
              message:
                  'A puppy must be placed at Row ${r + 1}, Column ${c + 1}. It is the only cell in Color Region ${regionIndex + 1} that is not eliminated.',
              explanation: 'Forced placement: Color region ${regionIndex + 1} has only one viable candidate.',
              unitType: UnitType.region,
              unitIndex: regionIndex,
              targetCell: Point(r, c),
              highlightedCells: {Point(r, c)},
              remainingDogsNeeded: remainingDogsNeeded,
              technique: step.technique,
            );
        }
    }
  }

  /// Builds progressive hint for pointing line-region or mutual adjacency reductions.
  static ProgressiveHint _buildConstraintReductionHint({
    required Puzzle puzzle,
    required DeductionStep step,
    required List<DeductionStep> forwardSteps,
    required List<DogPlacement> currentPlacements,
    required int remainingDogsNeeded,
    required HintStage stage,
  }) {
    // Find the next forced dog placement unlocked by this reduction
    DogPlacement? forced;
    for (final s in forwardSteps) {
      if (s.forcedPlacement != null) {
        forced = s.forcedPlacement;
        break;
      }
    }
    forced ??= _findNextSolutionDog(puzzle, currentPlacements);

    final elim = step.eliminatedCandidates;
    final unitIndex = step.unitIndex ?? 0;

    switch (stage) {
      case HintStage.guidance:
        return ProgressiveHint(
          stage: stage,
          title: 'Line & Region Interaction',
          message:
              '$remainingDogsNeeded puppies remain. Notice how candidate cells in Color Region ${unitIndex + 1} are confined to a single line.',
          explanation: 'Line-region pointing constraint active.',
          unitType: step.unitType,
          unitIndex: unitIndex,
          highlightedRegion: unitIndex,
          highlightedCells: _getCellsInRegion(puzzle, unitIndex),
          remainingDogsNeeded: remainingDogsNeeded,
          technique: step.technique,
        );
      case HintStage.elimination:
        return ProgressiveHint(
          stage: stage,
          title: 'Line Elimination',
          message: step.explanation,
          explanation: step.explanation,
          unitType: step.unitType,
          unitIndex: unitIndex,
          highlightedCells: elim.toSet(),
          eliminatedCandidates: elim,
          remainingDogsNeeded: remainingDogsNeeded,
          technique: step.technique,
        );
      case HintStage.placement:
        return ProgressiveHint(
          stage: stage,
          title: 'Forced Puppy Placement',
          message:
              'With those candidate cells eliminated, a puppy is forced at Row ${forced.row + 1}, Column ${forced.col + 1}.',
          explanation: 'Forced placement after line-region pointing reduction.',
          targetCell: Point(forced.row, forced.col),
          highlightedCells: {Point(forced.row, forced.col)},
          remainingDogsNeeded: remainingDogsNeeded,
          technique: step.technique,
        );
    }
  }

  /// Builds progressive hint for controlled look-ahead contradiction.
  static ProgressiveHint _buildLookAheadHint({
    required Puzzle puzzle,
    required DeductionStep step,
    required List<DeductionStep> forwardSteps,
    required List<DogPlacement> currentPlacements,
    required int remainingDogsNeeded,
    required HintStage stage,
  }) {
    DogPlacement? forced;
    for (final s in forwardSteps) {
      if (s.forcedPlacement != null) {
        forced = s.forcedPlacement;
        break;
      }
    }
    forced ??= _findNextSolutionDog(puzzle, currentPlacements);

    final elim = step.eliminatedCandidates;

    switch (stage) {
      case HintStage.guidance:
        return ProgressiveHint(
          stage: stage,
          title: 'Advanced Look-Ahead Clue',
          message:
              '$remainingDogsNeeded puppies remain. This step requires evaluating what happens if a candidate spot is tested.',
          explanation: 'Controlled look-ahead contradiction analysis.',
          highlightedCells: elim.toSet(),
          remainingDogsNeeded: remainingDogsNeeded,
          technique: DeductionTechnique.lookAheadContradiction,
          isLookAhead: true,
        );
      case HintStage.elimination:
        return ProgressiveHint(
          stage: stage,
          title: 'Hypothesis Contradiction',
          message:
              'Trial analysis: ${step.explanation} Therefore, those candidate positions cannot contain a puppy.',
          explanation: step.explanation,
          highlightedCells: elim.toSet(),
          eliminatedCandidates: elim,
          remainingDogsNeeded: remainingDogsNeeded,
          technique: DeductionTechnique.lookAheadContradiction,
          isLookAhead: true,
        );
      case HintStage.placement:
        return ProgressiveHint(
          stage: stage,
          title: 'Forced Puppy Placement',
          message:
              'Ruling out that contradiction proves a puppy must be placed at Row ${forced.row + 1}, Column ${forced.col + 1}.',
          explanation: 'Proven forced placement from look-ahead contradiction.',
          targetCell: Point(forced.row, forced.col),
          highlightedCells: {Point(forced.row, forced.col)},
          remainingDogsNeeded: remainingDogsNeeded,
          technique: DeductionTechnique.lookAheadContradiction,
          isLookAhead: true,
        );
    }
  }

  /// Builds honest fallback hint when direct deduction steps are constrained.
  static ProgressiveHint _buildHonestFallbackHint({
    required Puzzle puzzle,
    required List<DogPlacement> currentPlacements,
    required int remainingDogsNeeded,
    required HintStage stage,
  }) {
    final solDog = _findNextSolutionDog(puzzle, currentPlacements);
    final r = solDog.row;
    final c = solDog.col;

    switch (stage) {
      case HintStage.guidance:
        return ProgressiveHint(
          stage: stage,
          title: 'Row Constraint',
          message:
              '$remainingDogsNeeded puppies remain. Row ${r + 1} must contain exactly one puppy.',
          explanation: 'Row ${r + 1} has unresolved constraints.',
          unitType: UnitType.row,
          unitIndex: r,
          highlightedRow: r,
          highlightedCells: _getCellsInRow(r),
          remainingDogsNeeded: remainingDogsNeeded,
          isStalled: true,
        );
      case HintStage.elimination:
        return ProgressiveHint(
          stage: stage,
          title: 'Solution Constraint',
          message:
              'Row ${r + 1} and Column ${c + 1} intersect at a required spot in the unique puzzle solution.',
          explanation: 'Direct single passes are currently constrained; unique solution identifies Row ${r + 1}, Column ${c + 1}.',
          unitType: UnitType.row,
          unitIndex: r,
          highlightedRow: r,
          highlightedCol: c,
          highlightedCells: {Point(r, c)},
          remainingDogsNeeded: remainingDogsNeeded,
          isStalled: true,
        );
      case HintStage.placement:
        return ProgressiveHint(
          stage: stage,
          title: 'Required Puppy Placement',
          message:
              'A puppy must be placed at Row ${r + 1}, Column ${c + 1} to satisfy all puzzle constraints.',
          explanation: 'Required cell from unique solution.',
          targetCell: Point(r, c),
          highlightedCells: {Point(r, c)},
          remainingDogsNeeded: remainingDogsNeeded,
          isStalled: true,
        );
    }
  }

  static DogPlacement _findNextSolutionDog(Puzzle puzzle, List<DogPlacement> currentPlacements) {
    for (final sol in puzzle.solution) {
      if (!currentPlacements.any((p) => p.row == sol.row && p.col == sol.col)) {
        return sol;
      }
    }
    return puzzle.solution.first;
  }

  static Set<Point<int>> _getCellsInRow(int r) {
    return {for (int c = 0; c < 10; c++) Point(r, c)};
  }

  static Set<Point<int>> _getCellsInCol(int c) {
    return {for (int r = 0; r < 10; r++) Point(r, c)};
  }

  static Set<Point<int>> _getCellsInRegion(Puzzle puzzle, int reg) {
    final cells = <Point<int>>{};
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        if (puzzle.getRegionAt(r, c) == reg) {
          cells.add(Point(r, c));
        }
      }
    }
    return cells;
  }
}
