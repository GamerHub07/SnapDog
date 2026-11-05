import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../models/progressive_hint.dart';

/// A compact, non-modal banner that displays progressive hints above the puzzle board.
///
/// Features:
/// - Keeps the entire 10x10 puzzle board visible and interactive at all times.
/// - Never dims or blurs the gameplay screen or introduces a modal barrier.
/// - Clearly displays the current progressive hint stage (e.g. "Clue 1 of 3 — Guidance").
/// - Uses SnapDog's warm cream, orange, peach, and brown design language.
/// - Provides compact controls ("Next clue" and "Got it") with responsive layout.
class HintBannerWidget extends StatelessWidget {
  final ProgressiveHint hint;
  final VoidCallback onNextClue;
  final VoidCallback onDismiss;

  const HintBannerWidget({
    super.key,
    required this.hint,
    required this.onNextClue,
    required this.onDismiss,
  });

  Color _badgeColor(HintStage stage) {
    switch (stage) {
      case HintStage.guidance:
        return const Color(0xFFE76F51); // Warm terracotta / orange
      case HintStage.elimination:
        return const Color(0xFFD32F2F); // Soft crimson
      case HintStage.placement:
        return const Color(0xFF2E7D32); // Soft forest green
    }
  }

  Color _badgeBgColor(HintStage stage) {
    switch (stage) {
      case HintStage.guidance:
        return const Color(0xFFFDEED9); // Light soft orange
      case HintStage.elimination:
        return const Color(0xFFFFEBEE); // Soft rose peach
      case HintStage.placement:
        return const Color(0xFFE8F5E9); // Soft sage
    }
  }

  String _badgeText(HintStage stage) {
    switch (stage) {
      case HintStage.guidance:
        return 'Clue 1 of 3 — Guidance';
      case HintStage.elimination:
        return 'Clue 2 of 3 — Elimination';
      case HintStage.placement:
        return 'Clue 3 of 3 — Placement';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = hint.stage;
    final badgeColor = _badgeColor(stage);
    final badgeBgColor = _badgeBgColor(stage);
    final isLastStage = stage == HintStage.placement;

    return Semantics(
      container: true,
      label: 'Hint: ${_badgeText(stage)}. ${hint.message}',
      child: Container(
        key: const ValueKey('hint_banner'),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8), // Clean warm cream background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowWarm,
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top row: Stage indicator badge and compact controls (wrap-safe for small screens)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                // Stage indicator badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (stage == HintStage.placement)
                        const Padding(
                          padding: EdgeInsets.only(right: 3),
                          child: PawIcon(size: 11, color: Color(0xFF2E7D32)),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Icon(
                            stage == HintStage.guidance ? Icons.lightbulb_outline_rounded : Icons.filter_alt_outlined,
                            size: 11,
                            color: badgeColor,
                          ),
                        ),
                      Text(
                        _badgeText(stage),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action buttons: "Next clue" & "Got it"
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isLastStage) ...[
                      _CompactActionButton(
                        label: 'Next clue',
                        icon: Icons.arrow_forward_rounded,
                        backgroundColor: AppColors.primary,
                        textColor: Colors.white,
                        onTap: onNextClue,
                      ),
                      const SizedBox(width: 5),
                    ],
                    _CompactActionButton(
                      label: 'Got it',
                      icon: Icons.check_rounded,
                      backgroundColor: AppColors.background,
                      textColor: AppColors.text,
                      borderColor: AppColors.cardBorder,
                      onTap: onDismiss,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Message text
            Text(
              hint.message,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor ?? backgroundColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                icon,
                size: 11,
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
