# SnapDog — Step 3 Implementation Report: Progressive Hint System

**Completed Date**: 2026-11-05  
**Component**: SnapDog Puzzle Intelligence System — Step 3  
**Status**: Completed & Verified  

---

## 1. Executive Summary

Step 3 introduces an explanation-based, progressive three-stage hint system to SnapDog without altering the game's core rules, artwork, region coloring, or level progression. The hint architecture directly leverages the Step 2 logical deduction engine (`DeductionEngine`) and difficulty classifier (`DifficultyClassifier`), providing players with human-understandable guidance, candidate elimination, and forced placement without giving away the entire solution or performing auto-placement.

---

## 2. Files Created and Modified

### Created Files
1. **`lib/features/game/models/progressive_hint.dart`**
   - Declares `HintStage` (`guidance`, `elimination`, `placement`).
   - Declares the immutable `ProgressiveHint` model containing stage metadata, user-friendly titles, messages, explanations, unit identifiers, highlighted cells/rows/cols/regions, target forced placement cells, candidate eliminations, remaining dog count, and deduction technique.
2. **`lib/features/game/services/hint_service.dart`**
   - Implements `HintService.generateHint(...)` operating on `Puzzle` and `currentPlacements`.
   - Reuses `DeductionEngine.analyze` with `initialPlacements` and `allowLookAhead: true`.
   - Never treats player-marked crosses as mathematically proven eliminations.
   - Mathematically verifies that eliminated candidate cells and target cells strictly conform to the unique solution.
3. **`test/hint_system_step3_test.dart`**
   - Implements all 12 test specifications required by Section 7.
4. **`docs/step3_implementation_report.md`**
   - Full documentation and verification report.

### Modified Files
1. **`lib/features/game/providers/game_provider.dart`**
   - Added progressive hint state (`activeHint`, `hintStage`, `highlightedCells`, `highlightedRow`, `highlightedCol`, `highlightedRegion`) to `PuzzleGameState`.
   - Added helper methods `isHintEliminatedAt`, `isHintHighlightedAt`, and updated `isHintCellAt` to display the exact hint pulsing paw on the board exclusively during Stage 3 (placement) or fallback.
   - Added `requestHint()`, `requestNextHintStage()`, and `dismissHint()`.
   - Added duplicate deduction protection (`_hintRevealedForCurrentBoardState`): hints are deducted only when revealed for the first time on a board state.
   - Clears stale hints and board highlights on any board change (`singleTapCell`, `doubleTapCell`, `endDragCross`, `undo`, `resetPuzzle`, `loadLevel`).
2. **`lib/features/game/widgets/puzzle_board_widget.dart`**
   - Extended `_CellVisualState` to observe `isHintHighlighted` and `isHintEliminated`.
   - Enhanced `_CellView` to render gentle, non-destructive highlights:
     - Guided units (row/col/region): subtle warm amber glow (`Color.lerp(regionColor, 0xFFFFF9C4, 0.35)`).
     - Eliminated cells: subtle soft peach tint (`Color.lerp(regionColor, 0xFFFFCDD2, 0.45)`).
     - Forced cell (Stage 3): pulsing gold ring and golden paw icon (`ValueKey('cell_hint')`).
3. **`lib/features/game/widgets/hint_dialog.dart`**
   - Converted to `ConsumerWidget` observing `puzzleGameProvider`.
   - Renders animated corgi illustration, "Puppy Hint" title, and progressive clue badge:
     - `Clue 1 of 3: Guidance`
     - `Clue 2 of 3: Elimination`
     - `Clue 3 of 3: Placement`
   - Dynamically updates content when "Next Clue" is tapped without dismissing and reopening the overlay.
   - Maintained full-width primary "Got it" button and compact "Next Clue" text button with bounded constraints to prevent layout overflow.
4. **`lib/features/game/screens/game_screen.dart`**
   - Ensures `dismissHint()` is invoked when the hint dialog overlay is dismissed.

---

## 3. Examples of All Three Hint Stages

Taking **Level 1 (Puppy Park)** as an example:

### Stage 1: Constraint Guidance
- **Clue Badge**: `Clue 1 of 3: Guidance`
- **Title**: `Row Constraint`
- **Message**: `10 puppies remain. Row 1 must contain exactly one puppy. Look closely at the available cells in this row.`
- **Board Visualization**: Row 1 is subtly tinted with a warm amber glow.
- **Placement**: `targetCell: null` (no exact cell is revealed).

### Stage 2: Logical Elimination
- **Clue Badge**: `Clue 2 of 3: Elimination`
- **Title**: `Row Elimination`
- **Message**: `In Row 1, several cells cannot contain a puppy due to dogs in adjacent rows, columns, or color regions.`
- **Explanation**: Deduction engine trace detailing candidate cell exclusions based on neighboring line and region rules.
- **Board Visualization**: Candidate cells that cannot mathematically hold a dog in Row 1 are highlighted with a soft peach tint.
- **Placement**: `targetCell: null` (does not give away the answer).

