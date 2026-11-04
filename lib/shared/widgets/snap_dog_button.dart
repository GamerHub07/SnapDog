import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/sound_haptic_helper.dart';

enum SnapDogButtonVariant {
  primary,
  secondary,
  outline,
}

/// A bouncy, tactile casual game button with depth and pressing feedback.
class SnapDogButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final SnapDogButtonVariant variant;
  final double height;
  final double? width;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const SnapDogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = SnapDogButtonVariant.primary,
    this.height = 54,
    this.width,
    this.fontSize = 17,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  State<SnapDogButton> createState() => _SnapDogButtonState();
}

class _SnapDogButtonState extends State<SnapDogButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    Color topColor;
    Color bottomColor;
    Color textColor;

    switch (widget.variant) {
      case SnapDogButtonVariant.primary:
        topColor = isEnabled ? AppColors.primary : const Color(0xFFDECAC0);
        bottomColor = isEnabled ? AppColors.primaryDark : const Color(0xFFB8A298);
        textColor = Colors.white;
        break;
      case SnapDogButtonVariant.secondary:
        topColor = isEnabled ? AppColors.secondary : const Color(0xFFF3EAE4);
        bottomColor = isEnabled ? const Color(0xFFE8C6AF) : const Color(0xFFDAC7BC);
        textColor = AppColors.text;
        break;
      case SnapDogButtonVariant.outline:
        topColor = AppColors.card;
        bottomColor = const Color(0xFFE2D4C6);
        textColor = AppColors.text;
        break;
    }

    const double depth = 4.0;
    final double currentOffset = _isPressed ? depth : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onPressed,
      onTapDown: isEnabled
          ? (_) {
              setState(() => _isPressed = true);
              SoundHapticHelper.lightTap();
            }
          : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
            }
          : null,
      onTapCancel: isEnabled
          ? () {
              setState(() => _isPressed = false);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        height: widget.height,
        width: widget.width,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Shadow / 3D bottom base
            Container(
              height: widget.height,
              width: widget.width,
              decoration: BoxDecoration(
                color: bottomColor,
                borderRadius: BorderRadius.circular(widget.height / 2),
                boxShadow: isEnabled && !_isPressed
                    ? [
                        const BoxShadow(
                          color: AppColors.shadowWarm,
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
            ),
            // Front face layer that depresses
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              top: currentOffset,
              bottom: depth - currentOffset,
              left: 0,
              right: 0,
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: topColor,
                  borderRadius: BorderRadius.circular(widget.height / 2),
                  border: widget.variant == SnapDogButtonVariant.outline
                      ? Border.all(color: AppColors.cardBorder, width: 1.5)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      widget.icon!,
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        style: AppTextStyles.buttonLabel.copyWith(
                          color: textColor,
                          fontSize: widget.fontSize,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
