import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapdog/features/game/models/dog_placement.dart';
import 'package:snapdog/features/game/models/puzzle.dart';
import 'package:snapdog/features/game/services/puzzle_repository.dart';
import 'package:snapdog/features/progression/models/progression_state.dart';
import 'package:snapdog/features/progression/models/puzzle_progress.dart';
import 'package:snapdog/features/progression/providers/progression_provider.dart';
import 'package:snapdog/features/progression/services/progression_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('SnapDog – Milestone 3: Progression & Unlocking Engine', () {
    test('1. Initial unlock state: only Easy Level 1 is unlocked', () {
      final progression = container.read(progressionProvider);

      expect(progression.completedPuzzlesCount, equals(0));
      expect(progression.isDifficultyUnlocked(Difficulty.easy), isTrue);
      expect(progression.isDifficultyUnlocked(Difficulty.medium), isFalse);
      expect(progression.isDifficultyUnlocked(Difficulty.hard), isFalse);

      // Level 1 of Easy is unlocked
      expect(progression.isPuzzleUnlocked('puzzle_1'), isTrue);

      // All other puzzles are locked
      for (int i = 2; i <= 9; i++) {
        expect(
          progression.isPuzzleUnlocked('puzzle_$i'),
          isFalse,
          reason: 'puzzle_$i must be locked initially',
        );
      }

      // Next available is puzzle_1
      expect(progression.getNextAvailablePuzzle().id, equals('puzzle_1'));
      expect(progression.getResumePuzzle().id, equals('puzzle_1'));
    });

    test('2. Completing a puzzle unlocks the next puzzle in that difficulty', () {
      final notifier = container.read(progressionProvider.notifier);
      final p1 = PuzzleRepository.getPuzzleById('puzzle_1');

      // Complete puzzle_1
      final success = notifier.recordCompletion(
        puzzle: p1,
        placements: p1.solution,
        timeSeconds: 45,
        hintsUsed: 1,
        mistakes: 0,
      );

      expect(success, isTrue);

      final state = container.read(progressionProvider);
      expect(state.isPuzzleCompleted('puzzle_1'), isTrue);
      expect(state.completedPuzzlesCount, equals(1));

      // puzzle_2 (Easy level 2) is now unlocked!
      expect(state.isPuzzleUnlocked('puzzle_2'), isTrue);

      // puzzle_3 (Easy level 3) is still locked
      expect(state.isPuzzleUnlocked('puzzle_3'), isFalse);

      // Next available is now puzzle_2
      expect(state.getNextAvailablePuzzle().id, equals('puzzle_2'));
    });

    test('3. Replaying completed puzzles: previously completed puzzles remain unlocked', () {
      final notifier = container.read(progressionProvider.notifier);
      final p1 = PuzzleRepository.getPuzzleById('puzzle_1');

      notifier.recordCompletion(
        puzzle: p1,
        placements: p1.solution,
        timeSeconds: 50,
        hintsUsed: 0,
        mistakes: 0,
      );

      final state = container.read(progressionProvider);
      expect(state.isPuzzleCompleted('puzzle_1'), isTrue);
      expect(state.isPuzzleUnlocked('puzzle_1'), isTrue);

      // Replay puzzle_1 again with a new attempt
      final replaySuccess = notifier.recordCompletion(
        puzzle: p1,
        placements: p1.solution,
        timeSeconds: 40,
        hintsUsed: 0,
        mistakes: 0,
      );

      expect(replaySuccess, isTrue);
      final replayedState = container.read(progressionProvider);
      expect(replayedState.isPuzzleCompleted('puzzle_1'), isTrue);
      expect(replayedState.isPuzzleUnlocked('puzzle_1'), isTrue);
    });

    test('4. Easy completion unlocks Medium tier (first Medium puzzle)', () {
      final notifier = container.read(progressionProvider.notifier);
      final p1 = PuzzleRepository.getPuzzleById('puzzle_1');
      final p2 = PuzzleRepository.getPuzzleById('puzzle_2');
      final p3 = PuzzleRepository.getPuzzleById('puzzle_3');

      // Medium is locked initially
      expect(container.read(progressionProvider).isDifficultyUnlocked(Difficulty.medium), isFalse);
      expect(container.read(progressionProvider).isPuzzleUnlocked('puzzle_4'), isFalse);

      // Complete puzzle 1
      notifier.recordCompletion(puzzle: p1, placements: p1.solution, timeSeconds: 30, hintsUsed: 0, mistakes: 0);
      expect(container.read(progressionProvider).isDifficultyUnlocked(Difficulty.medium), isFalse);

      // Complete puzzle 2
      notifier.recordCompletion(puzzle: p2, placements: p2.solution, timeSeconds: 35, hintsUsed: 0, mistakes: 0);
      expect(container.read(progressionProvider).isDifficultyUnlocked(Difficulty.medium), isFalse);

      // Complete final puzzle of Easy (puzzle 3)
      notifier.recordCompletion(puzzle: p3, placements: p3.solution, timeSeconds: 40, hintsUsed: 0, mistakes: 0);

      final state = container.read(progressionProvider);
      // Easy is 100% completed
      expect(state.completedCountForDifficulty(Difficulty.easy), equals(3));

      // Medium tier is now unlocked!
      expect(state.isDifficultyUnlocked(Difficulty.medium), isTrue);

      // First Medium puzzle (puzzle_4) is unlocked!
      expect(state.isPuzzleUnlocked('puzzle_4'), isTrue);

      // Second Medium puzzle (puzzle_5) is still locked
      expect(state.isPuzzleUnlocked('puzzle_5'), isFalse);

      // Hard is still locked
      expect(state.isDifficultyUnlocked(Difficulty.hard), isFalse);
    });

    test('5. Medium completion unlocks Hard tier (first Hard puzzle)', () {
      final notifier = container.read(progressionProvider.notifier);

      // Complete all 3 Easy puzzles
      for (int i = 1; i <= 3; i++) {
        final p = PuzzleRepository.getPuzzleById('puzzle_$i');
        notifier.recordCompletion(puzzle: p, placements: p.solution, timeSeconds: 30, hintsUsed: 0, mistakes: 0);
      }

      expect(container.read(progressionProvider).isDifficultyUnlocked(Difficulty.hard), isFalse);

      // Complete Medium puzzles 4 and 5
      for (int i = 4; i <= 5; i++) {
        final p = PuzzleRepository.getPuzzleById('puzzle_$i');
        notifier.recordCompletion(puzzle: p, placements: p.solution, timeSeconds: 35, hintsUsed: 0, mistakes: 0);
      }
      expect(container.read(progressionProvider).isDifficultyUnlocked(Difficulty.hard), isFalse);

      // Complete final Medium puzzle 6
      final p6 = PuzzleRepository.getPuzzleById('puzzle_6');
      notifier.recordCompletion(puzzle: p6, placements: p6.solution, timeSeconds: 40, hintsUsed: 0, mistakes: 0);

      final state = container.read(progressionProvider);
      expect(state.completedCountForDifficulty(Difficulty.medium), equals(3));

      // Hard tier is now unlocked!
      expect(state.isDifficultyUnlocked(Difficulty.hard), isTrue);

      // First Hard puzzle (puzzle_7) is unlocked!
      expect(state.isPuzzleUnlocked('puzzle_7'), isTrue);

      // Second Hard puzzle (puzzle_8) is still locked
      expect(state.isPuzzleUnlocked('puzzle_8'), isFalse);
    });

    test('6. Locked puzzles cannot be opened', () {
      final state = container.read(progressionProvider);

      // Locked puzzles report false for isPuzzleUnlocked
      expect(state.isPuzzleUnlocked('puzzle_2'), isFalse);
      expect(state.isPuzzleUnlocked('puzzle_5'), isFalse);
      expect(state.isPuzzleUnlocked('puzzle_8'), isFalse);
    });

    test('7. Best time updates correctly on faster attempt', () {
      final notifier = container.read(progressionProvider.notifier);
      final p1 = PuzzleRepository.getPuzzleById('puzzle_1');

      // First attempt: 60 seconds
      notifier.recordCompletion(
        puzzle: p1,
        placements: p1.solution,
        timeSeconds: 60,
        hintsUsed: 2,
        mistakes: 1,
      );

      final firstProgress = container.read(progressionProvider).getProgress('puzzle_1');
      expect(firstProgress?.bestTimeSeconds, equals(60));
      expect(firstProgress?.lastTimeSeconds, equals(60));

      // Second attempt: faster (42 seconds)
      notifier.recordCompletion(
        puzzle: p1,
        placements: p1.solution,
        timeSeconds: 42,
        hintsUsed: 0,
        mistakes: 0,
      );

      final secondProgress = container.read(progressionProvider).getProgress('puzzle_1');
      expect(secondProgress?.bestTimeSeconds, equals(42)); // Updated to better time
      expect(secondProgress?.lastTimeSeconds, equals(42));
    });

    test('8. Best time is preserved when a slower attempt is completed', () {
      final notifier = container.read(progressionProvider.notifier);
      final p1 = PuzzleRepository.getPuzzleById('puzzle_1');

      // Best attempt: 35 seconds
      notifier.recordCompletion(
        puzzle: p1,
        placements: p1.solution,
        timeSeconds: 35,
        hintsUsed: 0,
        mistakes: 0,
      );

      expect(container.read(progressionProvider).getProgress('puzzle_1')?.bestTimeSeconds, equals(35));

      // Slower replay attempt: 75 seconds
      notifier.recordCompletion(
        puzzle: p1,
        placements: p1.solution,
        timeSeconds: 75,
        hintsUsed: 1,
        mistakes: 2,
      );

      final progress = container.read(progressionProvider).getProgress('puzzle_1');
      expect(progress?.bestTimeSeconds, equals(35)); // Preserved 35 seconds!
      expect(progress?.lastTimeSeconds, equals(75)); // Last time is 75
      expect(progress?.hintsUsed, equals(1));
      expect(progress?.mistakes, equals(2));
    });

    test('9. Progress survives persistence save and load', () async {
      final stateToSave = ProgressionState(
        lastPlayedPuzzleId: 'puzzle_2',
        puzzleProgress: {
          'puzzle_1': PuzzleProgress(
            puzzleId: 'puzzle_1',
            isCompleted: true,
            bestTimeSeconds: 40,
            lastTimeSeconds: 50,
            hintsUsed: 1,
            mistakes: 0,
            completedAt: DateTime(2026, 10, 31, 12, 0),
          ),
          'puzzle_2': PuzzleProgress(
            puzzleId: 'puzzle_2',
            isCompleted: true,
            bestTimeSeconds: 55,
            lastTimeSeconds: 55,
            hintsUsed: 0,
            mistakes: 1,
            completedAt: DateTime(2026, 10, 31, 12, 30),
          ),
        },
      );

      // Save to SharedPreferences
      await ProgressionRepository.saveProgression(stateToSave);

      // Load from SharedPreferences
      final loadedState = await ProgressionRepository.loadProgression();

      expect(loadedState.completedPuzzlesCount, equals(2));
      expect(loadedState.lastPlayedPuzzleId, equals('puzzle_2'));
      expect(loadedState.isPuzzleCompleted('puzzle_1'), isTrue);
      expect(loadedState.isPuzzleCompleted('puzzle_2'), isTrue);

      final p1Loaded = loadedState.getProgress('puzzle_1');
      expect(p1Loaded?.bestTimeSeconds, equals(40));
      expect(p1Loaded?.lastTimeSeconds, equals(50));
      expect(p1Loaded?.hintsUsed, equals(1));
      expect(p1Loaded?.mistakes, equals(0));
      expect(p1Loaded?.completedAt?.year, equals(2026));

      // Verify that puzzle 3 is unlocked because puzzle 2 was completed
      expect(loadedState.isPuzzleUnlocked('puzzle_3'), isTrue);
    });

    test('10. Invalid or incomplete puzzles cannot be marked completed', () {
      final notifier = container.read(progressionProvider.notifier);
      final p1 = PuzzleRepository.getPuzzleById('puzzle_1');

      // Attempt 1: Empty placements
      final emptyResult = notifier.recordCompletion(
        puzzle: p1,
        placements: const [],
        timeSeconds: 30,
        hintsUsed: 0,
        mistakes: 0,
      );
      expect(emptyResult, isFalse);
      expect(container.read(progressionProvider).isPuzzleCompleted('puzzle_1'), isFalse);

      // Attempt 2: 9 dogs (incomplete)
      final incompleteResult = notifier.recordCompletion(
        puzzle: p1,
        placements: p1.solution.take(9).toList(),
        timeSeconds: 30,
        hintsUsed: 0,
        mistakes: 0,
      );
      expect(incompleteResult, isFalse);
      expect(container.read(progressionProvider).isPuzzleCompleted('puzzle_1'), isFalse);

      // Attempt 3: 10 dogs with rule clashes
      final invalidResult = notifier.recordCompletion(
        puzzle: p1,
        placements: List.generate(10, (i) => DogPlacement(0, i)), // Same row
        timeSeconds: 30,
        hintsUsed: 0,
        mistakes: 0,
      );
      expect(invalidResult, isFalse);
      expect(container.read(progressionProvider).isPuzzleCompleted('puzzle_1'), isFalse);
    });
  });
}
