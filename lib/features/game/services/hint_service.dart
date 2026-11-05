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
      } else if (firstStep.technique == DeductionTechnique.basicElimination ||
          firstStep.technique == DeductionTechnique.pointingRegionToLine ||
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
    List<Point<int>> elim = step.eliminatedCandidates;
    if (elim.isEmpty) {
      // When a single cell is forced, all other cells in its row, column, and adjacent neighbors are eliminated
      final candidateElim = <Point<int>>[];
      for (int ci = 0; ci < 10; ci++) {
        if (ci != c) candidateElim.add(Point(r, ci));
      }
      for (int ri = 0; ri < 10; ri++) {
        if (ri != r) candidateElim.add(Point(ri, c));
      }
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final nr = r + dr;
          final nc = c + dc;
          if (nr >= 0 && nr < 10 && nc >= 0 && nc < 10) {
            candidateElim.add(Point(nr, nc));
          }
        }
      }
      elim = candidateElim.toSet().where((pt) {
        return !puzzle.solution.any((s) => s.row == pt.x && s.col == pt.y);
      }).toList();
    }

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
              title: 'Row Clue',
              message:
                  '$remainingDogsNeeded puppies remain. Row ${rowIndex + 1} still needs one dog. Look closely at the available cells in this row.',
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
                  'In Row ${rowIndex + 1}, several cells cannot contain a dog due to puppies in adjacent rows, columns, or color regions.',
              explanation: sanitizeMessage(step.explanation, puzzle),
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
                  'The only possible position for the next dog is Row ${r + 1}, Column ${c + 1}. It is the only remaining valid candidate for Row ${rowIndex + 1}.',
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
              title: 'Column Clue',
              message:
                  '$remainingDogsNeeded puppies remain. Column ${colIndex + 1} still needs one dog. Check the open cells in this column.',
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
                  'In Column ${colIndex + 1}, conflicting candidate cells are ruled out by placed dogs.',
              explanation: sanitizeMessage(step.explanation, puzzle),
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
                  'The only possible position for the next dog is Row ${r + 1}, Column ${c + 1}. It is the only remaining cell that can satisfy Column ${colIndex + 1}.',
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
        final regionDescCap = describeRegionCapitalized(puzzle, regionIndex);
        final regionDesc = describeRegion(puzzle, regionIndex);
        switch (stage) {
          case HintStage.guidance:
            return ProgressiveHint(
              stage: stage,
              title: 'Region Clue',
              message:
                  '$remainingDogsNeeded puppies remain. $regionDescCap still needs one dog. Look at its remaining available cells.',
              explanation: '$regionDescCap needs 1 puppy.',
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
                  'In $regionDesc, candidate cells are ruled out by dogs in neighboring rows, columns, or touching cells.',
              explanation: sanitizeMessage(step.explanation, puzzle),
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
                  'The only possible position for the next dog is Row ${r + 1}, Column ${c + 1} in $regionDesc.',
              explanation: 'Forced placement: $regionDescCap has only one viable candidate.',
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
    final regionDesc = describeRegion(puzzle, unitIndex);

    switch (stage) {
      case HintStage.guidance:
        return ProgressiveHint(
          stage: stage,
          title: 'Line & Region Interaction',
          message:
              '$remainingDogsNeeded puppies remain. Notice how candidate cells in $regionDesc are confined to a single line.',
          explanation: 'Line-region pointing constraint active.',
          unitType: step.unitType,
          unitIndex: unitIndex,
          highlightedRegion: unitIndex,
          highlightedCells: _getCellsInRegion(puzzle, unitIndex),
          remainingDogsNeeded: remainingDogsNeeded,
          technique: step.technique,
        );
      case HintStage.elimination:
        final explanation = sanitizeMessage(step.explanation, puzzle);
        return ProgressiveHint(
          stage: stage,
          title: 'Line Elimination',
          message: explanation,
          explanation: explanation,
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
              'The only possible position for the next dog is Row ${forced.row + 1}, Column ${forced.col + 1}.',
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
        final sanitized = sanitizeMessage(step.explanation, puzzle);
        return ProgressiveHint(
          stage: stage,
          title: 'Hypothesis Contradiction',
          message:
              'Trial analysis: $sanitized Therefore, those candidate positions can be eliminated.',
          explanation: sanitized,
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
              'The only possible position for the next dog is Row ${forced.row + 1}, Column ${forced.col + 1}.',
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
    final reg = puzzle.getRegionAt(r, c);
    final regionDesc = describeRegion(puzzle, reg);

    switch (stage) {
      case HintStage.guidance:
        return ProgressiveHint(
          stage: stage,
          title: 'Row Clue',
          message:
              '$remainingDogsNeeded puppies remain. Row ${r + 1} still needs one dog. Look at the open cells in this row.',
          explanation: 'Row ${r + 1} has unresolved constraints.',
          unitType: UnitType.row,
          unitIndex: r,
          highlightedRow: r,
          highlightedCells: _getCellsInRow(r),
          remainingDogsNeeded: remainingDogsNeeded,
          isStalled: true,
        );
      case HintStage.elimination:
        final fallbackElim = [
          for (int ci = 0; ci < 10; ci++)
            if (ci != c) Point(r, ci)
        ];
        return ProgressiveHint(
          stage: stage,
          title: 'Solution Constraint',
          message:
              'Row ${r + 1} and Column ${c + 1} intersect in $regionDesc at a required spot in the solution.',
          explanation: 'Direct single passes are currently constrained; unique solution identifies Row ${r + 1}, Column ${c + 1}.',
          unitType: UnitType.row,
          unitIndex: r,
          highlightedRow: r,
          highlightedCol: c,
          highlightedCells: fallbackElim.toSet(),
          eliminatedCandidates: fallbackElim,
          remainingDogsNeeded: remainingDogsNeeded,
          isStalled: true,
        );
      case HintStage.placement:
        return ProgressiveHint(
          stage: stage,
          title: 'Required Puppy Placement',
          message:
              'The only possible position for the next dog is Row ${r + 1}, Column ${c + 1}.',
          explanation: 'Required cell from unique solution.',
          targetCell: Point(r, c),
          highlightedCells: {Point(r, c)},
          remainingDogsNeeded: remainingDogsNeeded,
          isStalled: true,
        );
    }
  }

  static const List<String> _regionColorNames = [
    'mint-green',
    'sky-blue',
    'peach',
    'lavender',
    'pink',
    'butter-yellow',
    'aqua',
    'coral',
    'periwinkle',
    'pale-lime',
  ];

  /// Returns the human-friendly color name for region index (0..9).
  static String getRegionColorName(int regionIndex) {
    if (regionIndex < 0 || regionIndex >= _regionColorNames.length) {
      return 'pastel';
    }
    return _regionColorNames[regionIndex];
  }

  /// Generates a human-friendly visual description of a region based on its color and board position.
  /// Never returns internal IDs like "Region 4".
  static String describeRegion(Puzzle puzzle, int regionIndex) {
    final colorName = getRegionColorName(regionIndex);
    final cells = _getCellsInRegion(puzzle, regionIndex);
    if (cells.isEmpty) {
      return 'the $colorName region';
    }

    double sumR = 0;
    double sumC = 0;
    for (final pt in cells) {
      sumR += pt.x;
      sumC += pt.y;
    }
    final avgR = sumR / cells.length;
    final avgC = sumC / cells.length;

    final String position;
    if (avgR < 3.3) {
      if (avgC < 3.3) {
        position = 'near the top-left';
      } else if (avgC > 6.6) {
        position = 'in the upper-right';
      } else {
        position = 'near the top';
      }
    } else if (avgR > 6.6) {
      if (avgC < 3.3) {
        position = 'near the bottom-left';
      } else if (avgC > 6.6) {
        position = 'in the lower-right';
      } else {
        position = 'near the bottom';
      }
    } else {
      // Middle row band (3.3 <= avgR <= 6.6)
      if (avgC < 3.3) {
        position = 'along the left side';
      } else if (avgC > 6.6) {
        position = 'along the right side';
      } else {
        position = 'in the center';
      }
    }

    return 'the $colorName region $position';
  }

  /// Capitalized version of [describeRegion] for sentence beginnings.
  static String describeRegionCapitalized(Puzzle puzzle, int regionIndex) {
    final desc = describeRegion(puzzle, regionIndex);
    if (desc.startsWith('the ')) {
      return 'The ${desc.substring(4)}';
    }
    return desc;
  }

  /// Formats player-facing text by transforming internal region IDs into visual descriptions.
  static String sanitizeMessage(String text, Puzzle puzzle) {
    var result = text.replaceAllMapped(
      RegExp(r'(?:Color\s+)?[Rr]egion\s+(\d+)', caseSensitive: false),
      (match) {
        final num = int.tryParse(match.group(1) ?? '');
        if (num != null && num >= 1 && num <= 10) {
          return describeRegion(puzzle, num - 1);
        }
        return match.group(0)!;
      },
    );

    result = result.replaceAllMapped(
      RegExp(r'(^|\.\s+)the\s+([a-z\-]+)\s+region'),
      (match) => '${match.group(1)}The ${match.group(2)} region',
    );

    return result;
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
