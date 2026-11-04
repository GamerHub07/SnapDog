import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/home/screens/main_navigation_shell.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/splash/screens/splash_screen.dart';

class SnapDogApp extends ConsumerWidget {
  final bool showSplash;

  const SnapDogApp({
    super.key,
    this.showSplash = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'SnapDog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: showSplash ? const SplashScreen() : const MainNavigationShell(),
    );
  }
}
