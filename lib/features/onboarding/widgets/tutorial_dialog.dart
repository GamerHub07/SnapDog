import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/sound_haptic_helper.dart';
import '../../../shared/widgets/clay_cross_marker.dart';
import '../../../shared/widgets/cute_dog_character.dart';
import '../../../shared/widgets/dog_mascot.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../../shared/widgets/snap_dog_button.dart';
import '../../settings/models/settings_state.dart';

class TutorialDialog extends StatefulWidget {
  final VoidCallback? onCompleted;

  const TutorialDialog({
    super.key,
    this.onCompleted,
  });

  static Future<void> show(BuildContext context, {VoidCallback? onCompleted}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TutorialDialog(onCompleted: onCompleted),
    );
  }

  @override
  State<TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_TutorialStep> _steps = [
    _TutorialStep(
      stepNumber: 1,
      title: 'One Dog Per Row',
      description: 'Every horizontal row across the board must contain exactly one happy puppy.',
      iconData: Icons.table_rows_rounded,
      ruleType: _RuleType.row,
    ),
    _TutorialStep(
      stepNumber: 2,
      title: 'One Dog Per Column',
      description: 'Every vertical column on the 10×10 board must also contain exactly one puppy.',
      iconData: Icons.view_column_rounded,
      ruleType: _RuleType.column,
    ),
    _TutorialStep(
      stepNumber: 3,
      title: 'One Dog Per Color Region',
      description: 'Each colored pastel territory on the board belongs to exactly one unique puppy.',
      iconData: Icons.palette_rounded,
      ruleType: _RuleType.region,
    ),
    _TutorialStep(
      stepNumber: 4,
      title: 'No Touching (Even Diagonally!)',
      description: 'Puppies need their personal space! Dogs cannot touch in any of the 8 directions.',
      iconData: Icons.do_not_disturb_on_rounded,
      ruleType: _RuleType.noTouch,
    ),
    _TutorialStep(
      stepNumber: 5,
      title: 'Single Tap = Mark with Cross (×)',
      description: 'Single-tap any empty cell to mark it with a cross. Tap again to clear it.',
      iconData: Icons.close_rounded,
      ruleType: _RuleType.cross,
    ),
    _TutorialStep(
      stepNumber: 6,
      title: 'Double Tap = Place a Dog',
      description: 'Double-tap an empty or crossed cell to place your pup! Ready to solve?',
      iconData: Icons.pets_rounded,
      ruleType: _RuleType.dog,
    ),
  ];

  void _finish() async {
    SoundHapticHelper.buttonClick();
    await SettingsRepository.setOnboardingCompleted();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onCompleted?.call();
    }
  }

  void _nextPage() {
    SoundHapticHelper.buttonClick();
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _steps.length - 1;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 540),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowWarm,
                offset: Offset(0, 8),
                blurRadius: 24,
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
          children: [
            // Header with badge and skip button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const PawIcon(size: 14, color: AppColors.primaryDark),
                      const SizedBox(width: 6),
                      Text(
                        'STEP ${_currentPage + 1} OF ${_steps.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(48, 30),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Swipable Steps PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Visual Illustration / Mini Graphic
                      _buildStepGraphic(step.ruleType),
                      const SizedBox(height: 20),

                      // Step Title
                      Text(
                        step.title,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),

                      // Step Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          step.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textLight,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Bottom Navigation Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page Indicator Dots
                Row(
                  children: List.generate(_steps.length, (idx) {
                    final isCurrent = idx == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: isCurrent ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.primary : AppColors.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                // Next or Finish Button
                SnapDogButton(
                  label: isLast ? 'Start Playing!' : 'Next',
                  icon: Icon(
                    isLast ? Icons.pets_rounded : Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  height: 44,
                  fontSize: 14,
                  onPressed: _nextPage,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildStepGraphic(_RuleType type) {
    switch (type) {
      case _RuleType.row:
      case _RuleType.column:
      case _RuleType.region:
      case _RuleType.noTouch:
        return Container(
          width: 140,
          height: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowWarm,
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: _buildMiniBoard(type),
          ),
        );
      case _RuleType.cross:
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder, width: 2),
          ),
          child: const Center(
            child: ClayCrossMarker(size: 60),
          ),
        );
      case _RuleType.dog:
        return const DogMascot(
          size: 130,
          mood: DogMascotMood.celebrating,
        );
    }
  }

  Widget _buildMiniBoard(_RuleType type) {
    // 3x3 miniature board visualization
    return Table(
      children: List.generate(3, (r) {
        return TableRow(
          children: List.generate(3, (c) {
            final isTarget = (type == _RuleType.row && r == 1 && c == 1) ||
                (type == _RuleType.column && r == 1 && c == 1) ||
                (type == _RuleType.region && r == 1 && c == 1) ||
                (type == _RuleType.noTouch && r == 0 && c == 0);

            final isConflicting = (type == _RuleType.noTouch && r == 1 && c == 1);

            return Container(
              height: 34,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isTarget
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : (isConflicting ? AppColors.clashBackground : AppColors.card),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isConflicting ? AppColors.clashRed : AppColors.cardBorder,
                  width: isConflicting ? 1.5 : 1.0,
                ),
              ),
              child: Center(
                child: isTarget
                    ? const CuteDogCharacter(size: 20)
                    : (isConflicting
                        ? const Icon(Icons.not_interested_rounded, size: 16, color: AppColors.clashRed)
                        : null),
              ),
            );
          }),
        );
      }),
    );
  }
}

enum _RuleType {
  row,
  column,
  region,
  noTouch,
  cross,
  dog,
}

class _TutorialStep {
  final int stepNumber;
  final String title;
  final String description;
  final IconData iconData;
  final _RuleType ruleType;

  const _TutorialStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.iconData,
    required this.ruleType,
  });
}
