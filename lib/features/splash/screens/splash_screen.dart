import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/services/sound_service.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../daily_challenge/services/daily_persistence_service.dart';
import '../../home/screens/main_navigation_shell.dart';
import '../../progression/services/progression_repository.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/splash_quote.dart';

/// Minimalist, premium cold-startup splash and loading screen for SnapDog.
///
/// Features strictly:
/// 1. SnapDog logo and wordmark (modern rounded typography in orange, coral & deep brown).
/// 2. One motivational or playful quote centered with generous whitespace.
/// 3. Minimal thin, rounded progress bar in warm orange on a light track.
/// 4. Small loading status message ("Getting things ready...").
///
/// No cards, buttons, dog collections, statistics, or decorative illustrations.
class SplashScreen extends ConsumerStatefulWidget {
  final SplashQuote? quote;
  final bool autoNavigate;
  final double? initialProgress;

  const SplashScreen({
    super.key,
    this.quote,
    this.autoNavigate = true,
    this.initialProgress,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // Brand & Minimalist Theme Palette
  static const Color _bgWarm = Color(0xFFFFF9F2);
  static const Color _primaryOrange = Color(0xFFF4A261);
  static const Color _coral = Color(0xFFE47F56);
  static const Color _deepBrown = Color(0xFF49352B);
  static const Color _mutedText = Color(0xFFA88D7B);
  static const Color _trackBg = Color(0xFFF0EAE1);

  late final SplashQuote _selectedQuote;
  double _progress = 0.0;
  String _statusMessage = 'Getting things ready...';
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _selectedQuote = widget.quote ??
        splashQuotes[math.Random().nextInt(splashQuotes.length)];
    _progress = widget.initialProgress ?? 0.0;

    if (widget.autoNavigate) {
      // Ensure the loading screen is drawn on the very first Flutter frame before async initialization starts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startColdStartupInitialization();
        }
      });
    }
  }

  Future<void> _startColdStartupInitialization() async {
    // In automated widget testing, immediately post-frame navigate to avoid blocking tests
    if (SoundService.instance.isTestEnvironment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isNavigating && widget.autoNavigate) {
          _navigateToHome();
        }
      });
      return;
    }

    try {
      // Step 1: Load settings & user preferences
      if (mounted) {
        setState(() {
          _progress = 0.25;
          _statusMessage = 'Getting things ready...';
        });
      }
      await ref.read(settingsProvider.notifier).ensureInitialized();

      // Step 2: Load progression & level records
      if (mounted) {
        setState(() {
          _progress = 0.50;
        });
      }
      await ProgressionRepository.loadProgression();

      // Step 3: Load daily challenge state
      if (mounted) {
        setState(() {
          _progress = 0.75;
        });
      }
      await DailyPersistenceService.loadDailyState();

      // Step 4: Initialize sound and precache core dog assets
      if (mounted) {
        setState(() {
          _progress = 1.0;
        });
      }
      final settings = ref.read(settingsProvider);
      SoundService.instance.init(
        soundEnabled: settings.soundEnabled,
        volume: settings.soundVolume,
      );

      for (final assetPath in AppAssets.allDogAssets) {
        if (!mounted) break;
        try {
          await precacheImage(AssetImage(assetPath), context);
        } catch (_) {}
      }
    } catch (e, stack) {
      debugPrint('Startup initialization handled gracefully: $e\n$stack');
    }

    if (mounted && widget.autoNavigate && !_isNavigating) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    _isNavigating = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: SoundService.instance.isTestEnvironment
            ? Duration.zero
            : const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWarm,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 32.0;
            final isShortScreen = constraints.maxHeight < 650;

            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: constraints.maxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isShortScreen ? 16.0 : 24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Spacing & Branding Header
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: isShortScreen ? 12 : 36,
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _buildBrandWordmark(),
                          ),
                        ],
                      ),

                      // Upper-Middle: Playful / Motivational Quote
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isShortScreen ? 16.0 : 24.0,
                          horizontal: 4.0,
                        ),
                        child: _buildQuoteSection(
                          constraints.maxWidth - (horizontalPadding * 2),
                          isShortScreen,
                        ),
                      ),

                      // Bottom: Minimal Progress Bar & Small Status Message
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildProgressBar(constraints.maxWidth - (horizontalPadding * 2)),
                          const SizedBox(height: 12),
                          _buildStatusMessage(),
                          SizedBox(
                            height: isShortScreen ? 12 : 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Refined SnapDog branding with paw icon and distinctive typography.
  Widget _buildBrandWordmark() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App Identity Paw Icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _primaryOrange,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1449352B),
                offset: Offset(0, 3),
                blurRadius: 8,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const PawIcon(size: 24, color: Colors.white),
        ),
        const SizedBox(width: 12),
        // Modern rounded wordmark
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Snap',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _deepBrown,
                  letterSpacing: -0.6,
                  height: 1.1,
                ),
              ),
              TextSpan(
                text: 'Dog',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _coral,
                  letterSpacing: -0.6,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Bold, calm, centered quote typography as the loading screen's main visual focus.
  Widget _buildQuoteSection(double availableWidth, bool isShortScreen) {
    // Increase quote font size to approximately 25–30 logical pixels, adapting to screen size
    final double quoteFontSize = isShortScreen
        ? 24.0
        : (availableWidth * 0.08).clamp(25.0, 30.0);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: math.min(380.0, availableWidth)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedQuote.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: quoteFontSize,
              fontWeight: FontWeight.w600,
              color: _deepBrown,
              height: 1.35,
              letterSpacing: -0.3,
            ),
          ),
          if (_selectedQuote.attribution != null) ...[
            const SizedBox(height: 10),
            Text(
              '— ${_selectedQuote.attribution}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _mutedText,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Thin, rounded progress bar with smooth transition.
  Widget _buildProgressBar(double availableWidth) {
    final double barWidth = math.min(220.0, availableWidth);
    const double barHeight = 4.0;
    final radius = BorderRadius.circular(2.0);

    return SizedBox(
      width: barWidth,
      height: barHeight,
      child: Stack(
        children: [
          // Background track
          Container(
            width: barWidth,
            height: barHeight,
            decoration: BoxDecoration(
              color: _trackBg,
              borderRadius: radius,
            ),
          ),
          // Smooth Animated Progress Fill
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: _progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: animatedValue,
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: _primaryOrange,
                    borderRadius: radius,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Small, understated status message near the progress bar.
  Widget _buildStatusMessage() {
    return Text(
      _statusMessage,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _mutedText,
        letterSpacing: 0.2,
      ),
    );
  }
}
