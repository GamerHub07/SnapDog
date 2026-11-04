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

  // 10 Distinct Pastel Region Colors
  static const List<Color> regionColors = [
    Color(0xFFFFD6C9), // 0: Pastel Coral / Peach
    Color(0xFFFFF2B2), // 1: Pastel Buttercup Yellow
    Color(0xFFCBEBC4), // 2: Pastel Sage Mint
    Color(0xFFC7E4F8), // 3: Pastel Sky Blue
    Color(0xFFE5D7F4), // 4: Pastel Lavender
    Color(0xFFFFD4E2), // 5: Pastel Blossom Pink
    Color(0xFFFFE3C2), // 6: Pastel Warm Apricot
    Color(0xFFBFECE3), // 7: Pastel Fresh Seafoam
    Color(0xFFD6DEF7), // 8: Pastel Periwinkle
    Color(0xFFF3E8D7), // 9: Pastel Warm Linen
  ];

  // Board & Grid Line Colors
  static const Color boardBackground = Color(0xFFFFFFFF);
  static const Color gridLineThin = Color(0x3849352B);
  static const Color regionBorderThick = Color(0xFF5A4135);

  // Highlighting & State Colors
  static const Color cellSelected = Color(0x59F4A261);
  static const Color cellHighlight = Color(0x28F4A261);
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
