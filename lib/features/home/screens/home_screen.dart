import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/dog_mascot.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../../shared/widgets/snap_dog_button.dart';
import '../../game/models/puzzle.dart';
import '../../game/providers/game_provider.dart';
import '../../game/screens/game_screen.dart';
import '../../daily_challenge/screens/daily_challenge_screen.dart';
import '../../progression/providers/progression_provider.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/daily_challenge_card.dart';
import '../widgets/home_decorations.dart';
import '../widgets/home_dog_face_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _startPuzzle(Puzzle puzzle) {
    ref.read(puzzleGameProvider.notifier).loadLevel(puzzle.levelNumber);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(puzzleIndex: puzzle.levelNumber - 1),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progression = ref.watch(progressionProvider);
    final resumePuzzle = progression.getResumePuzzle();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle decorative grass patches, 3D clay bones, and paw accents
          const HomeBackgroundDecorations(),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo & Branding Header with Settings Access
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Balance spacer matching the settings icon button
                      const SizedBox(width: 44),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.shadowWarm,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const PawIcon(size: 20, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'SnapDog',
                            style: AppTextStyles.displayMedium.copyWith(
                              letterSpacing: -0.5,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),

                      IconButton(
                        icon: const Icon(Icons.settings_rounded, color: AppColors.text),
                        onPressed: _openSettings,
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Decorative Row of Consistent 3D Dog-Face Illustrations
                  const HomeDogFaceRow(),
                  const SizedBox(height: 12),

                  // Friendly Mascot & Main Action Card
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 48),
                        padding: const EdgeInsets.only(
                          top: 60,
                          bottom: 22,
                          left: 20,
                          right: 20,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.cardBorder, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowWarm,
                              offset: Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Speech Bubble Greeting
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Can you place all 10 dogs with no touching?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Current Level Banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorder, width: 1),
                              ),
                              child: Row(
                                children: [
                                  const PawIcon(size: 18, color: AppColors.primaryDark),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Level ${resumePuzzle.levelNumber} • ${resumePuzzle.title}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.text,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      resumePuzzle.difficultyLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Continue Level Button
                            SnapDogButton(
                              label: 'Continue Level',
                              icon: const PawIcon(size: 20, color: Colors.white),
                              height: 54,
                              fontSize: 16,
                              width: double.infinity,
                              onPressed: () => _startPuzzle(resumePuzzle),
                            ),
                          ],
                        ),
                      ),

                      // Mascot peeking above card
                      const Positioned(
                        top: 0,
                        child: DogMascot(
                          size: 115,
                          mood: DogMascotMood.sleeping,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Daily Challenge Card
                  DailyChallengeCard(
                    onPlay: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DailyChallengeScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
