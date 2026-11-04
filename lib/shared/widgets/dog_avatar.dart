import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../features/game/models/dog_breed.dart';

/// Reusable 3D Clay Dog Avatar widget for SnapDog.
///
/// Features:
/// - Accepts either a [DogBreed] or a direct [assetPath].
/// - Strictly uses [BoxFit.contain] to preserve the entire dog face, including ears.
/// - Avoids stretching or cropping and ensures consistent visual scale across all 6 breeds.
/// - Supports optional circular background, custom borders, soft shadows, and animations.
/// - Gracefully clips to circular boundaries to eliminate unwanted square corners on opaque images.
/// - Robust fallback for headless widget test environments.
class DogAvatar extends StatelessWidget {
  /// The breed of the dog. If provided and [assetPath] is null, uses [breed.assetPath].
  final DogBreed? breed;

  /// Direct path to the image asset. Overrides [breed.assetPath] if provided.
  final String? assetPath;

  /// The outer dimension (width and height) of the avatar in logical pixels.
  final double size;

  /// Whether to render a circular container background behind the dog image.
  final bool circularBackground;

  /// Custom background color for the circular badge (defaults to warm cream `#FFF7EE`).
  final Color? backgroundColor;

  /// Optional outer border for the avatar.
  final BoxBorder? border;

  /// Optional list of box shadows for elevation.
  final List<BoxShadow>? boxShadow;

  /// Optional scale/pop animation to drive interactive entrance/placement effects.
  final Animation<double>? animation;

  /// Whether to apply a gentle breathing/idle animation.
  final bool animate;

  /// Whether the placed dog is in a conflicting/clashing state on the board.
  final bool hasClash;

  /// Whether to render the avatar as a soft dark silhouette (e.g. for unplaced dogs).
  final bool isSilhouette;

  /// Optional accessibility semantic label.
  final String? semanticLabel;

  const DogAvatar({
    super.key,
    this.breed,
    this.assetPath,
    this.size = 40.0,
    this.circularBackground = false,
    this.backgroundColor,
    this.border,
    this.boxShadow,
    this.animation,
    this.animate = false,
    this.hasClash = false,
    this.isSilhouette = false,
    this.semanticLabel,
  });

  /// Factory constructor for circular badge dog avatars with consistent border and shadow.
  factory DogAvatar.circularBadge({
    Key? key,
    required DogBreed breed,
    double size = 42.0,
    Color? backgroundColor,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
  }) {
    return DogAvatar(
      key: key,
      breed: breed,
      size: size,
      circularBackground: true,
      backgroundColor: backgroundColor ?? const Color(0xFFFFF7EE),
      border: border ?? Border.all(color: AppColors.cardBorder, width: 1.5),
      boxShadow: boxShadow ??
          const [
            BoxShadow(
              color: AppColors.shadowWarm,
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
    );
  }

  String get _resolvedAssetPath {
    if (assetPath != null && assetPath!.isNotEmpty) {
      return assetPath!;
    }
    if (breed != null) {
      return breed!.assetPath;
    }
    return AppAssets.corgi;
  }

  String get _resolvedLabel {
    if (semanticLabel != null) return semanticLabel!;
    if (breed != null) return '${breed!.displayName} avatar';
    return 'Dog avatar';
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _resolvedAssetPath;

    // Inner image size leaving a subtle margin for ears within a circular boundary
    final double innerSize = circularBackground ? size * 0.90 : size;

    Widget imageWidget = Image.asset(
      imagePath,
      width: innerSize,
      height: innerSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        // Safe fallback for unit and widget tests
        return _buildFallbackIcon(innerSize);
      },
    );

    if (isSilhouette) {
      imageWidget = Opacity(
        opacity: 0.35,
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Color(0xFF6B584E),
            BlendMode.srcIn,
          ),
          child: imageWidget,
        ),
      );
    } else if (hasClash) {
      imageWidget = ColorFiltered(
        colorFilter: ColorFilter.mode(
          AppColors.clashRed.withValues(alpha: 0.35),
          BlendMode.srcATop,
        ),
        child: imageWidget,
      );
    }

    Widget content;
    if (circularBackground) {
      content = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? const Color(0xFFFFF7EE),
          border: hasClash
              ? Border.all(color: AppColors.clashRed, width: 2.0)
              : border,
          boxShadow: boxShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: ClipOval(
            child: imageWidget,
          ),
        ),
      );
    } else {
      content = SizedBox(
        width: size,
        height: size,
        child: Center(
          child: ClipOval(
            child: imageWidget,
          ),
        ),
      );
    }

    if (animation != null) {
      content = ScaleTransition(
        scale: animation!,
        child: content,
      );
    }

    return Semantics(
      label: _resolvedLabel,
      image: true,
      child: content,
    );
  }

  Widget _buildFallbackIcon(double innerSize) {
    final color = breed?.primaryColor ?? AppColors.primary;
    return Container(
      width: innerSize,
      height: innerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
      ),
      child: Center(
        child: Icon(
          Icons.pets_rounded,
          color: color,
          size: innerSize * 0.55,
        ),
      ),
    );
  }
}
