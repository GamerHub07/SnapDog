# SnapDog – Loading Screen & Board Border Refinement

Make only the following targeted changes. Preserve the existing layouts and functionality.

## 1. Region Boundary Borders

The latest region borders have become too light and difficult to distinguish.

Adjust them to a medium-strength muted brown.

Suggested styling:
- Region boundary color: #A88A76 or #9B7C68.
- Region boundary thickness: approximately 2–2.5 logical pixels.
- Ordinary cell grid lines should remain thinner and lighter.
- Avoid thick double borders where regions meet.

The borders should be clearly visible at normal phone viewing size without dominating the pastel board.

Do not change the region color palette.

## 2. Loading Quote Typography

The loading quote currently looks too small.

Improve it:
- Increase quote font size to approximately 25–30 logical pixels, adapting to screen size.
- Use a friendly, rounded font with medium or semibold weight.
- Use a warm dark-brown or muted coral color.
- Center-align the quote.
- Keep sufficient line spacing.
- Support longer quotes with graceful wrapping.
- Avoid clipping on smaller devices.

The quote should be the main visual focus of the loading screen.

## 3. Fix Blank/Black Startup Before Loading Screen

Currently, the app shows a blank or black screen for several seconds before the loading screen appears briefly.

This must be fixed.

Investigate the actual Android and Flutter startup lifecycle.

Requirements:

1. Configure the Android native launch screen/splash screen to use the same warm cream background as SnapDog.
2. Show the SnapDog loading screen as the very first Flutter frame.
3. Display the logo, quote and loading indicator immediately after Flutter starts.
4. Start asynchronous initialization only after the loading screen is visible.
5. Keep the loading screen visible while required initialization runs.
6. Navigate to Home only after essential startup tasks finish.

Inspect:
- Android launch theme.
- Android splash screen configuration.
- Flutter main() and runApp().
- Any initialization performed before runApp().
- Asset loading and precaching.
- Audio and local storage initialization.

Do not perform long synchronous operations before runApp().

If an essential initialization task must happen before Flutter starts, ensure the Android native splash screen remains visible throughout that period.

## 4. Smooth Transition

- Use a subtle fade transition from native splash to Flutter loading screen.
- Avoid showing a black frame between them.
- Avoid a flash of the Home screen before initialization finishes.
- Do not add an artificial loading delay.
- Keep the loading screen visible for the actual duration of initialization.
- Once initialization is complete, transition smoothly to Home.

## 5. Validation

Test:
- Cold launch after force-stopping the app.
- First launch after installation.
- Subsequent launches.
- Slow initialization.
- Loading failures.
- Different Android screen sizes.

Verify that there is no blank or black interval before the loading screen.

Run:

flutter test
flutter analyze
flutter build apk --debug

Report what caused the startup delay and exactly how it was fixed.

Do not change any other UI or gameplay functionality.