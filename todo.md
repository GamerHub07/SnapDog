# SnapDog – Step 5: Gameplay Experience & Feedback Polish

Improve the gameplay experience of the existing SnapDog Flutter application. Focus on sound effects, animations, visual feedback, and the level-completion experience.

**Important:** The existing gameplay UI and puzzle logic are approved. Do not redesign the gameplay screen, change the board layout, modify puzzle rules, or break any existing functionality.

## 1. Sound Effects

First inspect the existing codebase to determine whether sound effects have already been implemented. Reuse existing functionality and implement only what is missing.

Add appropriate short sound effects for:

- Dog placed correctly – satisfying success sound.
- Cross/X marked – subtle pop.
- Incorrect dog placement – gentle error sound.
- Undo – reverse pop.
- Hint used – sparkle sound.
- Button interaction – subtle click.
- Level completed – cheerful celebration sound.

Requirements:
- Use locally bundled audio assets.
- Use a dedicated AudioManager or SoundService.
- Avoid downloading sounds at runtime.
- Prevent overlapping sounds from becoming unpleasant.
- Add sound on/off and volume controls in Settings.
- Persist sound preferences locally.
- Keep sound and haptics settings independent.
- Gracefully handle missing audio assets.

Do not generate new artwork or audio using AI. Use existing assets or clearly document any missing assets.

## 2. Dog Placement Animations

Add polished, lightweight animations:

- Correct dog placement: subtle scale-up and bounce.
- Correct dog locked into the board: gentle glow or success feedback.
- X marking: quick pop animation.
- Undo: subtle reverse animation.
- Hint: highlight the suggested cell with a pulsing animation.

Animations should feel responsive and should not delay user interactions.

## 3. Mistake Feedback

Improve the existing wrong-placement feedback:

- Preserve the existing mistake popup design.
- Add a brief shake animation to the incorrect cell.
- Play the error sound.
- Update the mistake counter exactly once.
- Remove the incorrect dog as currently implemented.
- Preserve the three-mistake limit.

Do not add unnecessary animations that make the game feel slow.

## 4. Level Completion Experience

Create a polished level-completion screen or overlay.

It should include:
- A cheerful celebration animation.
- A happy dog illustration using existing assets.
- "Level Completed!" heading.
- Completion time.
- Number of mistakes.
- Hints used.
- A button to continue to the next level.
- A button to return to the level selection screen, if one exists.

Requirements:
- Trigger completion only when all puzzle conditions are satisfied.
- Prevent multiple completion events for the same puzzle.
- Save progress exactly once.
- Stop the timer after completion.
- Preserve the existing level progression and daily challenge logic.
- Ensure the next-level button loads the correct next puzzle.

## 5. Settings

Verify that the settings screen provides:
- Sound toggle.
- Sound volume control.
- Haptics toggle.

Persist these preferences and apply them immediately.

## 6. Performance and Compatibility

- Keep animations lightweight and suitable for Android devices.
- Avoid unnecessary widget rebuilds.
- Dispose of animation controllers and audio resources properly.
- Ensure sounds and animations do not interfere with double-tap dog placement or drag-to-mark-X gestures.
- Test on different screen sizes.

## 7. Testing

Verify:
- Correct dog placement feedback.
- Wrong placement feedback and mistake counting.
- Undo behavior.
- Hint behavior.
- Sound settings persistence.
- Haptics settings persistence.
- Completion screen appears exactly once.
- Timer stops after completion.
- Next-level progression works correctly.
- Existing daily challenge behavior remains intact.

Run:

```bash
flutter test
flutter analyze
flutter build apk --debug
```

## Final Instructions

Do not change the approved gameplay layout or puzzle mechanics.

Do not replace the current dog artwork in this milestone. We will handle consistent dog illustrations separately.

At the end, provide:
1. Features implemented.
2. Files created or modified.
3. Audio assets used and their locations.
4. Tests performed and their results.
5. Any remaining issues.

Implement carefully, preserving all existing working functionality.