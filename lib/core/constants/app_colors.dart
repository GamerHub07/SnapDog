import 'package:flutter/material.dart';

/// App color palette reflecting the warm, playful dog theme.
class AppColors {
  AppColors._();

  // Core Brand Colors from Design Specs
  static const Color background = Color(0xFFFFF8EF); // Warm cream
  static const Color primary = Color(0xFFF4A261); // Soft orange
  static const Color primaryDark = Color(0xFFE76F51); // Warm terracotta accent
  static const Color primaryLight = Color(0xFFFBE4D5); // Very soft orange
  static const Color secondary = Color(0xFFFCE1CF); // Light peach
  static const Color text = Color(0xFF49352B); // Dark brown
  static const Color textLight = Color(0xFF7A6456); // Medium warm brown
  static const Color textMuted = Color(0xFFA69386); // Soft warm gray/brown
  static const Color card = Color(0xFFFFFFFF); // Clean white for cards

  // Card & Surface Accents
  static const Color cardBorder = Color(0xFFF0E5D8);
  static const Color surfaceElevated = Color(0xFFFFFBF6);

  // 10 Distinct Pastel Region Colors (Refined contrast palette)
  static const List<Color> regionColors = [
    Color(0xFFC9E8C7), // 0: Soft mint
    Color(0xFFBFDDF2), // 1: Sky blue
    Color(0xFFFFD8B8), // 2: Warm peach
    Color(0xFFD9D0F0), // 3: Lavender
    Color(0xFFF4C9D9), // 4: Soft pink
    Color(0xFFF6E7A9), // 5: Butter yellow
    Color(0xFFB9E5DF), // 6: Aqua
    Color(0xFFF2C2B4), // 7: Light coral
    Color(0xFFC9D3F2), // 8: Periwinkle
    Color(0xFFDDE9B5), // 9: Pale lime
  ];

  // Board & Grid Line Colors
  static const Color boardBackground = Color(0xFFFFFFFF);
  static const Color gridLineThin = Color(0x389B7C68);
  static const Color regionBorderThick = Color(0xFF9B7C68);

  // Highlighting & State Colors
  static const Color cellSelected = Color(0x38FFFFFF);
  static const Color cellHighlight = Color(0x24FFFFFF);
  static const Color clashRed = Color(0xFFE63946);
  static const Color clashBackground = Color(0xFFFFD2D5);

  // Status & Feedback Colors
  static const Color success = Color(0xFF81B29A); // Soft sage green
  static const Color warning = Color(0xFFE9C46A); // Warm golden yellow
  static const Color error = Color(0xFFE56B6F); // Soft coral red
  static const Color gold = Color(0xFFFFB703); // Shiny paw/trophy gold

  // Shadows
  static const Color shadowWarm = Color(0x1A49352B);
  static const Color shadowDark = Color(0x2E49352B);
}
