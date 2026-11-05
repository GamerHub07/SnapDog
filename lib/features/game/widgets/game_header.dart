import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../settings/screens/settings_screen.dart';
import '../models/puzzle.dart';
import '../providers/game_provider.dart';

/// Compact gameplay header matching Reference Image 2.
///
/// Features:
/// - Back button (circular clay button)
/// - Level number & Puzzle title
/// - Dogs placement counter ('Dogs: $count/10')
/// - Settings gear button
/// - 3 Golden bone treat lives (lives remaining before game over)
/// - Interactive timer with pause button
class GameHeader extends ConsumerWidget {
  final VoidCallback onBack;
  final VoidCallback? onSettings;

  const GameHeader({
    super.key,
    required this.onBack,
    this.onSettings,
  });

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _difficultyColor(Difficulty diff) {
    switch (diff) {
      case Difficulty.easy:
        return AppColors.success;
      case Difficulty.medium:
        return AppColors.warning;
      case Difficulty.hard:
        return AppColors.primaryDark;
    }
  }

  void _openSettings(BuildContext context) {
    if (onSettings != null) {
      onSettings!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(puzzleGameProvider);
    final puzzle = gameState.puzzle;
    final dogCount = gameState.dogCount;
    final mistakes = gameState.mistakes;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Back | Level & Title | Dogs: 0/10 | Settings
          Row(
            children: [
              // Back Button
              _CircularIconButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: 'Back to menu',
                onTap: onBack,
              ),

              const SizedBox(width: 6),

              // Level & Difficulty Badge (e.g., "LEVEL 12" and a small "HARD" label)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryLight, width: 1.2),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PawIcon(size: 13, color: AppColors.primaryDark),
                        const SizedBox(width: 4),
                        Text(
                          'Level ${puzzle.levelNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: _difficultyColor(puzzle.difficulty),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            puzzle.difficulty.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Dogs Placed Counter (explicitly 'Dogs: $count/10')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowWarm,
                      offset: Offset(0, 1.5),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Text(
                  'Dogs: $dogCount/10',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: dogCount == 10 ? AppColors.success : AppColors.text,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Settings Gear Button
              _CircularIconButton(
                icon: Icons.settings_rounded,
                semanticLabel: 'Settings',
                onTap: () => _openSettings(context),
              ),
            ],
          ),

          const SizedBox(height: 5),

          // Row 2: 3 Golden Bone Treat Lives | Difficulty Pill | Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 3 Golden Bone Treat Lives (Reference Image 2 fish treats equivalent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: mistakes > 0
                        ? AppColors.clashRed.withValues(alpha: 0.35)
                        : AppColors.cardBorder,
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowWarm,
                      offset: Offset(0, 1.5),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BoneTreatLife(isAlive: mistakes < 1),
                    const SizedBox(width: 3),
                    _BoneTreatLife(isAlive: mistakes < 2),
                    const SizedBox(width: 3),
                    _BoneTreatLife(isAlive: mistakes < 3),
                  ],
                ),
              ),

              // Difficulty pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder, width: 1.0),
                ),
                child: Text(
                  puzzle.difficultyLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              // Timer & Pause Button
              GestureDetector(
                onTap: () {
                  ref.read(puzzleGameProvider.notifier).togglePause();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowWarm,
                        offset: Offset(0, 1.5),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        gameState.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        color: AppColors.primaryDark,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(gameState.timerSeconds),
                        style: AppTextStyles.titleSmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  const _CircularIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder, width: 1.3),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowWarm,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.text, size: 18),
          ),
        ),
      ),
    );
  }
}

/// 3D golden bone / treat life indicator.
class _BoneTreatLife extends StatelessWidget {
  final bool isAlive;

  const _BoneTreatLife({required this.isAlive});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isAlive ? 1.0 : 0.85,
      duration: const Duration(milliseconds: 200),
      child: AnimatedOpacity(
        opacity: isAlive ? 1.0 : 0.28,
        duration: const Duration(milliseconds: 200),
        child: CustomPaint(
          size: const Size(18, 14),
          painter: _BoneTreatPainter(isAlive: isAlive),
        ),
      ),
    );
  }
}

class _BoneTreatPainter extends CustomPainter {
  final bool isAlive;

  const _BoneTreatPainter({required this.isAlive});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final boneColor = isAlive ? AppColors.gold : const Color(0xFFBCAAA4);
    final shadowColor = isAlive ? const Color(0xFFD48B00) : const Color(0xFF8D6E63);

    final bonePaint = Paint()..color = boneColor;
    final shadowPaint = Paint()..color = shadowColor.withValues(alpha: 0.35);

    // Subtle drop shadow under bone
    final shadowShaft = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.54),
      width: w * 0.56,
      height: h * 0.38,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(shadowShaft, Radius.circular(h * 0.18)), shadowPaint);

    // Bone shaft
    final shaftRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.5),
      width: w * 0.56,
      height: h * 0.38,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(shaftRect, Radius.circular(h * 0.18)), bonePaint);

    // Left bone knobs
    canvas.drawCircle(Offset(w * 0.24, h * 0.32), h * 0.26, bonePaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.68), h * 0.26, bonePaint);

    // Right bone knobs
    canvas.drawCircle(Offset(w * 0.76, h * 0.32), h * 0.26, bonePaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.68), h * 0.26, bonePaint);

    // Clay highlight on top
    if (isAlive) {
      final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
      canvas.drawCircle(Offset(w * 0.25, h * 0.28), h * 0.10, highlightPaint);
      canvas.drawCircle(Offset(w * 0.50, h * 0.40), h * 0.08, highlightPaint);
      canvas.drawCircle(Offset(w * 0.75, h * 0.28), h * 0.10, highlightPaint);
    } else {
      // Crack mark across center
      final crackPaint = Paint()
        ..color = shadowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(w * 0.42, h * 0.25), Offset(w * 0.58, h * 0.75), crackPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoneTreatPainter oldDelegate) => oldDelegate.isAlive != isAlive;
}
