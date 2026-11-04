import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/features/game/models/dog_breed.dart';
import 'package:snapdog/features/game/models/dog_placement.dart';
import 'package:snapdog/features/game/models/puzzle.dart';
import 'package:snapdog/features/game/screens/game_screen.dart';
import 'package:snapdog/features/game/widgets/dog_breed_collection_row.dart';
import 'package:snapdog/features/game/widgets/game_header.dart';
import 'package:snapdog/features/game/widgets/game_rules_card.dart';
import 'package:snapdog/features/game/widgets/puzzle_board_widget.dart';
import 'package:snapdog/shared/widgets/cute_dog_character.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SnapDog – Step 4: Gameplay UI Redesign & Dog Breed System Tests', () {
    final testPuzzle = Puzzle(
      id: 'test_puzzle_redesign_1',
      title: 'Sunny Garden',
      difficulty: Difficulty.easy,
      levelNumber: 1,
      regionMap: List.generate(10, (r) => List.generate(10, (c) => (r ~/ 2))),
      solution: const [
        DogPlacement(0, 0),
        DogPlacement(1, 2),
        DogPlacement(2, 4),
        DogPlacement(3, 6),
        DogPlacement(4, 8),
        DogPlacement(5, 1),
        DogPlacement(6, 3),
        DogPlacement(7, 5),
        DogPlacement(8, 7),
        DogPlacement(9, 9),
      ],
    );

    test('1. Dog Breed Assignment is deterministic and consistent for the same puzzle', () {
      final assignment1 = DogBreedAssignment.forPuzzle(testPuzzle);
      final assignment2 = DogBreedAssignment.forPuzzle(testPuzzle);

      expect(assignment1.orderedBreeds.length, equals(10));
      expect(assignment2.orderedBreeds.length, equals(10));
      expect(assignment1.orderedBreeds, equals(assignment2.orderedBreeds));

      // Coordinate query returns identical results
      for (final p in testPuzzle.solution) {
        expect(
          assignment1.getBreedAt(p.row, p.col),
          equals(assignment2.getBreedAt(p.row, p.col)),
        );
      }
    });

    test('2. All 6 Dog Breeds are represented across the 10 puzzle placements', () {
      final assignment = DogBreedAssignment.forPuzzle(testPuzzle);
      final uniqueBreeds = assignment.orderedBreeds.toSet();

      expect(uniqueBreeds.contains(DogBreed.corgi), isTrue);
      expect(uniqueBreeds.contains(DogBreed.shibaInu), isTrue);
      expect(uniqueBreeds.contains(DogBreed.pug), isTrue);
      expect(uniqueBreeds.contains(DogBreed.husky), isTrue);
      expect(uniqueBreeds.contains(DogBreed.goldenRetriever), isTrue);
      expect(uniqueBreeds.contains(DogBreed.beagle), isTrue);
      expect(uniqueBreeds.length, equals(6));
    });

    testWidgets('3. All 6 Dog Breeds render cleanly without exceptions in CuteDogCharacter', (tester) async {
      for (final breed in DogBreed.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CuteDogCharacter(
                  breed: breed,
                  size: 40,
                  hasClash: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CuteDogCharacter), findsOneWidget);
      }
    });

    testWidgets('4. GameRulesCard displays 3 compact illustrated mini rules', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameRulesCard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GameRulesCard), findsOneWidget);
      expect(find.text('1 Dog per\ncolor'), findsOneWidget);
      expect(find.text('1 Dog per\nrow & col'), findsOneWidget);
      expect(find.text('Dogs cannot\ntouch'), findsOneWidget);
    });

    testWidgets('5. GameHeader renders Back, Level, Dogs, Settings, 3 Bone Treat lives, and Timer', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GameHeader(
                onBack: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      expect(find.text('Dogs: 0/10'), findsOneWidget);
      expect(find.textContaining('Level'), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('6. Complete GameScreen hierarchy renders in exact required order without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 5 layers are present
      expect(find.byType(GameHeader), findsOneWidget);
      expect(find.byType(GameRulesCard), findsOneWidget);
      expect(find.byType(DogBreedCollectionRow), findsOneWidget);
      expect(find.byType(PuzzleBoardWidget), findsOneWidget);

      // Verify vertical ordering: Header top < Rules < Breed Row < Board
      final headerTop = tester.getTopLeft(find.byType(GameHeader)).dy;
      final rulesTop = tester.getTopLeft(find.byType(GameRulesCard)).dy;
      final breedRowTop = tester.getTopLeft(find.byType(DogBreedCollectionRow)).dy;
      final boardTop = tester.getTopLeft(find.byType(PuzzleBoardWidget)).dy;

      expect(headerTop, lessThan(rulesTop));
      expect(rulesTop, lessThan(breedRowTop));
      expect(breedRowTop, lessThan(boardTop));
    });

    testWidgets('7. Board renders cleanly without overflow on small 320x568 Android screen', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PuzzleBoardWidget), findsOneWidget);
    });
  });
}
