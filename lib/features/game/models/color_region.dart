import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Represents one of the 10 colored regions on the board.
class ColorRegion {
  final int id;
  final String name;
  final Color color;

  const ColorRegion({
    required this.id,
    required this.name,
    required this.color,
  });

  static const List<String> regionNames = [
    'Coral Den',
    'Buttercup Meadow',
    'Sage Valley',
    'Sky Hill',
    'Lavender Glen',
    'Blossom Yard',
    'Apricot Trail',
    'Seafoam Creek',
    'Periwinkle Grove',
    'Linen Patio',
  ];

  factory ColorRegion.fromId(int id) {
    return ColorRegion(
      id: id,
      name: regionNames[id % regionNames.length],
      color: AppColors.regionColors[id % AppColors.regionColors.length],
    );
  }
}
