import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../providers/game_provider.dart';

class GameHeader extends ConsumerWidget {
  final VoidCallback onBack;

  const GameHeader({
    super.key,
    required this.onBack,
  });

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(puzzleGameProvider);
    final puzzle = gameState.puzzle;
    final dogCount = gameState.dogCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              IconButton(
                onPressed: onBack,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowWarm,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.text, size: 20),
                ),
              ),

              // Puzzle Title & Difficulty Badge
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryLight, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PawIcon(size: 15, color: AppColors.primaryDark),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${puzzle.title} (${puzzle.difficultyLabel})',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Timer & Pause Button
              GestureDetector(
                onTap: () {
                  ref.read(puzzleGameProvider.notifier).togglePause();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowWarm,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        gameState.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        color: AppColors.primaryDark,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(gameState.timerSeconds),
                        style: AppTextStyles.titleSmall.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dogs Placed Counter & Status Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dogs Placed Counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.cardBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      PawIcon(
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dogs: $dogCount/10',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Mistakes Counter (Mistakes: 0/3)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: gameState.mistakes > 0 ? const Color(0xFFFFF0F0) : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: gameState.mistakes > 0
                            ? AppColors.clashRed.withValues(alpha: 0.4)
                            : AppColors.cardBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: gameState.mistakes > 0 ? AppColors.clashRed : AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Mistakes: ${gameState.mistakes}/3',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: gameState.mistakes > 0 ? AppColors.clashRed : AppColors.text,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contextual Message Banner (Rule violation or Hint message)
          if (gameState.contextualMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 6, right: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: gameState.contextualMessage == 'A little pup belongs here!'
                      ? const Color(0xFFFFF8E1)
                      : const Color(0xFFFFECEE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: gameState.contextualMessage == 'A little pup belongs here!'
                        ? AppColors.gold
                        : AppColors.clashRed.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    if (gameState.contextualMessage == 'A little pup belongs here!')
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          AppAssets.corgiThinking,
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.lightbulb_rounded,
                            size: 16,
                            color: AppColors.gold,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.clashRed,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        gameState.contextualMessage!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: gameState.contextualMessage == 'A little pup belongs here!'
                              ? const Color(0xFF8D6E14)
                              : AppColors.clashRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
