import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/sound_haptic_helper.dart';
import '../../../shared/widgets/dog_mascot.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../onboarding/widgets/tutorial_dialog.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showHowToPlay(BuildContext context) {
    SoundHapticHelper.buttonClick();
    TutorialDialog.show(context);
  }

  void _confirmResetProgress(BuildContext context, WidgetRef ref) {
    SoundHapticHelper.buttonClick();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.clashRed, size: 26),
              SizedBox(width: 8),
              Text('Reset All Progress?', style: AppTextStyles.titleLarge),
            ],
          ),
          content: const Text(
            'This will permanently delete all your completed puzzles, best times, daily challenge streaks, and game statistics. This action cannot be undone.\n\nAre you sure you want to reset?',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Keep Progress',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.clashRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await ref.read(settingsProvider.notifier).resetAllProgress();
                SoundHapticHelper.invalidPlacement();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('All game progress and streaks have been reset.'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                }
              },
              child: const Text('Reset Everything', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, bool isDark) {
    SoundHapticHelper.buttonClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choose Game Theme', style: AppTextStyles.titleLarge),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const PawIcon(size: 20, color: AppColors.primary),
                  title: const Text('Light (Warm Cream)', style: AppTextStyles.bodyLarge),
                  subtitle: const Text('Delightful pastel theme', style: AppTextStyles.bodySmall),
                  trailing: !isDark
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).toggleDarkMode(false);
                    Navigator.pop(sheetContext);
                  },
                ),
                const Divider(color: AppColors.cardBorder),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.dark_mode_rounded, color: AppColors.primary),
                  title: const Text('Dark (Cozy Night)', style: AppTextStyles.bodyLarge),
                  subtitle: const Text('Comfortable high-contrast dark theme', style: AppTextStyles.bodySmall),
                  trailing: isDark
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).toggleDarkMode(true);
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            PawIcon(size: 20, color: AppColors.primaryDark),
            SizedBox(width: 8),
            Text('Puppy Settings'),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Audio & Haptics Section
              Text(
                'Feedback & Senses',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Material(
                color: AppColors.card,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      title: const Text('Sound Effects', style: AppTextStyles.bodyLarge),
                      subtitle: const Text('Audio cues on placing dogs and solving puzzles', style: AppTextStyles.bodySmall),
                      secondary: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                      value: settings.soundEnabled,
                      onChanged: (val) {
                        ref.read(settingsProvider.notifier).toggleSound(val);
                        SoundHapticHelper.dogPlace();
                      },
                    ),
                    if (settings.soundEnabled) ...[
                      const Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.cardBorder),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      settings.soundVolume == 0
                                          ? Icons.volume_mute_rounded
                                          : Icons.volume_down_rounded,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Sound Volume', style: AppTextStyles.bodyMedium),
                                  ],
                                ),
                                Text(
                                  '${(settings.soundVolume * 100).round()}%',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                                thumbColor: AppColors.primary,
                                overlayColor: AppColors.primary.withValues(alpha: 0.15),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: settings.soundVolume,
                                min: 0.0,
                                max: 1.0,
                                divisions: 10,
                                onChanged: (val) {
                                  ref.read(settingsProvider.notifier).setSoundVolume(val);
                                },
                                onChangeEnd: (val) {
                                  SoundHapticHelper.buttonClick();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.cardBorder),
                    SwitchListTile(
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      title: const Text('Haptic Vibration', style: AppTextStyles.bodyLarge),
                      subtitle: const Text('Light physical vibration on board interactions', style: AppTextStyles.bodySmall),
                      secondary: const Icon(Icons.vibration_rounded, color: AppColors.primary),
                      value: settings.hapticsEnabled,
                      onChanged: (val) {
                        ref.read(settingsProvider.notifier).toggleHaptics(val);
                        SoundHapticHelper.dogPlace();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Appearance & Tutorial Section
              Text(
                'Game Experience',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Material(
                color: AppColors.card,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.palette_outlined, color: AppColors.primary),
                      title: const Text('Theme', style: AppTextStyles.bodyLarge),
                      subtitle: Text(settings.themeLabel, style: AppTextStyles.bodySmall),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                      onTap: () => _showThemePicker(context, ref, settings.isDarkMode),
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.cardBorder),
                    ListTile(
                      leading: const Icon(Icons.help_outline_rounded, color: AppColors.primary),
                      title: const Text('How to Play', style: AppTextStyles.bodyLarge),
                      subtitle: const Text('Review rules, tips, and touch gestures', style: AppTextStyles.bodySmall),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                      onTap: () => _showHowToPlay(context),
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.cardBorder),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_rounded, color: AppColors.clashRed),
                      title: const Text(
                        'Reset Game Progress',
                        style: TextStyle(
                          color: AppColors.clashRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: const Text('Clear completed puzzles, streaks, and best times', style: AppTextStyles.bodySmall),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                      onTap: () => _confirmResetProgress(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // About SnapDog Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowWarm,
                      offset: Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: const [
                    DogMascot(size: 80, mood: DogMascotMood.happy),
                    SizedBox(height: 10),
                    Text('SnapDog', style: AppTextStyles.displayMedium),
                    SizedBox(height: 4),
                    Text('Version 1.0.0', style: AppTextStyles.bodySmall),
                    SizedBox(height: 12),
                    Text(
                      'A cheerful, relaxing dog-themed puzzle game crafted with love for puzzle solvers and puppy lovers everywhere.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