### Stage 3: Exact Placement
- **Clue Badge**: `Clue 3 of 3: Placement`
- **Title**: `Forced Puppy Placement`
- **Message**: `A puppy must be placed at Row 1, Column 8. It is the only remaining valid candidate for Row 1.`
- **Board Visualization**: Cell (0, 7) displays a pulsing gold aura and paw icon.
- **Action**: The puppy is **never auto-placed**. The player must tap the cell on the board to place the dog.

---

## 4. How Deductions Are Selected

1. **Board State Initialization**: `DeductionEngine.analyze` is invoked with `puzzle`, `initialPlacements: currentPlacements`, and `allowLookAhead: true`.
2. **Ignoring Player Mistakes**: Player `crosses` (manual X marks) are deliberately omitted from the deduction engine. The engine evaluates strictly verified rules and placed dogs, ensuring that mistaken player crosses are never assumed to be mathematically impossible.
3. **Step Filtering**: The deduction engine produces a sequence of steps. Steps corresponding to already placed dogs are filtered out, isolating the genuine forward deductions available from the current board state.
4. **Priority Hierarchy**:
   - **Single Placements**: Naked singles in rows, hidden singles in columns, or hidden singles in regions (`nakedSingleRow`, `hiddenSingleColumn`, `hiddenSingleRegion`).
   - **Line-Region Reductions**: Pointing constraints (`pointingRegionToLine`, `pointingLineToRegion`) and mutual adjacency (`mutualAdjacency`).
   - **Controlled Look-Ahead**: Single-hypothesis contradictions (`lookAheadContradiction`), clearly distinguished as trial-based reasoning.
   - **Honest Fallback**: When forward single passes are constrained, the solver identifies the next unplaced dog from `puzzle.solution` and provides honest constraint guidance without inventing false deductions.
5. **Solution Invariance**: All candidate eliminations and forced placements are verified against `puzzle.solution` via assertions and safety checks.

---

## 5. How Hint Usage Is Persisted

- **Deduction Rule**: When `requestHint()` is called, `_hintRevealedForCurrentBoardState` is checked.
  - If a hint has not yet been revealed for the current board state, `hintsUsed` increments by 1 and `_hintRevealedForCurrentBoardState` is set to `true`.
  - Rapid taps, reopening an active hint, advancing stages ("Next Clue"), and dismissing the dialog do **not** increment `hintsUsed`.
  - Modifying the board (`singleTapCell`, `doubleTapCell`, `endDragCross`, `undo`, `resetPuzzle`, `loadLevel`) resets `_hintRevealedForCurrentBoardState` to `false` and clears active hints.
- **Persistence Across Restarts**: `_saveCurrentInProgress()` commits `hintsUsed` along with level number, placements, crosses, timer, and mistakes to `InProgressPuzzleState` in `SharedPreferences`.
- **Level Scoping**: When a level is loaded via `loadLevel()`, if an in-progress session exists for that exact level, `hintsUsed` is restored; otherwise, `hintsUsed` initializes to 0.

---

## 6. Verification and Test Results

### Automated Tests (`test/hint_system_step3_test.dart`)
All 12 specific scenarios required by Section 7 pass:

| # | Test Scenario | Status |
|---|---|---|
| 1 | Hint 1 provides valid constraint guidance | **PASSED** |
| 2 | Hint 2 provides a valid elimination explanation | **PASSED** |
| 3 | Hint 3 identifies a genuinely forced cell | **PASSED** |
| 4 | Hints never contradict the unique solution across levels | **PASSED** |
| 5 | Hints update after the player places a dog | **PASSED** |
| 6 | Manually marked X cells are not treated as proven eliminations | **PASSED** |
| 7 | Stale hints are cleared after board changes | **PASSED** |
| 8 | Hint count is deducted exactly once | **PASSED** |
| 9 | Hint usage persists correctly across app restarts and level loads | **PASSED** |
| 10 | System works on a procedurally generated Level 10 puzzle | **PASSED** |
| 11 | System works on generated puzzles with level > 9 (Levels 12 and 15) | **PASSED** |
| 12 | No hardcoded nine-level assumption exists in hint implementation | **PASSED** |

### Complete Test Suite
- `flutter test`: **202 / 202 tests passed** (0 failures, 100% pass rate).
- `flutter analyze`: **0 issues found**.
- `flutter build apk --debug`: **Built successfully** in 22.7s.

---

## 7. Confirmation of Unlimited Level Support ($\ge 10$)

- Handcrafted puzzles (Levels 1–9) and procedurally generated puzzles (Level 10 onwards, up to Level 999+) are fully supported.
- `HintService` operates strictly on the input `Puzzle` object and `currentPlacements`. It contains no checks for `levelNumber <= 9` or hardcoded lists of 9 puzzles.
- Puzzle difficulty is dynamically evaluated using `DifficultyClassifier.classify(puzzle)`.

---

## 8. Limitations & Scope Compliance

- **No Auto-Placement**: Players must tap the board to place dogs; hints do not automatically modify dog placements.
- **Visual Integrity Preserved**: Region colors remain visually distinguishable and are never permanently overridden.
- **Board Layout Unchanged**: The 10x10 board structure and grid dimensions are preserved.
- **Progression Unchanged**: Level progression logic and unlock systems remain identical.
- **Scope Boundary**: Development concluded at Step 3; Step 4 has not been started.
