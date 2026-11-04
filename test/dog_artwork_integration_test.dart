import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/app.dart';
import 'package:snapdog/core/constants/app_assets.dart';
import 'package:snapdog/features/game/models/dog_breed.dart';
import 'package:snapdog/features/game/screens/game_completion_screen.dart';
import 'package:snapdog/features/game/screens/game_screen.dart';
import 'package:snapdog/features/game/services/puzzle_repository.dart';
import 'package:snapdog/features/game/widgets/dog_breed_collection_row.dart';
import 'package:snapdog/features/home/widgets/home_dog_face_row.dart';
import 'package:snapdog/shared/widgets/cute_dog_character.dart';
import 'package:snapdog/shared/widgets/dog_avatar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'snapdog_onboarding_completed': true,
    });
  });

  group('SnapDog – 3D Clay Dog Artwork Integration Tests', () {
    test('1. Asset Mapping: All 6 breeds map to exact supplied PNG files', () {
      expect(DogBreed.beagle.assetPath, equals('assets/images/dogs/beagle.png'));
      expect(DogBreed.corgi.assetPath, equals('assets/images/dogs/corgi.png'));
      expect(DogBreed.goldenRetriever.assetPath, equals('assets/images/dogs/golden_retriever.png'));
      expect(DogBreed.husky.assetPath, equals('assets/images/dogs/husky.png'));
      expect(DogBreed.labrador.assetPath, equals('assets/images/dogs/labrador.png'));
      expect(DogBreed.pug.assetPath, equals('assets/images/dogs/pug.png'));

      expect(AppAssets.allDogAssets.length, equals(6));
      for (final asset in AppAssets.allDogAssets) {
        expect(File(asset).existsSync(), isTrue, reason: 'Asset file $asset must exist on disk');
      }
    });

    test('2. DogBreed enum includes all six breeds with distinct metadata', () {
      final breeds = DogBreed.values;
      expect(breeds.length, equals(6));

      final ids = breeds.map((b) => b.id).toSet();
      expect(ids.length, equals(6));
      expect(ids.contains('beagle'), isTrue);
      expect(ids.contains('corgi'), isTrue);
      expect(ids.contains('golden_retriever'), isTrue);
      expect(ids.contains('husky'), isTrue);
      expect(ids.contains('labrador'), isTrue);
      expect(ids.contains('pug'), isTrue);

      // Backwards compatibility alias
      expect(DogBreed.shibaInu, equals(DogBreed.labrador));
    });

    test('3. Deterministic Breed Assignment across 10 puzzle placements', () {
      final puzzle = PuzzleRepository.puzzles.first;
      final assignment1 = DogBreedAssignment.forPuzzle(puzzle);
      final assignment2 = DogBreedAssignment.forPuzzle(puzzle);

      // 10 dogs total
      expect(assignment1.orderedBreeds.length, equals(10));
      expect(assignment2.orderedBreeds.length, equals(10));

      // Same puzzle always produces exact same breed layout
      for (int i = 0; i < 10; i++) {
        expect(assignment1.orderedBreeds[i], equals(assignment2.orderedBreeds[i]));
      }

      // All 6 breeds are represented
      final uniqueBreeds = assignment1.orderedBreeds.toSet();
      expect(uniqueBreeds.length, equals(6));
      for (final breed in DogBreed.values) {
        expect(uniqueBreeds.contains(breed), isTrue);
      }
    });

    testWidgets('4. Reusable DogAvatar widget renders all breeds with BoxFit.contain', (tester) async {
      for (final breed in DogBreed.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: DogAvatar(
                  breed: breed,
                  size: 44,
                  circularBackground: true,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(DogAvatar), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);

        final imageWidget = tester.widget<Image>(find.byType(Image));
        expect(imageWidget.fit, equals(BoxFit.contain));
      }
    });

    testWidgets('5. Home screen displays all 6 3D dog-face illustrations in HomeDogFaceRow', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SnapDogApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeDogFaceRow), findsOneWidget);
      // All 6 dog avatars inside HomeDogFaceRow
      expect(find.descendant(of: find.byType(HomeDogFaceRow), matching: find.byType(DogAvatar)), findsNWidgets(6));
    });

    testWidgets('6. Gameplay dog progress indicator renders 10 dog avatars', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DogBreedCollectionRow), findsOneWidget);
      expect(find.descendant(of: find.byType(DogBreedCollectionRow), matching: find.byType(DogAvatar)), findsNWidgets(10));
    });

    testWidgets('7. Placed dog on puzzle board renders 3D clay DogAvatar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Double tap cell (0, 7) to place a dog
      final cellFinder = find.byKey(const ValueKey('cell_0_7'));
      expect(cellFinder, findsOneWidget);

      await tester.tap(cellFinder);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(cellFinder);
      await tester.pumpAndSettle();

      // Placed dog renders CuteDogCharacter containing DogAvatar
      expect(find.descendant(of: cellFinder, matching: find.byType(CuteDogCharacter)), findsOneWidget);
      expect(find.descendant(of: cellFinder, matching: find.byType(DogAvatar)), findsOneWidget);
    });

    testWidgets('8. Level completion screen displays celebratory DogAvatars', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GameCompletionScreen(
            timeSeconds: 95,
            hintsUsed: 0,
            mistakes: 0,
            puzzleTitle: 'Puppy Park',
            onNextPuzzle: () {},
            onHome: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GameCompletionScreen), findsOneWidget);
      expect(find.descendant(of: find.byType(GameCompletionScreen), matching: find.byType(DogAvatar)), findsNWidgets(6));
    });
  });
}
