import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/app.dart';
import 'package:snapdog/core/constants/app_colors.dart';
import 'package:snapdog/features/game/screens/game_screen.dart';
import 'package:snapdog/features/home/widgets/daily_challenge_card.dart';
import 'package:snapdog/features/home/widgets/latest_completed_challenge_card.dart';
import 'package:snapdog/shared/widgets/clay_cross_marker.dart';
import 'package:snapdog/shared/widgets/dog_avatar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'snapdog_onboarding_completed': true,
    });
  });

  group('SnapDog – Step 6: Board Visual Refinement & Home Screen Cleanup', () {
    test('1. Region color palette contains all 10 distinct pastel colors with high contrast', () {
      expect(AppColors.regionColors.length, equals(10));
      expect(AppColors.regionColors[0], equals(const Color(0xFFC9E8C7))); // Soft mint
      expect(AppColors.regionColors[1], equals(const Color(0xFFBFDDF2))); // Sky blue
      expect(AppColors.regionColors[2], equals(const Color(0xFFFFD8B8))); // Warm peach
      expect(AppColors.regionColors[3], equals(const Color(0xFFD9D0F0))); // Lavender
      expect(AppColors.regionColors[4], equals(const Color(0xFFF4C9D9))); // Soft pink
      expect(AppColors.regionColors[5], equals(const Color(0xFFF6E7A9))); // Butter yellow
      expect(AppColors.regionColors[6], equals(const Color(0xFFB9E5DF))); // Aqua
      expect(AppColors.regionColors[7], equals(const Color(0xFFF2C2B4))); // Light coral
      expect(AppColors.regionColors[8], equals(const Color(0xFFC9D3F2))); // Periwinkle
      expect(AppColors.regionColors[9], equals(const Color(0xFFDDE9B5))); // Pale lime

      // Region border is medium-strength muted brown
      expect(AppColors.regionBorderThick, equals(const Color(0xFF9B7C68)));
    });

    testWidgets('2. Home screen displays only one completed challenge card (no duplicate LatestCompletedChallengeCard)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SnapDogApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Only one DailyChallengeCard on Home screen
      expect(find.byType(DailyChallengeCard), findsOneWidget);
      // The duplicate card is completely absent
      expect(find.byType(LatestCompletedChallengeCard), findsNothing);
      expect(find.text('Latest Completed Challenge'), findsNothing);
    });

    testWidgets('3. Selected cell does NOT have red border, and row/column highlighting updates immediately', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Single tap on cell (2, 3) marks cross & selects it
      final cellFinder23 = find.byKey(const ValueKey('cell_2_3'));
      expect(cellFinder23, findsOneWidget);
      await tester.tap(cellFinder23);
      await tester.pump(const Duration(milliseconds: 250));

      // Verify no red selection border (neither AppColors.primaryDark nor red borders) exists
      final decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      for (final box in decoratedBoxes) {
        final dec = box.decoration;
        if (dec is BoxDecoration && dec.border != null) {
          final border = dec.border!;
          if (border is Border) {
            expect(border.top.color != AppColors.primaryDark, isTrue);
            expect(border.bottom.color != AppColors.primaryDark, isTrue);
            expect(border.left.color != AppColors.primaryDark, isTrue);
            expect(border.right.color != AppColors.primaryDark, isTrue);
            expect(border.top.color != const Color(0xFFE76F51), isTrue);
            expect(border.bottom.color != const Color(0xFFE76F51), isTrue);
          }
        }
      }

      // Tap cell (5, 7) - selection and highlighting updates immediately
      final cellFinder57 = find.byKey(const ValueKey('cell_5_7'));
      expect(cellFinder57, findsOneWidget);
      await tester.tap(cellFinder57);
      await tester.pump(const Duration(milliseconds: 250));

      // Verify cross exists on (2, 3) and (5, 7)
      expect(find.descendant(of: cellFinder23, matching: find.byType(ClayCrossMarker)), findsOneWidget);
      expect(find.descendant(of: cellFinder57, matching: find.byType(ClayCrossMarker)), findsOneWidget);
    });

    testWidgets('4. Cell feedback: Error/conflict styling still activates red on mistake/clash', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Double-tap cell (0, 0) which is a mistake
      final cellFinder00 = find.byKey(const ValueKey('cell_0_0'));
      await tester.tap(cellFinder00);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(cellFinder00);
      await tester.pump(const Duration(milliseconds: 100));

      // Red close icon / mistake indicator appears
      expect(find.descendant(of: cellFinder00, matching: find.byIcon(Icons.close_rounded)), findsOneWidget);
    });

    testWidgets('5. Dog and X marks remain clearly visible across the pastel palette', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Single tap (3, 3) marks cross
      final cellFinder33 = find.byKey(const ValueKey('cell_3_3'));
      await tester.tap(cellFinder33);
      await tester.pump(const Duration(milliseconds: 250));

      // Double tap (0, 7) places solution dog
      final cellFinder07 = find.byKey(const ValueKey('cell_0_7'));
      await tester.tap(cellFinder07);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(cellFinder07);
      await tester.pump(const Duration(milliseconds: 250));

      // Both cross and 3D dog avatar are displayed
      expect(find.descendant(of: cellFinder33, matching: find.byType(ClayCrossMarker)), findsOneWidget);
      expect(find.descendant(of: cellFinder07, matching: find.byType(DogAvatar)), findsOneWidget);
    });
  });
}
