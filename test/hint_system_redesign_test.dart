import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/core/services/sound_service.dart';
import 'package:snapdog/core/utils/sound_haptic_helper.dart';
import 'package:snapdog/features/game/models/progressive_hint.dart';
import 'package:snapdog/features/game/providers/game_provider.dart';
import 'package:snapdog/features/game/screens/game_screen.dart';
import 'package:snapdog/features/game/services/hint_service.dart';
import 'package:snapdog/features/game/services/puzzle_repository.dart';
import 'package:snapdog/features/game/widgets/hint_banner_widget.dart';
import 'package:snapdog/features/game/widgets/puzzle_board_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundService.instance.resetTestingState();
    SoundService.instance.init(soundEnabled: false, volume: 0.0);
    SoundHapticHelper.soundEnabled = false;
    SoundHapticHelper.hapticsEnabled = false;
  });

  group('SnapDog — Progressive Hint Experience Redesign Tests', () {
    // 1. Stage 1 highlights the correct complete connected region
    test('1. Stage 1 highlights the correct complete connected region', () {
      final puzzle = PuzzleRepository.getPuzzleByLevel(1);
      final hint = HintService.generateHint(
        puzzle: puzzle,
        currentPlacements: const [],
        stage: HintStage.guidance,
      );

      expect(hint.stage, equals(HintStage.guidance));
      expect(hint.highlightedCells, isNotEmpty);

      if (hint.highlightedRegion != null) {
        // Collect all cells belonging to this region
        final expectedCells = <Point<int>>{};
        for (int r = 0; r < 10; r++) {
          for (int c = 0; c < 10; c++) {
            if (puzzle.getRegionAt(r, c) == hint.highlightedRegion) {
              expectedCells.add(Point(r, c));
            }
          }
        }
        expect(hint.highlightedCells, equals(expectedCells),
            reason: 'Stage 1 must highlight the complete connected color region');
      } else if (hint.highlightedRow != null) {
        expect(hint.highlightedCells.length, equals(10));
      } else if (hint.highlightedCol != null) {
        expect(hint.highlightedCells.length, equals(10));
      }
    });

    // 2. Region descriptions identify the actual visible region, never just an internal region ID
    test('2. Region descriptions identify the actual visible region, never just an internal region ID', () {
      final puzzle = PuzzleRepository.getPuzzleByLevel(1);

      // Verify all 10 regions have visual color and location descriptions
      for (int reg = 0; reg < 10; reg++) {
        final desc = HintService.describeRegion(puzzle, reg);
        expect(desc, isNotEmpty);

        // Must never contain raw internal identifiers
        expect(desc.contains(RegExp(r'Region \d+')), isFalse);

        // Must contain a color descriptor
        final colorName = HintService.getRegionColorName(reg);
        expect(desc.contains(colorName), isTrue,
            reason: 'Description for region $reg should include color $colorName');

        // Must contain spatial position keywords
        final hasSpatialWord = desc.contains('top') ||
            desc.contains('bottom') ||
            desc.contains('left') ||
            desc.contains('right') ||
            desc.contains('center');
        expect(hasSpatialWord, isTrue,
            reason: 'Description must specify board location: $desc');
      }

      // Verify generated hint messages do not contain internal region IDs
      for (int lvl = 1; lvl <= 5; lvl++) {
        final p = PuzzleRepository.getPuzzleByLevel(lvl);
        for (final stage in HintStage.values) {
          final hint = HintService.generateHint(
            puzzle: p,
            currentPlacements: const [],
            stage: stage,
          );
          expect(hint.message.contains(RegExp(r'(?:Color\s+)?[Rr]egion\s+\d+')), isFalse,
              reason: 'Hint message contains raw region ID: "${hint.message}"');
        }
      }
    });

    // 3. Stage 1 does not reveal the exact solution cell
    test('3. Stage 1 does not reveal the exact solution cell', () {
      final puzzle = PuzzleRepository.getPuzzleByLevel(1);
      final hint = HintService.generateHint(
        puzzle: puzzle,
        currentPlacements: const [],
        stage: HintStage.guidance,
      );

      expect(hint.stage, equals(HintStage.guidance));
      expect(hint.targetCell, isNull, reason: 'Hint targetCell must be null in Stage 1');

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);
      notifier.requestHint();

      final state = notifier.state;
      expect(state.hintStage, equals(HintStage.guidance));
      expect(state.hintCell, isNull, reason: 'State hintCell must be null in Stage 1');

      for (int r = 0; r < 10; r++) {
        for (int c = 0; c < 10; c++) {
          expect(state.isHintCellAt(r, c), isFalse,
              reason: 'isHintCellAt must be false for all cells during Stage 1');
        }
      }
    });

    // 4. Stage 2 highlights only logically eliminated candidates relevant to the deduction
    test('4. Stage 2 highlights only logically eliminated candidates relevant to the deduction', () {
      final puzzle = PuzzleRepository.getPuzzleByLevel(1);
      final hint = HintService.generateHint(
        puzzle: puzzle,
        currentPlacements: const [],
        stage: HintStage.elimination,
      );

      expect(hint.stage, equals(HintStage.elimination));
      expect(hint.targetCell, isNull);
      expect(hint.eliminatedCandidates, isNotEmpty);

      // Eliminated candidates must NEVER include any solution dog
      for (final elim in hint.eliminatedCandidates) {
        final isSolution = puzzle.solution.any((p) => p.row == elim.x && p.col == elim.y);
        expect(isSolution, isFalse,
            reason: 'Eliminated candidate ($elim) cannot be in the solution!');
      }
    });

    // 5. Stage 2 does not treat manual X marks as proven eliminations
    test('5. Stage 2 does not treat manual X marks as proven eliminations', () {
      final puzzle = PuzzleRepository.getPuzzleByLevel(1);
      final solDog = puzzle.solution.first;

      // Suppose the player incorrectly placed an X on an actual solution dog cell
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);
      notifier.singleTapCell(solDog.row, solDog.col); // Places X on solution dog cell

      expect(notifier.state.hasCrossAt(solDog.row, solDog.col), isTrue);

      // Request hint: deduction engine must ignore manual X marks and find true logical deduction
      notifier.requestHint();
      notifier.requestNextHintStage(); // Stage 2
      notifier.requestNextHintStage(); // Stage 3

      final hint3 = notifier.state.activeHint!;
      expect(hint3.targetCell, isNotNull);
      expect(puzzle.solution.any((p) => p.row == hint3.targetCell!.x && p.col == hint3.targetCell!.y), isTrue);
    });

    // 6. Stage 3 highlights a genuinely forced cell
    test('6. Stage 3 highlights a genuinely forced cell', () {
      final puzzle = PuzzleRepository.getPuzzleByLevel(1);
      final hint = HintService.generateHint(
        puzzle: puzzle,
        currentPlacements: const [],
        stage: HintStage.placement,
      );

      expect(hint.stage, equals(HintStage.placement));
      expect(hint.targetCell, isNotNull, reason: 'Stage 3 must identify the forced target cell');

      final target = hint.targetCell!;
      final isPartOfSolution = puzzle.solution.any((p) => p.row == target.x && p.col == target.y);
      expect(isPartOfSolution, isTrue, reason: 'Stage 3 target must be part of verified puzzle solution');
      expect(hint.highlightedCells.contains(target), isTrue);
    });

    // 7. The board remains visible and interactive during hints
    testWidgets('7. The board remains visible and interactive during hints', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Hint button to show banner
      await tester.tap(find.text('Hint'));
      await tester.pumpAndSettle();

      // Banner is shown
      expect(find.byType(HintBannerWidget), findsOneWidget);

      // Board is visible
      final boardFinder = find.byType(PuzzleBoardWidget);
      expect(boardFinder, findsOneWidget);

      // Tap a cell on the board to mark an X (interactive while hint is displayed)
      // Cell (0, 0)
      await tester.tap(find.byKey(const ValueKey('cell_0_0')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Marking the board clears the hint highlights and banner
      expect(find.byType(HintBannerWidget), findsNothing);
    });

    // 8. The hint banner does not obscure important board cells
    testWidgets('8. The hint banner does not obscure important board cells', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hint'));
      await tester.pumpAndSettle();

      expect(find.byType(HintBannerWidget), findsOneWidget);
      expect(find.byType(PuzzleBoardWidget), findsOneWidget);

      final bannerRect = tester.getRect(find.byType(HintBannerWidget));
      final boardRect = tester.getRect(find.byType(PuzzleBoardWidget));

      // Banner must be strictly above the board and must NOT overlap any board cell
      expect(bannerRect.overlaps(boardRect), isFalse,
          reason: 'Hint banner must not overlap or obscure the board');
      expect(bannerRect.bottom, lessThanOrEqualTo(boardRect.top + 2.0));
    });

    // 9. Highlights disappear when the hint is dismissed
    test('9. Highlights disappear when the hint is dismissed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);
      notifier.requestHint();

      expect(notifier.state.activeHint, isNotNull);
      expect(notifier.state.highlightedCells, isNotEmpty);

      // Dismiss the hint
      notifier.dismissHint();

      expect(notifier.state.activeHint, isNull);
      expect(notifier.state.highlightedCells, isEmpty);
      expect(notifier.state.hintCell, isNull);
      expect(notifier.state.highlightedRegion, isNull);
      expect(notifier.state.highlightedRow, isNull);
      expect(notifier.state.highlightedCol, isNull);
    });

    // 10. Hints refresh correctly after dog placement
    test('10. Hints refresh correctly after dog placement', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);

      // Advance to Stage 3 to get forced placement
      notifier.requestHint();
      notifier.requestNextHintStage();
      notifier.requestNextHintStage();

      final firstTarget = notifier.state.hintCell!;

      // Player taps cell to place the dog
      notifier.singleTapCell(firstTarget.x, firstTarget.y);

      // Board has 1 dog placed and active hint is dismissed
      expect(notifier.state.dogCount, equals(1));
      expect(notifier.state.activeHint, isNull);

      // Request fresh hint
      notifier.requestHint();
      notifier.requestNextHintStage();
      notifier.requestNextHintStage();

      final secondTarget = notifier.state.hintCell!;
      expect(secondTarget, isNot(equals(firstTarget)),
          reason: 'Next hint must identify a different remaining puppy position');
    });

    // 11. Hint usage is deducted only once per board state
    test('11. Hint usage is deducted only once per board state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);
      expect(notifier.state.hintsUsed, equals(0));

      // 1st request -> hintsUsed: 1
      notifier.requestHint();
      expect(notifier.state.hintsUsed, equals(1));

      // Repeated requests on same board state -> still 1
      notifier.requestHint();
      expect(notifier.state.hintsUsed, equals(1));

      // Advancing through stages -> still 1
      notifier.requestNextHintStage();
      expect(notifier.state.hintsUsed, equals(1));
      notifier.requestNextHintStage();
      expect(notifier.state.hintsUsed, equals(1));

      // Dismiss and re-request -> still 1
      notifier.dismissHint();
      notifier.requestHint();
      expect(notifier.state.hintsUsed, equals(1));

      // Place a dog (new board state)
      final solDog = notifier.state.puzzle.solution.first;
      notifier.doubleTapCell(solDog.row, solDog.col);

      // Request hint for new board state -> hintsUsed: 2
      notifier.requestHint();
      expect(notifier.state.hintsUsed, equals(2));
    });

    // 12. Hints work on both handcrafted and procedurally generated levels above Level 9
    test('12. Hints work on both handcrafted and procedurally generated levels above Level 9', () {
      // Handcrafted levels
      for (int lvl = 1; lvl <= 9; lvl++) {
        final puzzle = PuzzleRepository.getPuzzleByLevel(lvl);
        for (final stage in HintStage.values) {
          final hint = HintService.generateHint(
            puzzle: puzzle,
            currentPlacements: const [],
            stage: stage,
          );
          expect(hint.message, isNotEmpty);
          expect(hint.message.contains(RegExp(r'(?:Color\s+)?[Rr]egion\s+\d+')), isFalse);
        }
      }

      // Procedurally generated levels above Level 9
      for (final lvl in [10, 12, 15, 20]) {
        final puzzle = PuzzleRepository.getPuzzleByLevel(lvl);
        expect(puzzle.levelNumber, equals(lvl));
        expect(puzzle.size, equals(10));

        for (final stage in HintStage.values) {
          final hint = HintService.generateHint(
            puzzle: puzzle,
            currentPlacements: const [],
            stage: stage,
          );
          expect(hint.message, isNotEmpty);
          expect(hint.message.contains(RegExp(r'(?:Color\s+)?[Rr]egion\s+\d+')), isFalse);
          if (stage == HintStage.placement) {
            expect(hint.targetCell, isNotNull);
            expect(puzzle.solution.any((p) => p.row == hint.targetCell!.x && p.col == hint.targetCell!.y), isTrue);
          }
        }
      }
    });

    // 13. Small-screen layouts do not overflow
    testWidgets('13. Small-screen layouts do not overflow', (tester) async {
      // Simulate small Android screen (e.g. 320 x 568 px)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open hint (Stage 1)
      await tester.tap(find.text('Hint'));
      await tester.pumpAndSettle();
      expect(find.byType(HintBannerWidget), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Small screen Stage 1 must not overflow');

      // Next clue (Stage 2)
      await tester.tap(find.text('Next clue'));
      await tester.pumpAndSettle();
      expect(find.byType(HintBannerWidget), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Small screen Stage 2 must not overflow');

      // Next clue (Stage 3)
      await tester.tap(find.text('Next clue'));
      await tester.pumpAndSettle();
      expect(find.byType(HintBannerWidget), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Small screen Stage 3 must not overflow');

      // Dismiss
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.byType(HintBannerWidget), findsNothing);
      expect(tester.takeException(), isNull, reason: 'Small screen dismissed must not overflow');
    });

    // 14. Existing gameplay and progression tests continue passing
    test('14. Existing gameplay rules and progression remain intact', () {
      final puzzle = PuzzleRepository.getPuzzleByLevel(1);
      expect(puzzle.solution.length, equals(10));
      expect(puzzle.size, equals(10));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(puzzleGameProvider.notifier);
      expect(notifier.state.dogCount, equals(0));

      // Tap cell to place cross
      notifier.singleTapCell(3, 3);
      expect(notifier.state.hasCrossAt(3, 3), isTrue);

      // Single tap again to remove cross
      notifier.singleTapCell(3, 3);
      expect(notifier.state.hasCrossAt(3, 3), isFalse);
    });
  });
}
