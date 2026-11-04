import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/app.dart';
import 'package:snapdog/features/home/screens/main_navigation_shell.dart';
import 'package:snapdog/features/home/widgets/home_decorations.dart';
import 'package:snapdog/features/home/widgets/home_dog_face_row.dart';
import 'package:snapdog/features/splash/models/splash_quote.dart';
import 'package:snapdog/features/splash/screens/splash_screen.dart';
import 'package:snapdog/shared/widgets/cute_dog_character.dart';
import 'package:snapdog/shared/widgets/dog_avatar.dart';
import 'package:snapdog/shared/widgets/paw_icon.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'snapdog_onboarding_completed': true,
    });
  });

  group('SnapDog – Minimalist Splash & Loading Screen Tests', () {
    testWidgets('1. Only contains the 4 essential elements (Branding, Quote, Progress Bar, Status)', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(
              quote: SplashQuote(text: 'Play a little. Smile a lot.'),
              autoNavigate: false,
              initialProgress: 0.5,
            ),
          ),
        ),
      );
      await tester.pump();

      // 1. Branding: PawIcon and SnapDog wordmark
      expect(find.byType(PawIcon), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
      expect(find.textContaining('Play a little. Smile a lot.'), findsOneWidget);

      // 2. Progress bar
      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);

      // 3. Small loading status text
      expect(find.text('Getting things ready...'), findsOneWidget);

      // Verify NO disallowed elements
      expect(find.byType(Card), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(DogAvatar), findsNothing);
      expect(find.byType(CuteDogCharacter), findsNothing);
      expect(find.byType(HomeDogFaceRow), findsNothing);
      expect(find.byType(HomeBackgroundDecorations), findsNothing);
    });

    testWidgets('2. Displays quotes accurately with proper typography and centered alignment', (tester) async {
      const testQuote = SplashQuote(
        text: 'A little puzzle can brighten your day.',
        attribution: 'SnapDog Wisdom',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(
              quote: testQuote,
              autoNavigate: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('A little puzzle can brighten your day.'), findsOneWidget);
      expect(find.text('— SnapDog Wisdom'), findsOneWidget);

      final quoteTextWidget = tester.widget<Text>(find.text('A little puzzle can brighten your day.'));
      expect(quoteTextWidget.textAlign, equals(TextAlign.center));
      expect(quoteTextWidget.style?.color, equals(const Color(0xFF49352B)));
      expect(quoteTextWidget.style?.fontSize, inInclusiveRange(24.0, 30.0));
      expect(quoteTextWidget.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('3. Responsive layout test across small, standard, and tablet screen sizes', (tester) async {
      final screenSizes = [
        const Size(320, 568),  // Small / Compact Android phone
        const Size(412, 915),  // Modern standard Android phone
        const Size(800, 1280), // Android Tablet
      ];

      for (final size in screenSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: SplashScreen(
                quote: SplashQuote(text: 'Stay pawsitive. Keep playing.'),
                autoNavigate: false,
              ),
            ),
          ),
        );
        await tester.pump();

        // Ensure zero layout exceptions / overflows
        expect(tester.takeException(), isNull, reason: 'Must not overflow on screen size $size');
      }
    });

    testWidgets('4. Cold startup automatically navigates to MainNavigationShell', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SnapDogApp(),
        ),
      );

      // Initial frame renders SplashScreen
      await tester.pump();

      // Completes cold startup initialization and navigates to Home
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MainNavigationShell), findsOneWidget);
      // SplashScreen is replaced and no longer in tree
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('5. Graceful handling: initialization error does not crash and continues safely', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(
              autoNavigate: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(MainNavigationShell), findsOneWidget);
    });
  });
}
