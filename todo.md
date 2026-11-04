# SnapDog – Step 4: Complete Gameplay UI Redesign

Redesign the existing SnapDog gameplay screen using the previously supplied reference images.

## Reference instructions

- Reference Image 1: Existing SnapDog implementation. Preserve its functionality.
- Reference Image 2: Primary reference for gameplay layout, hierarchy, and arrangement.
- Reference Image 3: Primary reference for 3D clay pets, colorful board tiles, and character styling.

Do not generate new images. Use the dog artwork/assets already supplied or available in the project. If additional breed assets are missing, create clearly documented placeholders and report them rather than silently using unrelated artwork.

## 1. Overall visual identity

Build a polished, playful, premium casual mobile puzzle game.

Design characteristics:
- Soft pastel color palette.
- Warm cream background.
- Rounded cards and controls.
- Colorful rounded board tiles.
- 3D clay-style dog characters.
- Soft shadows and subtle depth.
- Friendly, readable typography.
- Consistent spacing and alignment.

Avoid excessive gradients, clutter, and oversized decorative elements.

## 2. Gameplay header

Redesign the top section inspired by Reference Image 2.

Include:
- Back button.
- Puzzle level and puzzle name.
- Score or progress.
- Settings button.
- Timer.
- Mistake counter (0/3).

Keep this area compact.

## 3. Rules section

Display the game rules in compact illustrated cards:

- One dog per row.
- One dog per column.
- One dog per color region.
- Dogs cannot touch, including diagonally.

Use small grid illustrations and concise text.

Do not allow this section to consume too much vertical space.

## 4. Automatic Dog Breed Assignment

Introduce different 3D clay dog breeds.

Initial breeds:
- Corgi.
- Shiba Inu.
- Pug.
- Husky.
- Golden Retriever.
- Beagle.

Requirements:

- Automatically assign different breeds to the ten dog placements in each puzzle.
- Do not require manual breed selection.
- Use a deterministic assignment for a given puzzle so the same puzzle always displays the same breed arrangement.
- Use a balanced distribution across available breeds.
- Repeated breeds are allowed because there are ten placements and fewer initial breeds.
- Ensure every breed has consistent proportions, lighting, image quality, and visual style.
- Keep dog images centered and properly scaled inside board cells.
- Do not let breed identity affect puzzle validation, placement correctness, or the verified solution.

IMPORTANT:
The breeds are visual variations of the same game object: a dog. All existing placement and validation rules must remain exactly the same.

## 5. Puzzle board redesign

Use Reference Image 3 for the visual direction.

Requirements:
- Preserve the existing 10x10 board.
- Preserve all existing region boundaries and puzzle data.
- Use rounded square tiles.
- Introduce subtle shadows and raised tile styling.
- Use coordinated pastel region colors.
- Make dog illustrations prominent and recognizable.
- Keep X markers large, bold, and clearly visible.
- Maintain sufficient contrast.
- Provide clear visual distinction between empty, crossed, selected, and dog-occupied cells.

Do not make the board so decorative that cell boundaries become difficult to identify.

## 6. Screen layout

Organize the screen in this order:

1. Compact gameplay header.
2. Game rules.
3. Dog breed preview/character collection.
4. Puzzle board.
5. Bottom action controls.

The board should receive the largest possible usable screen area.

Avoid unnecessary vertical scrolling on standard Android phones.

Use responsive sizing for smaller devices.

## 7. Bottom controls

Redesign:
- Undo.
- Reset.
- Hint.

Use compact circular or rounded controls with clear icons and labels.

Preserve all existing functionality and confirmation dialogs.

## 8. Existing gameplay behavior – MUST PRESERVE

Do not modify:
- Single tap to mark/unmark X.
- Double tap to place a dog.
- Dragging across cells to mark multiple Xs.
- One undo action for an entire drag.
- Correct dog locking.
- Three-mistake limit.
- Wrong placement feedback.
- Hint behavior.
- Puzzle completion.
- Daily challenges.
- Puzzle progression.
- Local persistence.
- Sound and haptic settings.

Do not introduce interaction delays or gesture conflicts.

## 9. Code quality

- Reuse existing widgets and architecture where practical.
- Keep the board responsive.
- Avoid rebuilding the entire board unnecessarily.
- Use reusable components.
- Keep breed assignment separate from puzzle validation.
- Avoid adding unnecessary dependencies.

## 10. Verification

Test:
- All existing gameplay interactions.
- Breed assignment consistency for the same puzzle.
- Correct display of all available breeds.
- Small and large Android screen layouts.
- Dog image scaling and cropping.
- Dialog positioning.
- Board performance during rapid taps and dragging.

Run:
- flutter test
- flutter analyze
- flutter build apk --debug

Provide a summary of the redesigned screen, changed files, breed assignment implementation, and any missing assets.

Do not redesign other application screens in this milestone. Focus only on the gameplay screen.