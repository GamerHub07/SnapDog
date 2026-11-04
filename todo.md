# SnapDog – Gameplay Dialog Fix & Audio Effects

Implement the following improvements in the existing Flutter application.

Preserve all existing gameplay logic, visual identity, puzzle progression, dog locking, three-mistake limit, hints, and haptic feedback.

## A. Fix Board Layout Shifting

Currently, displaying the mistake or hint dialog causes the game board to shift down.

Investigate and fix the root cause.

Requirements:
- Display dialogs as overlays above the gameplay screen.
- Use Flutter showDialog or an appropriate overlay mechanism.
- Never insert dialogs into the normal gameplay Column or widget layout.
- Keep the board in exactly the same position and size before, during, and after the dialog.
- Add a subtle background barrier.
- Prevent multiple dialogs from opening simultaneously.
- Do not rebuild or resize the board unnecessarily when dialogs appear.

## B. Create a Polished Mistake Popup

Replace the existing basic mistake popup with a custom animated dialog.

Design:
- Warm cream background.
- Rounded corners.
- Soft shadow.
- Small sad 3D clay Corgi illustration.
- Heading: "Oops! Wrong Spot"
- Message: "That isn't the right place for this puppy."
- Mistake counter, e.g. 1/3.
- One "Got it" button.

Animation:
- Smooth fade-in.
- Scale from approximately 0.85 to 1.0.
- Gentle shake or bounce on the Corgi.
- Smooth fade-out when dismissed.

Important:
- The dialog must not shift the board.
- Preserve the existing three-mistake behavior.
- The third mistake should show the existing Game Over dialog instead of an ordinary mistake dialog.
- Do not increment mistakes again when the dialog is dismissed.

## C. Improve Hint Dialog

- Use the same overlay approach.
- Keep the board stationary.
- Use a small thinking Corgi illustration.
- Add a gentle fade-and-scale animation.
- Preserve the existing hint logic and hint counter.

## D. Implement Actual Sound Effects

Currently haptic feedback works, but audio effects are missing.

Use audioplayers or another appropriate lightweight Flutter audio package.

Bundle short audio assets locally. Do not fetch audio from the internet during gameplay.

Add these sound effects:

1. Cross marking: soft pop/click.
2. Correct dog placement: pleasant confirmation chime.
3. Wrong dog placement: gentle descending bloop.
4. Dog removal/undo: soft reverse pop.
5. Hint usage: magical sparkle sound.
6. Puzzle completion: cheerful celebration sound.
7. Button interactions: subtle UI click.

Use appropriate short WAV, MP3, or OGG files.

If suitable sound assets do not already exist, source properly licensed assets or create original sound effects. Do not use copyrighted game sounds.

## E. Audio Settings

Update the existing settings screen.

Add:
- Sound Effects: ON/OFF.
- Sound volume slider (0–100%).

Requirements:
- Persist preferences locally.
- Sound should respect the master toggle and volume.
- Muting audio must not disable haptic feedback.
- Haptic settings must remain independent.
- Do not play sound effects when the app is muted.
- Dispose audio resources correctly.

## F. Audio Architecture

Create a dedicated AudioManager or SoundService.

Gameplay widgets and controllers should call methods such as:
- playCrossSound()
- playCorrectPlacementSound()
- playWrongPlacementSound()
- playHintSound()
- playCompletionSound()
- playButtonSound()

Avoid placing audio playback logic directly inside UI widgets.

Prevent overlapping sounds from creating unpleasant audio.

## G. Testing

Test:
- Mistake dialog does not change board position.
- Hint dialog does not change board position.
- Dialog animations do not interfere with gestures.
- Repeated taps cannot open duplicate dialogs.
- Correct sound plays only for correct placements.
- Wrong sound plays for incorrect placements.
- Sound toggle works.
- Volume setting works.
- Audio preferences persist after restart.
- Muting sound does not disable haptics.
- Existing gameplay and mistake-limit tests still pass.

Run:
flutter pub get
flutter test
flutter analyze

Fix all errors and warnings introduced by this implementation.

Finally, provide a summary of the root cause of the board shift, audio assets added, packages introduced, and files changed.