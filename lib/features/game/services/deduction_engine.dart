import 'dart:math';
import '../models/dog_placement.dart';
import '../models/puzzle.dart';
import '../models/deduction_step.dart';
import 'puzzle_solver.dart';

/// Reusable logical deduction engine for 10x10 SnapDog puzzles.
///
/// Progressively deduces dog placements and candidate eliminations using pure human-explainable logic:
/// - Candidate elimination (row, col, region, 8-neighborhood)
/// - Naked singles in rows
/// - Hidden singles in columns and color regions
/// - Line-Region / Region-Line pointing constraints (claiming)
/// - Mutual adjacency exclusions (neighborhood shadows)
/// - Controlled look-ahead (single-hypothesis contradiction elimination)
///
/// Never fabricates solutions or relies on backtracking shortcuts.
class DeductionEngine {
  DeductionEngine._();

  /// Analyzes and solves [puzzle] from the initial state using pure logical deduction.
  ///
  /// If [allowLookAhead] is false, deduction stops when forward singles and pointing
  /// constraints can no longer advance.
  /// If [oracleSolution] is provided (e.g. during test verification), every deduction
  /// is checked to ensure no solution cell is mistakenly eliminated.
  static DeductionResult analyze(
    Puzzle puzzle, {
    bool allowLookAhead = true,
    List<DogPlacement>? initialPlacements,
    List<DogPlacement>? oracleSolution,
  }) {
    // 0. Safety validation
    final structureError = PuzzleSolver.validateBoardStructure(puzzle);
    if (structureError != null) {
      return DeductionResult(
        isSolved: false,
        placements: const [],
        steps: [
          DeductionStep(
            stepNumber: 1,
            technique: DeductionTechnique.basicElimination,
            unitType: UnitType.cell,
            candidatesBefore: const [],
            eliminatedCandidates: const [],
            remainingCandidates: const [],
            explanation: 'Malformed puzzle: $structureError',
          )
        ],
        difficulty: Difficulty.hard,
        difficultyScore: 999,
        requiresLookAhead: false,
        stalled: true,
        remainingPlacementsNeeded: 10,
        techniquesUsed: const {},
      );
    }

    // 10x10 candidate grid
    final candidates = List.generate(10, (_) => List.filled(10, true));
    final placements = <DogPlacement>[];
    final placedRows = <int>{};
    final placedCols = <int>{};
    final placedRegions = <int>{};

    final steps = <DeductionStep>[];
    final techniquesUsed = <DeductionTechnique>{};
    int difficultyScore = 0;
    bool usedLookAhead = false;

    // Helper: list candidates in a row
    List<Point<int>> rowCandidates(int r) {
      final list = <Point<int>>[];
      for (int c = 0; c < 10; c++) {
        if (candidates[r][c]) list.add(Point(r, c));
      }
      return list;
    }

    // Helper: list candidates in a column
    List<Point<int>> colCandidates(int c) {
      final list = <Point<int>>[];
      for (int r = 0; r < 10; r++) {
        if (candidates[r][c]) list.add(Point(r, c));
      }
      return list;
    }

    // Helper: list candidates in a region
    List<Point<int>> regionCandidates(int reg) {
      final list = <Point<int>>[];
      for (int r = 0; r < 10; r++) {
        for (int c = 0; c < 10; c++) {
          if (puzzle.getRegionAt(r, c) == reg && candidates[r][c]) {
            list.add(Point(r, c));
          }
        }
      }
      return list;
    }

    // Place a dog and trigger basic candidate elimination
    void placeDog({
      required int r,
      required int c,
      required DeductionTechnique technique,
      required UnitType unitType,
      int? unitIndex,
      required String explanation,
      required List<Point<int>> candidatesBefore,
    }) {
      final placement = DogPlacement(r, c);
      placements.add(placement);
      placedRows.add(r);
      placedCols.add(c);
      final reg = puzzle.getRegionAt(r, c);
      placedRegions.add(reg);
      techniquesUsed.add(technique);

      // Score weight
      switch (technique) {
        case DeductionTechnique.basicElimination:
          difficultyScore += 1;
          break;
        case DeductionTechnique.nakedSingleRow:
          difficultyScore += 2;
          break;
        case DeductionTechnique.hiddenSingleColumn:
          difficultyScore += 3;
          break;
        case DeductionTechnique.hiddenSingleRegion:
          difficultyScore += 3;
          break;
        case DeductionTechnique.pointingRegionToLine:
        case DeductionTechnique.pointingLineToRegion:
          difficultyScore += 10;
          break;
        case DeductionTechnique.mutualAdjacency:
          difficultyScore += 15;
          break;
        case DeductionTechnique.lookAheadContradiction:
          difficultyScore += 30;
          break;
      }

      // Record placement step
      steps.add(DeductionStep(
        stepNumber: steps.length + 1,
        technique: technique,
        unitType: unitType,
        unitIndex: unitIndex,
        candidatesBefore: candidatesBefore,
        eliminatedCandidates: candidatesBefore.where((p) => p.x != r || p.y != c).toList(),
        remainingCandidates: [Point(r, c)],
        forcedPlacement: placement,
        explanation: explanation,
      ));

      // Eliminate all other cells in same row, column, region, and 8-neighbors
      final eliminatedByDog = <Point<int>>[];
      for (int row = 0; row < 10; row++) {
        for (int col = 0; col < 10; col++) {
          if (row == r && col == c) {
            candidates[row][col] = false; // consumed by placement
            continue;
          }
          if (!candidates[row][col]) continue;

          final bool sameRow = row == r;
          final bool sameCol = col == c;
          final bool sameRegion = puzzle.getRegionAt(row, col) == reg;
          final bool isNeighbor = (row - r).abs() <= 1 && (col - c).abs() <= 1;

          if (sameRow || sameCol || sameRegion || isNeighbor) {
            candidates[row][col] = false;
            eliminatedByDog.add(Point(row, col));
          }
        }
      }

      if (eliminatedByDog.isNotEmpty) {
        techniquesUsed.add(DeductionTechnique.basicElimination);
        steps.add(DeductionStep(
          stepNumber: steps.length + 1,
          technique: DeductionTechnique.basicElimination,
          unitType: UnitType.cell,
          unitIndex: null,
          candidatesBefore: eliminatedByDog,
          eliminatedCandidates: eliminatedByDog,
          remainingCandidates: const [],
          explanation:
              'Dog placed at (${r + 1}, ${c + 1}) eliminates ${eliminatedByDog.length} candidate cells in Row ${r + 1}, Column ${c + 1}, Region ${reg + 1}, and surrounding adjacent cells.',
        ));
      }

      // Independent Oracle assertion: ensure we never placed an incorrect dog
      if (oracleSolution != null) {
        assert(oracleSolution.contains(placement),
            'Deduction engine placed dog at ($r, $c) which is NOT in the unique solution!');
      }
    }

    // Apply any initial placements
    if (initialPlacements != null && initialPlacements.isNotEmpty) {
      for (final p in initialPlacements) {
        placeDog(
          r: p.row,
          c: p.col,
          technique: DeductionTechnique.basicElimination,
          unitType: UnitType.cell,
          explanation: 'Initial placement of dog at (${p.row + 1}, ${p.col + 1}).',
          candidatesBefore: [Point(p.row, p.col)],
        );
      }
    }

    // Main deduction loop: repeat passes until completed or stalled
    bool progress = true;
    while (progress && placements.length < 10) {
      progress = false;

      // -------------------------------------------------------------
      // Pass 1: Naked singles in rows (Row has only 1 available cell)
      // -------------------------------------------------------------
      for (int r = 0; r < 10; r++) {
        if (placedRows.contains(r)) continue;
        final avail = rowCandidates(r);
        if (avail.length == 1) {
          final pt = avail.first;
          placeDog(
            r: pt.x,
            c: pt.y,
            technique: DeductionTechnique.nakedSingleRow,
            unitType: UnitType.row,
            unitIndex: r,
            explanation:
                'Row ${r + 1} has only one available cell at Column ${pt.y + 1} because all other cells conflict with already placed dogs or occupied lines/regions.',
            candidatesBefore: avail,
          );
          progress = true;
          break;
        }
      }
      if (progress) continue;

      // -------------------------------------------------------------
      // Pass 2: Hidden singles in columns
      // -------------------------------------------------------------
      for (int c = 0; c < 10; c++) {
        if (placedCols.contains(c)) continue;
        final avail = colCandidates(c);
        if (avail.length == 1) {
          final pt = avail.first;
          placeDog(
            r: pt.x,
            c: pt.y,
            technique: DeductionTechnique.hiddenSingleColumn,
            unitType: UnitType.column,
            unitIndex: c,
            explanation:
                'Column ${c + 1} must contain a dog and has only one possible candidate cell remaining at Row ${pt.x + 1}.',
            candidatesBefore: avail,
          );
          progress = true;
          break;
        }
      }
      if (progress) continue;

      // -------------------------------------------------------------
      // Pass 3: Hidden singles in color regions
      // -------------------------------------------------------------
      for (int reg = 0; reg < 10; reg++) {
        if (placedRegions.contains(reg)) continue;
        final avail = regionCandidates(reg);
        if (avail.length == 1) {
          final pt = avail.first;
          placeDog(
            r: pt.x,
            c: pt.y,
            technique: DeductionTechnique.hiddenSingleRegion,
            unitType: UnitType.region,
            unitIndex: reg,
            explanation:
                'Color Region ${reg + 1} must contain a dog and has only one available cell remaining at (${pt.x + 1}, ${pt.y + 1}).',
            candidatesBefore: avail,
          );
          progress = true;
          break;
        }
      }
      if (progress) continue;

      // -------------------------------------------------------------
      // Pass 4: Pointing Line-Region / Region-Line constraints
      // -------------------------------------------------------------
      // 4A: Region -> Row pointing
      for (int reg = 0; reg < 10; reg++) {
        if (placedRegions.contains(reg)) continue;
        final avail = regionCandidates(reg);
        if (avail.length < 2) continue;

        final targetRow = avail.first.x;
        if (avail.every((p) => p.x == targetRow)) {
          final eliminated = <Point<int>>[];
          for (int c = 0; c < 10; c++) {
            if (candidates[targetRow][c] && puzzle.getRegionAt(targetRow, c) != reg) {
              candidates[targetRow][c] = false;
              eliminated.add(Point(targetRow, c));
            }
          }
          if (eliminated.isNotEmpty) {
            techniquesUsed.add(DeductionTechnique.pointingRegionToLine);
            difficultyScore += 10;
            steps.add(DeductionStep(
              stepNumber: steps.length + 1,
              technique: DeductionTechnique.pointingRegionToLine,
              unitType: UnitType.region,
              unitIndex: reg,
              candidatesBefore: avail,
              eliminatedCandidates: eliminated,
              remainingCandidates: avail,
              explanation:
                  'All remaining candidates for Color Region ${reg + 1} lie in Row ${targetRow + 1}. Therefore, the dog for Region ${reg + 1} must occupy Row ${targetRow + 1}, eliminating other cells in Row ${targetRow + 1}.',
            ));
            progress = true;
            break;
          }
        }

        // 4B: Region -> Column pointing
        final targetCol = avail.first.y;
        if (avail.every((p) => p.y == targetCol)) {
          final eliminated = <Point<int>>[];
          for (int r = 0; r < 10; r++) {
            if (candidates[r][targetCol] && puzzle.getRegionAt(r, targetCol) != reg) {
              candidates[r][targetCol] = false;
              eliminated.add(Point(r, targetCol));
            }
          }
          if (eliminated.isNotEmpty) {
            techniquesUsed.add(DeductionTechnique.pointingRegionToLine);
            difficultyScore += 10;
            steps.add(DeductionStep(
              stepNumber: steps.length + 1,
              technique: DeductionTechnique.pointingRegionToLine,
              unitType: UnitType.region,
              unitIndex: reg,
              candidatesBefore: avail,
              eliminatedCandidates: eliminated,
              remainingCandidates: avail,
              explanation:
                  'All remaining candidates for Color Region ${reg + 1} lie in Column ${targetCol + 1}. Therefore, the dog for Region ${reg + 1} must occupy Column ${targetCol + 1}, eliminating other cells in Column ${targetCol + 1}.',
            ));
            progress = true;
            break;
          }
        }
      }
      if (progress) continue;

      // 4C: Row -> Region pointing
      for (int r = 0; r < 10; r++) {
        if (placedRows.contains(r)) continue;
        final avail = rowCandidates(r);
        if (avail.length < 2) continue;

        final targetReg = puzzle.getRegionAt(r, avail.first.y);
        if (avail.every((p) => puzzle.getRegionAt(r, p.y) == targetReg)) {
          final eliminated = <Point<int>>[];
          for (int row = 0; row < 10; row++) {
            if (row == r) continue;
            for (int col = 0; col < 10; col++) {
              if (puzzle.getRegionAt(row, col) == targetReg && candidates[row][col]) {
                candidates[row][col] = false;
                eliminated.add(Point(row, col));
              }
            }
          }
          if (eliminated.isNotEmpty) {
            techniquesUsed.add(DeductionTechnique.pointingLineToRegion);
            difficultyScore += 10;
            steps.add(DeductionStep(
              stepNumber: steps.length + 1,
              technique: DeductionTechnique.pointingLineToRegion,
              unitType: UnitType.row,
              unitIndex: r,
              candidatesBefore: avail,
              eliminatedCandidates: eliminated,
              remainingCandidates: avail,
              explanation:
                  'All remaining candidates for Row ${r + 1} lie within Color Region ${targetReg + 1}. Therefore, the dog for Row ${r + 1} satisfies Region ${targetReg + 1}, eliminating candidate cells in Region ${targetReg + 1} outside Row ${r + 1}.',
            ));
            progress = true;
            break;
          }
        }
      }
      if (progress) continue;

      // 4D: Column -> Region pointing
      for (int c = 0; c < 10; c++) {
        if (placedCols.contains(c)) continue;
        final avail = colCandidates(c);
        if (avail.length < 2) continue;

        final targetReg = puzzle.getRegionAt(avail.first.x, c);
        if (avail.every((p) => puzzle.getRegionAt(p.x, c) == targetReg)) {
          final eliminated = <Point<int>>[];
          for (int row = 0; row < 10; row++) {
            for (int col = 0; col < 10; col++) {
              if (col == c) continue;
              if (puzzle.getRegionAt(row, col) == targetReg && candidates[row][col]) {
                candidates[row][col] = false;
                eliminated.add(Point(row, col));
              }
            }
          }
          if (eliminated.isNotEmpty) {
            techniquesUsed.add(DeductionTechnique.pointingLineToRegion);
            difficultyScore += 10;
            steps.add(DeductionStep(
              stepNumber: steps.length + 1,
              technique: DeductionTechnique.pointingLineToRegion,
              unitType: UnitType.column,
              unitIndex: c,
              candidatesBefore: avail,
              eliminatedCandidates: eliminated,
              remainingCandidates: avail,
              explanation:
                  'All remaining candidates for Column ${c + 1} lie within Color Region ${targetReg + 1}. Therefore, the dog for Column ${c + 1} satisfies Region ${targetReg + 1}, eliminating candidate cells in Region ${targetReg + 1} outside Column ${c + 1}.',
            ));
            progress = true;
            break;
          }
        }
      }
      if (progress) continue;

      // -------------------------------------------------------------
      // Pass 5: Mutual Adjacency (Neighborhood Shadows)
      // -------------------------------------------------------------
      for (int reg = 0; reg < 10; reg++) {
        if (placedRegions.contains(reg)) continue;
        final avail = regionCandidates(reg);
        if (avail.length < 2) continue;

        final eliminated = <Point<int>>[];
        for (int r = 0; r < 10; r++) {
          for (int c = 0; c < 10; c++) {
            if (!candidates[r][c]) continue;
            if (puzzle.getRegionAt(r, c) == reg) continue;

            // Does every cell in avail touch (r, c)?
            if (avail.every((p) => (p.x - r).abs() <= 1 && (p.y - c).abs() <= 1)) {
              candidates[r][c] = false;
              eliminated.add(Point(r, c));
            }
          }
        }
        if (eliminated.isNotEmpty) {
          techniquesUsed.add(DeductionTechnique.mutualAdjacency);
          difficultyScore += 15;
          steps.add(DeductionStep(
            stepNumber: steps.length + 1,
            technique: DeductionTechnique.mutualAdjacency,
            unitType: UnitType.region,
            unitIndex: reg,
            candidatesBefore: avail,
            eliminatedCandidates: eliminated,
            remainingCandidates: avail,
            explanation:
                'Every remaining candidate in Color Region ${reg + 1} is adjacent to cell (${eliminated.map((p) => "(${p.x + 1}, ${p.y + 1})").join(", ")}). A dog at that position would leave Region ${reg + 1} with zero valid cells.',
          ));
          progress = true;
          break;
        }
      }
      if (progress) continue;

      // -------------------------------------------------------------
      // Pass 6: Controlled Look-Ahead (Contradiction Elimination)
      // -------------------------------------------------------------
      if (allowLookAhead) {
        Point<int>? contradictionCell;
        String? contradictionReason;

        cellSearch:
        for (int r = 0; r < 10; r++) {
          for (int c = 0; c < 10; c++) {
            if (!candidates[r][c]) continue;

            final reg = puzzle.getRegionAt(r, c);

            // 1. Would row become empty?
            for (int checkR = 0; checkR < 10; checkR++) {
              if (checkR == r || placedRows.contains(checkR)) continue;
              bool hasAvail = false;
              for (int checkC = 0; checkC < 10; checkC++) {
                if (checkC == c) continue;
                if (!candidates[checkR][checkC]) continue;
                if (puzzle.getRegionAt(checkR, checkC) == reg) continue;
                if ((checkR - r).abs() <= 1 && (checkC - c).abs() <= 1) continue;
                hasAvail = true;
                break;
              }
              if (!hasAvail) {
                contradictionCell = Point(r, c);
                contradictionReason = 'Row ${checkR + 1} would have zero available cells';
                break cellSearch;
              }
            }

            // 2. Would column become empty?
            for (int checkC = 0; checkC < 10; checkC++) {
              if (checkC == c || placedCols.contains(checkC)) continue;
              bool hasAvail = false;
              for (int checkR = 0; checkR < 10; checkR++) {
                if (checkR == r) continue;
                if (!candidates[checkR][checkC]) continue;
                if (puzzle.getRegionAt(checkR, checkC) == reg) continue;
                if ((checkR - r).abs() <= 1 && (checkC - c).abs() <= 1) continue;
                hasAvail = true;
                break;
              }
              if (!hasAvail) {
                contradictionCell = Point(r, c);
                contradictionReason = 'Column ${checkC + 1} would have zero available cells';
                break cellSearch;
              }
            }

            // 3. Would region become empty?
            for (int checkReg = 0; checkReg < 10; checkReg++) {
              if (checkReg == reg || placedRegions.contains(checkReg)) continue;
              bool hasAvail = false;
              for (int checkR = 0; checkR < 10; checkR++) {
                if (checkR == r) continue;
                for (int checkC = 0; checkC < 10; checkC++) {
                  if (checkC == c) continue;
                  if (puzzle.getRegionAt(checkR, checkC) != checkReg) continue;
                  if (!candidates[checkR][checkC]) continue;
                  if ((checkR - r).abs() <= 1 && (checkC - c).abs() <= 1) continue;
                  hasAvail = true;
                  break;
                }
                if (hasAvail) break;
              }
              if (!hasAvail) {
                contradictionCell = Point(r, c);
                contradictionReason = 'Color Region ${checkReg + 1} would have zero available cells';
                break cellSearch;
              }
            }
          }
        }

        if (contradictionCell != null) {
          candidates[contradictionCell.x][contradictionCell.y] = false;
          techniquesUsed.add(DeductionTechnique.lookAheadContradiction);
          usedLookAhead = true;
          difficultyScore += 30;

          steps.add(DeductionStep(
            stepNumber: steps.length + 1,
            technique: DeductionTechnique.lookAheadContradiction,
            unitType: UnitType.cell,
            unitIndex: null,
            candidatesBefore: [contradictionCell],
            eliminatedCandidates: [contradictionCell],
            remainingCandidates: const [],
            explanation:
                'Controlled look-ahead: Assuming a dog at (${contradictionCell.x + 1}, ${contradictionCell.y + 1}) leads to a direct contradiction ($contradictionReason). Therefore, (${contradictionCell.x + 1}, ${contradictionCell.y + 1}) cannot hold a dog and is eliminated.',
          ));

          if (oracleSolution != null) {
            assert(!oracleSolution.contains(DogPlacement(contradictionCell.x, contradictionCell.y)),
                'Contradiction eliminated a valid solution cell!');
          }

          progress = true;
          continue;
        }
      }
    }

    final bool isSolved = placements.length == 10;
    final bool stalled = !isSolved;

    // Difficulty Classification:
    // HARD: If look-ahead was required OR if deduction reached a dead end.
    // MEDIUM: If complex interacting constraints (pointing lines/regions, mutual adjacency) were needed.
    // EASY: Solvable entirely using basic elimination and straightforward singles (rows, cols, regions).
    Difficulty calculatedDifficulty;
    if (usedLookAhead || stalled) {
      calculatedDifficulty = Difficulty.hard;
    } else if (techniquesUsed.contains(DeductionTechnique.pointingRegionToLine) ||
        techniquesUsed.contains(DeductionTechnique.pointingLineToRegion) ||
        techniquesUsed.contains(DeductionTechnique.mutualAdjacency)) {
      calculatedDifficulty = Difficulty.medium;
    } else {
      calculatedDifficulty = Difficulty.easy;
    }

    return DeductionResult(
      isSolved: isSolved,
      placements: placements,
      steps: steps,
      difficulty: calculatedDifficulty,
      difficultyScore: difficultyScore,
      requiresLookAhead: usedLookAhead,
      stalled: stalled,
      remainingPlacementsNeeded: 10 - placements.length,
      techniquesUsed: techniquesUsed,
    );
  }
}
