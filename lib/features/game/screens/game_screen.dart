import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/game_provider.dart';
import '../widgets/game_controls.dart';
import '../widgets/game_header.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/hint_dialog.dart';
import '../widgets/mistake_dialog.dart';
import '../widgets/pause_dialog.dart';
import '../widgets/puzzle_board_widget.dart';
import '../../daily_challenge/models/daily_challenge_record.dart';
import '../../daily_challenge/providers/daily_challenge_provider.dart';
import '../../daily_challenge/screens/daily_completion_screen.dart';
import '../../progression/providers/progression_provider.dart';
import 'game_completion_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int puzzleIndex;
  final bool isDailyChallenge;
  final DateTime? dailyDate;

  const GameScreen({
    super.key,
    this.puzzleIndex = 0,
    this.isDailyChallenge = false,
    this.dailyDate,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  DailyCompletionResult? _dailyResult;
  bool _hasRecordedDaily = false;

  bool _isExitDialogOpen = false;
  bool _isExiting = false;
  bool _isMistakeDialogOpen = false;
  bool _isHintDialogOpen = false;

  void _confirmExit() {
    if (_isExitDialogOpen || _isExiting) return;
    _isExitDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Leave Puzzle?', style: AppTextStyles.titleLarge),
          content: const Text(
            'Are you sure you want to leave this puzzle? Your current progress may be lost.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Keep Playing',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _isExiting = true;
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Quit',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isExitDialogOpen = false;
        });
      } else {
        _isExitDialogOpen = false;
      }
    });
  }

  void _recordDailyIfCompleted(PuzzleGameState gameState) {
    if (widget.isDailyChallenge && gameState.isCompleted && !gameState.isGameOver && !_hasRecordedDaily) {
      _hasRecordedDaily = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final result = await ref.read(dailyChallengeProvider.notifier).recordDailyCompletion(
          puzzle: gameState.puzzle,
          timeSeconds: gameState.timerSeconds,
          hintsUsed: gameState.hintsUsed,
          mistakes: gameState.mistakes,
          completionDate: widget.dailyDate,
        );
        if (mounted) {
          setState(() {
            _dailyResult = result;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(puzzleGameProvider);

    ref.listen<PuzzleGameState>(puzzleGameProvider, (previous, next) {
      if (previous != null) {
        // Trigger mistake popup if mistake count increased, it is not Game Over,
        // and no dialog is currently open.
        if (next.mistakes > previous.mistakes &&
            !next.isGameOver &&
            !_isMistakeDialogOpen &&
            !_isExitDialogOpen &&
            !_isExiting) {
          _isMistakeDialogOpen = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            MistakeDialog.show(
              context,
              mistakes: next.mistakes,
              message: next.contextualMessage,
              onDismissed: () {
                if (mounted) {
                  setState(() {
                    _isMistakeDialogOpen = false;
                  });
                } else {
                  _isMistakeDialogOpen = false;
                }
              },
            ).then((_) {
              if (mounted) {
                setState(() {
                  _isMistakeDialogOpen = false;
                });
              } else {
                _isMistakeDialogOpen = false;
              }
            });
          });
        }

        // Trigger hint popup if hint count increased, it is not Game Over,
        // and no dialog is currently open.
        if (next.hintsUsed > previous.hintsUsed &&
            !next.isGameOver &&
            !_isHintDialogOpen &&
            !_isExitDialogOpen &&
            !_isExiting) {
          _isHintDialogOpen = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            HintDialog.show(
              context,
              hintsUsed: next.hintsUsed,
              message: next.contextualMessage,
              onDismissed: () {
                if (mounted) {
                  setState(() {
                    _isHintDialogOpen = false;
                  });
                } else {
                  _isHintDialogOpen = false;
                }
              },
            ).then((_) {
              if (mounted) {
                setState(() {
                  _isHintDialogOpen = false;
                });
              } else {
                _isHintDialogOpen = false;
              }
            });
          });
        }
      }
    });

    _recordDailyIfCompleted(gameState);

    // If game completed in daily challenge mode, show DailyCompletionScreen
    if (gameState.isCompleted && widget.isDailyChallenge) {
      final dailyState = ref.watch(dailyChallengeProvider);
      final activeDate = widget.dailyDate ?? ref.watch(clockProvider)();
      final streak = _dailyResult?.streakDays ?? dailyState.getEffectiveStreak(activeDate);
      final longestStreak = _dailyResult?.longestStreakDays ?? dailyState.longestStreak;
      final newlyUnlocked = _dailyResult?.newlyUnlockedRewards ?? const <DailyReward>[];

      return DailyCompletionScreen(
        date: activeDate,
        timeSeconds: gameState.timerSeconds,
        hintsUsed: gameState.hintsUsed,
        mistakes: gameState.mistakes,
        currentStreak: streak,
        longestStreak: longestStreak,
        newlyUnlockedRewards: newlyUnlocked,
        onHome: () {
          _isExiting = true;
          Navigator.pop(context);
        },
      );
    }

    // If regular game completed, show standard completion screen
    if (gameState.isCompleted) {
      final progress = ref.watch(progressionProvider).getProgress(gameState.puzzle.id);
      final bestTime = progress?.bestTimeSeconds;
      final isNewBest = bestTime != null && gameState.timerSeconds <= bestTime;

      return GameCompletionScreen(
        timeSeconds: gameState.timerSeconds,
        hintsUsed: gameState.hintsUsed,
        mistakes: gameState.mistakes,
        puzzleTitle: gameState.puzzle.title,
        bestTimeSeconds: bestTime,
        isNewBestTime: isNewBest,
        onNextPuzzle: () {
          ref.read(puzzleGameProvider.notifier).nextPuzzle();
        },
        onReplay: () {
          ref.read(puzzleGameProvider.notifier).resetPuzzle();
        },
        onHome: () {
          _isExiting = true;
          Navigator.pop(context);
        },
      );
    }

    return PopScope(
      canPop: _isExiting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Header with back, puzzle title, timer, dogs counter
                  GameHeader(
                    onBack: _confirmExit,
                  ),

                  // 10x10 Puzzle Board
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                      child: Center(
                        child: PuzzleBoardWidget(),
                      ),
                    ),
                  ),

                  // Controls (Undo, Reset, Hint)
                  const GameControls(),
                  const SizedBox(height: 12),
                ],
              ),

              // Pause Overlay
              if (gameState.isPaused)
                PauseDialog(
                  timerSeconds: gameState.timerSeconds,
                  difficultyLabel: gameState.puzzle.title,
                  onResume: () {
                    ref.read(puzzleGameProvider.notifier).togglePause();
                  },
                  onRestart: () {
                    ref.read(puzzleGameProvider.notifier).resetPuzzle();
                    ref.read(puzzleGameProvider.notifier).togglePause();
                  },
                  onQuit: () {
                    _isExiting = true;
                    Navigator.pop(context);
                  },
                ),

              // Game Over Overlay (3-mistake limit reached)
              if (gameState.isGameOver)
                GameOverDialog(
                  onRetry: () {
                    ref.read(puzzleGameProvider.notifier).resetPuzzle();
                  },
                  onHome: () {
                    _isExiting = true;
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
