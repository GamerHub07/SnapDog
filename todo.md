Redesign the existing SnapDog progressive hint experience to make hints visually understandable, interactive, and directly connected to the puzzle board.

IMPORTANT: Do not rely on external screenshots or reference images. Implement the complete experience using the detailed specifications below.

### 1. Main problem to solve

Currently, hints display messages such as:

"Color Region 4 must contain exactly one puppy."

This is not helpful because:
- Players cannot identify which region is Region 4.
- The hint appears inside a large modal that obscures the puzzle board.
- Players cannot simultaneously read the explanation and understand which cells it refers to.
- The hint explains a constraint but doesn't visually demonstrate how to approach the puzzle.

Replace this experience with a board-first visual hint system.

### 2. Keep the puzzle board visible

This is the most important requirement.

- Remove the large blocking hint modal.
- Never dim or blur the entire gameplay screen when showing a hint.
- Keep the complete puzzle board visible while a hint is active.
- Display the hint explanation in a compact floating banner or dedicated compact area above the board.
- Ensure the banner does not cover important board cells.
- Keep the relevant board cells visible and highlighted.
- The player must be able to understand the explanation and inspect the highlighted cells at the same time.

Use SnapDog's existing warm cream, orange, peach, and brown design language.

The hint banner should have:
- Rounded corners.
- A clean white or warm cream background.
- Subtle shadow.
- Readable, appropriately sized text.
- A small hint-stage indicator.
- Minimal visual clutter.

### 3. Stage 1 — Identify the relevant constraint

Instead of displaying abstract region numbers, visually identify the actual region.

For example, do not display:

"Color Region 4 must contain exactly one puppy."

Display something like:

"The mint-green region in the upper-left still needs one dog. Look at its remaining available cells."

Visual behavior:
- Highlight the complete relevant connected color region on the board.
- Use a subtle outline or glow around the region's boundary.
- Keep its original region color visible.
- If the deduction concerns a row, highlight that row.
- If it concerns a column, highlight that column.
- Highlight only the relevant area, not the entire board.
- Do not reveal the exact correct cell at this stage.

IMPORTANT:
Never refer to regions using internal IDs such as Region 4, Region 7, or Region 9 in player-facing text.

Generate meaningful region descriptions dynamically from their actual visual location and color.

Examples:
- "The mint-green region near the top-left..."
- "The peach region along the right side..."
- "The lavender region near the bottom..."

The description must correctly identify the highlighted region.

### 4. Stage 2 — Show logical elimination visually

Explain how the player can eliminate impossible positions.

Example:

"This dog cannot share its row, column, region, or neighboring cells with another dog. These positions can be eliminated."

The actual explanation must be generated from the deduction engine's real deduction trace.

Visual behavior:
- Highlight the relevant row, column, or region.
- Show cells that are eliminated by the specific deduction.
- Use a distinct but subtle elimination treatment, such as a translucent peach tint and a small cross indicator.
- Keep original region colors recognizable.
- Preserve already placed dogs.
- Never visually suggest that a manually marked X is a mathematically proven elimination.
- Do not highlight unrelated cells.

The player should be able to look at the board and understand which possibilities are being removed and why.

### 5. Stage 3 — Reveal the next logical placement

Example:

"The only possible position for the next dog is Row 7, Column 4."

Visual behavior:
- Highlight the exact cell with a clear gold/orange outline or gentle pulsing effect.
- Show a small paw indicator inside or beside the highlighted cell.
- Explain why the position is forced.
- Do not automatically place the dog.
- The player must tap the highlighted cell to place the dog.

Make sure the highlighted cell is actually forced according to the current deduction engine.

### 6. Progressive hint navigation

Preserve the three-stage hint structure:

1. Guidance.
2. Elimination.
3. Exact placement.

The player should be able to:
- Read the current hint.
- See the corresponding board highlights.
- Request the next clue.
- Dismiss the hint.

Use compact controls:
- "Next clue"
- "Got it"

Do not introduce a large dialog that hides the board.

Clearly indicate the current stage, for example:
"Clue 1 of 3 — Guidance"

Do not reveal all three stages at once.

### 7. Hint state and board interaction

- Use the existing HintService and DeductionEngine.
- Do not create a separate hint-solving algorithm.
- Always calculate hints from the current board state.
- Update highlights and explanations after the player places a dog.
- Clear stale highlights when the board changes.
- Preserve existing hint-counting and persistence behavior.
- Opening or dismissing the hint must not deduct another hint.
- Advancing from one clue stage to another must not deduct another hint for the same board state.

### 8. Visual consistency

- Keep the existing 10×10 board dimensions.
- Preserve the existing pastel region palette.
- Preserve region boundaries and original colors.
- Do not permanently change region colors when showing hints.
- Use overlays, outlines, borders, or small indicators for hint highlights.
- Keep dog artwork unchanged.
- Ensure highlights are distinguishable from manual X marks and normal selected-cell styling.
- Make sure the UI remains usable on small Android screens.

### 9. Accessibility and responsiveness

- Text must remain readable on different screen sizes.
- Avoid covering the board with long explanations.
- Break longer explanations into concise sentences.
- Ensure highlights have sufficient contrast against all region colors.
- Handle hints when the keyboard or system UI changes available screen space.

### 10. Protect existing working features

The following features have already been verified and must not regress:

- Unlimited level progression.
- Continue Level resumes the correct level.
- Next Level opens the next unlocked level.
- Drag-to-mark X.
- Drag-to-remove X.
- Undo after drag gestures.
- Puzzle completion detection.
- Completion screen.
- Next Level flow.
- Daily streak calculation.
- Puzzle generation and difficulty classification.

Do not redesign or modify these features.

### 11. Automated tests

Add or update tests to verify:

1. Stage 1 highlights the correct complete connected region.
2. Region descriptions identify the actual visible region, never just an internal region ID.
3. Stage 1 does not reveal the exact solution cell.
4. Stage 2 highlights only logically eliminated candidates relevant to the deduction.
5. Stage 2 does not treat manual X marks as proven eliminations.
6. Stage 3 highlights a genuinely forced cell.
7. The board remains visible and interactive during hints.
8. The hint banner does not obscure important board cells.
9. Highlights disappear when the hint is dismissed.
10. Hints refresh correctly after dog placement.
11. Hint usage is deducted only once per board state.
12. Hints work on both handcrafted and procedurally generated levels above Level 9.
13. Small-screen layouts do not overflow.
14. Existing gameplay and progression tests continue passing.

### 12. Final report

After implementation, report:
- Files changed.
- How the hint banner is positioned.
- How connected regions are identified and described.
- How each stage is visually represented.
- How hint highlights are cleared.
- Automated test results.
- Confirmation that existing gameplay features remain unchanged.

Stop after this hint redesign. Do not start another feature or redesign the rest of the gameplay screen.