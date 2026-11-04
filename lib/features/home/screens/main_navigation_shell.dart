import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/paw_icon.dart';
import '../../onboarding/widgets/tutorial_dialog.dart';
import '../../settings/models/settings_state.dart';
import '../../settings/screens/settings_screen.dart';
import '../../statistics/screens/statistics_screen.dart';
import 'home_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstLaunchOnboarding();
  }

  void _checkFirstLaunchOnboarding() async {
    final completed = await SettingsRepository.hasCompletedOnboarding();
    if (!completed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          TutorialDialog.show(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowWarm,
              offset: Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: const PawIcon(size: 22, color: AppColors.textMuted),
                  activeIcon: const PawIcon(size: 22, color: AppColors.primaryDark),
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: const Icon(Icons.bar_chart_rounded, size: 24, color: AppColors.textMuted),
                  activeIcon: const Icon(Icons.bar_chart_rounded, size: 24, color: AppColors.primaryDark),
                  label: 'Stats',
                ),
                _buildNavItem(
                  index: 2,
                  icon: const Icon(Icons.settings_outlined, size: 24, color: AppColors.textMuted),
                  activeIcon: const Icon(Icons.settings_rounded, size: 24, color: AppColors.primaryDark),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required Widget icon,
    required Widget activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isSelected ? activeIcon : icon,
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
