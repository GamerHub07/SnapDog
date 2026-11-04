import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/sound_haptic_helper.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../game/models/puzzle.dart';
import '../../game/providers/game_provider.dart';
import '../../game/screens/game_screen.dart';
import '../../game/services/puzzle_repository.dart';
import '../models/progression_state.dart';
import '../providers/progression_provider.dart';
import '../widgets/puzzle_card.dart';

class PuzzleSelectionScreen extends ConsumerStatefulWidget {
  const PuzzleSelectionScreen({super.key});

  @override
  ConsumerState<PuzzleSelectionScreen> createState() => _PuzzleSelectionScreenState();
}

class _PuzzleSelectionScreenState extends ConsumerState<PuzzleSelectionScreen> {
  Difficulty _selectedDifficulty = Difficulty.easy;

  void _openPuzzle(Puzzle puzzle) {
    final puzzleIndex = PuzzleRepository.getPuzzleIndex(puzzle);
    ref.read(puzzleGameProvider.notifier).loadPuzzle(puzzleIndex);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(puzzleIndex: puzzleIndex),
      ),
    );
  }

  void _showLockedMessage(Puzzle puzzle, ProgressionState progression) {
    SoundHapticHelper.errorVibrate();

    String message;
    if (!progression.isDifficultyUnlocked(puzzle.difficulty)) {
      message = 'Unlock ${puzzle.difficulty.label} by completing all puzzles in the previous tier!';
    } else {
      message = 'This level is locked! Complete preceding puzzles to unlock.';
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.text,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(milliseconds: 2400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progression = ref.watch(progressionProvider);
    final puzzlesForDifficulty = PuzzleRepository.getPuzzlesByDifficulty(_selectedDifficulty);
    final completedCount = progression.completedCountForDifficulty(_selectedDifficulty);
    final totalCount = puzzlesForDifficulty.length;
    final nextAvailable = progression.getNextAvailablePuzzle();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const PawIcon(size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              'Select Puzzle',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Difficulty Category Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowWarm,
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: Difficulty.values.map((diff) {
                    final isSelected = diff == _selectedDifficulty;
                    final unlocked = progression.isDifficultyUnlocked(diff);

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          SoundHapticHelper.lightTap();
                          setState(() => _selectedDifficulty = diff);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                diff.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (unlocked ? AppColors.text : AppColors.textMuted),
                                ),
                              ),
                              if (!unlocked) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.lock_rounded,
                                  size: 13,
                                  color: isSelected ? Colors.white : AppColors.textMuted,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Progress banner for selected difficulty
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 18,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedDifficulty.label} Progress',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$completedCount/$totalCount Completed',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Grid of Puzzle Cards
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: puzzlesForDifficulty.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final puzzle = puzzlesForDifficulty[index];
                  final isUnlocked = progression.isPuzzleUnlocked(puzzle.id);
                  final progress = progression.getProgress(puzzle.id);
                  final isCurrentAvailable = !progression.isPuzzleCompleted(puzzle.id) &&
                      puzzle.id == nextAvailable.id;

                  return PuzzleCard(
                    puzzle: puzzle,
                    progress: progress,
                    isUnlocked: isUnlocked,
                    isCurrentAvailable: isCurrentAvailable,
                    onTap: () => _openPuzzle(puzzle),
                    onLockedTap: () => _showLockedMessage(puzzle, progression),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
