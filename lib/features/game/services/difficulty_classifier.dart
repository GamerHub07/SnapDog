import '../models/puzzle.dart';
import '../models/deduction_step.dart';
import 'deduction_engine.dart';
import 'puzzle_solver.dart';

/// Detailed breakdown of how a puzzle's difficulty was determined.
class PuzzleDifficultyAnalysis {
  final Puzzle puzzle;
  final Difficulty difficulty;
  final int difficultyScore;
  final bool isLogicallySolvable;
  final bool requiresLookAhead;
  final bool stalled;
  final int totalDeductionSteps;
  final Set<DeductionTechnique> techniquesUsed;
  final String reasoning;
  final DeductionResult deductionResult;

  const PuzzleDifficultyAnalysis({
    required this.puzzle,
    required this.difficulty,
    required this.difficultyScore,
    required this.isLogicallySolvable,
    required this.requiresLookAhead,
    required this.stalled,
    required this.totalDeductionSteps,
    required this.techniquesUsed,
    required this.reasoning,
    required this.deductionResult,
  });

  @override
  String toString() =>
      'PuzzleDifficultyAnalysis(${puzzle.title}, difficulty: ${difficulty.name}, score: $difficultyScore, solvable: $isLogicallySolvable, lookAhead: $requiresLookAhead)';
}

/// Automatic difficulty classifier based on logical deduction complexity.
///
/// Thresholds and Criteria:
/// - **EASY**:
///   - Solvable using only basic elimination and straightforward singles (rows, columns, regions).
///   - Requires zero multi-unit pointing constraints or look-ahead.
/// - **MEDIUM**:
///   - Requires interacting constraints (Line-Region pointing, Region-Line claiming, or Mutual Adjacency).
///   - Solvable without trial-and-error or look-ahead.
/// - **HARD**:
///   - Requires advanced reasoning, controlled look-ahead (contradiction elimination), or reaches a logical dead end.
///
/// Never classifies a puzzle as EASY based on backtracking solver execution speed.
/// Fully deterministic for the same puzzle input.
class DifficultyClassifier {
  DifficultyClassifier._();

  /// Analyzes and classifies the difficulty of [puzzle].
  static PuzzleDifficultyAnalysis classify(Puzzle puzzle) {
    // 1. Verify uniqueness with Step 1 solver as oracle
    final uniqueResult = PuzzleSolver.validateUniqueness(puzzle);
    final oracleSolution = uniqueResult.isUnique ? uniqueResult.solution : null;

    // 2. Run logical deduction engine
    final deductionResult = DeductionEngine.analyze(
      puzzle,
      allowLookAhead: true,
      oracleSolution: oracleSolution,
    );

    // 3. Formulate transparent reasoning
    final String reasoning;
    if (deductionResult.stalled) {
      reasoning =
          'Hard: Logical deduction reached a dead end at ${deductionResult.placements.length}/10 placements; requires deeper look-ahead.';
    } else if (deductionResult.requiresLookAhead) {
      reasoning =
          'Hard: Required controlled look-ahead contradiction elimination to make forward progress beyond pointing constraints.';
    } else if (deductionResult.techniquesUsed.contains(DeductionTechnique.pointingRegionToLine) ||
        deductionResult.techniquesUsed.contains(DeductionTechnique.pointingLineToRegion) ||
        deductionResult.techniquesUsed.contains(DeductionTechnique.mutualAdjacency)) {
      reasoning =
          'Medium: Required interacting Line-Region pointing constraints and constraint intersections (${deductionResult.steps.length} deduction steps, score: ${deductionResult.difficultyScore}).';
    } else {
      reasoning =
          'Easy: Solvable purely using straightforward forced singles in rows, columns, and color regions (${deductionResult.steps.length} deduction steps, score: ${deductionResult.difficultyScore}).';
    }

    return PuzzleDifficultyAnalysis(
      puzzle: puzzle,
      difficulty: deductionResult.difficulty,
      difficultyScore: deductionResult.difficultyScore,
      isLogicallySolvable: deductionResult.isSolved,
      requiresLookAhead: deductionResult.requiresLookAhead,
      stalled: deductionResult.stalled,
      totalDeductionSteps: deductionResult.steps.length,
      techniquesUsed: deductionResult.techniquesUsed,
      reasoning: reasoning,
      deductionResult: deductionResult,
    );
  }
}
