# SnapDog – Step 2: Drag-to-Cross Multi-Cell Interaction

Introduce a drag gesture that allows players to mark multiple cells with crosses in a single continuous movement.

IMPORTANT: Extend the existing gameplay controller and gesture system. Do not duplicate cell interaction logic.

## 1. Expected behavior

When the player touches an empty cell and drags their finger across the board:

- The initial empty cell should receive an X.
- Every subsequent empty cell entered by the finger should also receive an X.
- The X should appear immediately as the finger moves across cells.
- The gesture should work horizontally, vertically, and diagonally.
- Each cell should be processed at most once during one drag gesture.

Example:

If the player drags across five empty cells, all five should receive X markers.

## 2. Cell restrictions

- Empty cells: Mark with X.
- Cells already containing X: Do not duplicate the X.
- Cells containing dogs: Never replace or remove the dog.
- Correct locked dogs: Never modify them.
- Incorrect placements must not be introduced through dragging.

Dragging must ONLY mark crosses. It must never place dogs.

## 3. Gesture recognition

Implement reliable gesture handling without breaking existing interactions.

Requirements:
- A normal single tap should continue marking or toggling X.
- A double tap should continue placing a dog.
- A drag should mark multiple cells.
- Moving the finger should not trigger individual tap or double-tap actions.
- Starting a drag should not accidentally place a dog.
- Use appropriate pointer or gesture tracking to distinguish tapping from dragging.
- Account for small finger movements using a reasonable touch slop threshold.
- Prevent repeated processing of the same cell during one gesture.

## 4. Undo behavior

Treat the entire drag operation as ONE undoable action.

Example:
- Player drags across 6 cells.
- Six X markers are added.
- Player presses Undo.
- All six X markers from that drag are removed together.

If a drag crosses cells that already contain X markers or dogs, only newly added X markers should be included in the undo action.

Undo must not affect existing dogs or previous crosses.

## 5. Visual feedback

- Show X markers immediately as cells are crossed.
- Use a smooth, lightweight pop-in animation.
- Highlight the currently touched cell subtly.
- Keep the X size and style consistent with existing markers.
- Avoid lag while dragging quickly across multiple cells.

## 6. State management

- Track the current drag gesture.
- Track cells visited during the gesture.
- Track only newly added crosses for undo.
- Commit the complete drag action to undo history when the gesture ends.
- Clear temporary gesture state when the pointer is released or canceled.

## 7. Testing

Add tests for:
- Horizontal dragging.
- Vertical dragging.
- Diagonal dragging.
- Fast dragging across multiple cells.
- No duplicate X markers.
- Existing X markers remain unchanged.
- Dog cells remain untouched.
- Locked dogs remain protected.
- Dragging never places dogs.
- One drag produces one undo action.
- Undo restores the correct previous state.
- Drag cancellation behaves safely.
- Single and double taps continue working.

Run flutter test and flutter analyze.

Test the final interaction on a physical Android device.

Do not redesign the screen or change any existing puzzle rules.