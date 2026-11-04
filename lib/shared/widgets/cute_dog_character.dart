import 'package:flutter/material.dart';
import '../../features/game/models/dog_breed.dart';
import 'dog_avatar.dart';

/// 3D Clay Dog character widget for board cells, preview rows, and badges.
///
/// Supports all 6 SnapDog breeds:
/// - [DogBreed.beagle]
/// - [DogBreed.corgi]
/// - [DogBreed.goldenRetriever]
/// - [DogBreed.husky]
/// - [DogBreed.labrador]
/// - [DogBreed.pug]
class CuteDogCharacter extends StatelessWidget {
  final double size;
  final DogBreed breed;
  final bool hasClash;
  final String? customAsset;
  final bool isSilhouette;

  const CuteDogCharacter({
    super.key,
    this.size = 36,
    this.breed = DogBreed.corgi,
    this.hasClash = false,
    this.customAsset,
    this.isSilhouette = false,
  });

  @override
  Widget build(BuildContext context) {
    return DogAvatar(
      breed: breed,
      assetPath: customAsset,
      size: size,
      hasClash: hasClash,
      isSilhouette: isSilhouette,
    );
  }
}

