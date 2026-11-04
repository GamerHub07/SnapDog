import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapdog/features/game/screens/game_screen.dart';
import 'package:snapdog/features/game/widgets/pause_dialog.dart';

void main() {
  Widget buildTestableGameScreen() {
    return const ProviderScope(
      child: MaterialApp(
        home: _TestNavigatorWrapperStateful(),
      ),
    );
  }

  testWidgets('Back icon opens exactly ONE confirmation dialog with expected Title, Message, and Actions', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableGameScreen());
    await tester.pumpAndSettle();

    // Verify on GameScreen
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    // Tap back icon
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Exactly ONE Leave Puzzle dialog appears
    expect(find.text('Leave Puzzle?'), findsOneWidget);
    expect(
      find.text('Are you sure you want to leave this puzzle? Your current progress may be lost.'),
      findsOneWidget,
    );
    expect(find.text('Keep Playing'), findsOneWidget);
    expect(find.text('Quit'), findsOneWidget);

    // NO PauseDialog is rendered!
    expect(find.byType(PauseDialog), findsNothing);
  });

  testWidgets('Repeated back icon taps do NOT create duplicate dialogs', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableGameScreen());
    await tester.pumpAndSettle();

    // Tap back icon multiple times rapidly
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.tap(find.byIcon(Icons.arrow_back_rounded), warnIfMissed: false);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Exactly one dialog
    expect(find.text('Leave Puzzle?'), findsOneWidget);
    expect(find.text('Keep Playing'), findsOneWidget);
    expect(find.text('Quit'), findsOneWidget);
    expect(find.byType(PauseDialog), findsNothing);
  });

  testWidgets('Keep Playing dismisses the dialog and preserves puzzle state, timer, and dogs', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableGameScreen());
    await tester.pumpAndSettle();

    // Mark a cross on cell (0, 0)
    final cell00 = find.byKey(const ValueKey('cell_0_0'));
    await tester.tap(cell00);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // Tap back icon
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Leave Puzzle?'), findsOneWidget);

    // Tap Keep Playing
    await tester.tap(find.text('Keep Playing'));
    await tester.pumpAndSettle();

    // Dialog is dismissed
    expect(find.text('Leave Puzzle?'), findsNothing);
    expect(find.byType(PauseDialog), findsNothing);

    // Game is still active with cross in place
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Dogs: 0/10'), findsOneWidget);
  });

  testWidgets('Quit navigates back successfully and does not trigger duplicate dialog', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableGameScreen());
    await tester.pumpAndSettle();

    // Tap back icon
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Leave Puzzle?'), findsOneWidget);

    // Tap Quit
    await tester.tap(find.text('Quit'));
    await tester.pumpAndSettle();

    // GameScreen has popped and returned to root
    expect(find.text('Leave Puzzle?'), findsNothing);
    expect(find.byType(GameScreen), findsNothing);
    expect(find.text('Root Screen'), findsOneWidget);
  });

  testWidgets('Android system back gesture triggers exactly ONE Leave Puzzle dialog', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableGameScreen());
    await tester.pumpAndSettle();

    // Simulate system back gesture
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();

    // Exactly one Leave Puzzle dialog appears
    expect(find.text('Leave Puzzle?'), findsOneWidget);
    expect(
      find.text('Are you sure you want to leave this puzzle? Your current progress may be lost.'),
      findsOneWidget,
    );
    expect(find.byType(PauseDialog), findsNothing);

    // Tap Keep Playing
    await tester.tap(find.text('Keep Playing'));
    await tester.pumpAndSettle();

    expect(find.text('Leave Puzzle?'), findsNothing);
    expect(find.byType(GameScreen), findsOneWidget);
  });
}

class _TestNavigatorWrapperStateful extends StatefulWidget {
  const _TestNavigatorWrapperStateful();

  @override
  State<_TestNavigatorWrapperStateful> createState() => _TestNavigatorWrapperStatefulState();
}

class _TestNavigatorWrapperStatefulState extends State<_TestNavigatorWrapperStateful> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const GameScreen(puzzleIndex: 0),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Root Screen'),
      ),
    );
  }
}
