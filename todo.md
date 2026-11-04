# SnapDog – Integrate 3D Clay Dog Artwork

Integrate the six new dog-face PNG illustrations located in `assets/images/dogs/` throughout the existing SnapDog Flutter application.

IMPORTANT: I will manually add the images to this folder. Do not generate, download, modify, or replace any artwork. Use the exact supplied PNG files.

## 1. Dog Asset Mapping

Inspect the images and map them to these breeds:

- `beagle.png` – Beagle
- `labrador.png` – Labrador Retriever
- `golden_retriever.png` – Golden Retriever
- `husky.png` – Husky
- `pug.png` – Pug
- `corgi.png` – Corgi

If the filenames differ, identify the images by their appearance and map them correctly. Do not rename or overwrite user assets without permission.

## 2. Flutter Asset Configuration

- Register `assets/images/dogs/` in `pubspec.yaml`.
- Verify all six files are accessible.
- Precache dog images where appropriate.
- Check whether PNGs have transparent backgrounds. If any have opaque black backgrounds, report this instead of displaying unwanted black rectangles or attempting destructive edits.

## 3. Create a Reusable DogAvatar Widget

Create a reusable widget that accepts:
- Dog breed or asset path.
- Image size.
- Optional circular background.
- Optional border.
- Optional animation.

Requirements:
- Use `BoxFit.contain`, not `BoxFit.cover`.
- Preserve the entire dog face, including ears.
- Avoid stretching or cropping.
- Maintain consistent visual sizing across breeds.
- Support transparent backgrounds.

## 4. Replace Existing Dog Artwork

Replace the old dog illustrations in:

- Home screen dog collection.
- Gameplay dog progress indicators.
- Correctly placed dogs on the puzzle board.
- Level-completion screen.
- Any other existing dog avatar locations.

Keep the existing UI layouts, colors, spacing, and interactions unchanged.

## 5. Breed Assignment

- Assign dog breeds automatically to the 10 dog placements.
- Use all six breeds, allowing repeats.
- Make assignments deterministic for a given puzzle so the same puzzle displays the same breeds.
- Keep breeds purely visual; they must not affect puzzle validation or solutions.
- Ensure the same placement retains its assigned breed throughout gameplay.

## 6. Performance

- Use image caching and precaching appropriately.
- Avoid loading the same image repeatedly.
- Ensure smooth scrolling and board interactions.
- Do not introduce unnecessary widget rebuilds.

## 7. Validation

Test all six breeds on:
- Home screen.
- Gameplay board.
- Dog progress indicator.
- Completion screen.

Run:

```bash
flutter pub get
flutter test
flutter analyze
flutter build apk --debug
```

At the end, report the asset mapping, files modified, and any image transparency issues.

Do not change puzzle logic, progression, or the approved UI design.