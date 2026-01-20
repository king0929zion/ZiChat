import 'package:flutter/material.dart';
import 'package:zichat/constants/app_colors.dart';

enum WeuiButtonType {
  primary,
  defaultType,
  warn,
}

enum WeuiButtonSize {
  normal,
  medium,
  small,
}

class WeuiButton extends StatelessWidget {
  const WeuiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = WeuiButtonType.primary,
    this.block = true,
    this.size = WeuiButtonSize.normal,
  });

  final String label;
  final VoidCallback? onPressed;
  final WeuiButtonType type;
  final bool block;
  final WeuiButtonSize size;

  @override
  Widget build(BuildContext context) {
    final Widget child = Text(label);

    final double height = switch (size) {
      WeuiButtonSize.normal => 48,
      WeuiButtonSize.medium => 40,
      WeuiButtonSize.small => 32,
    };

    final Size minimumSize = Size(block ? double.infinity : 184, height);
    final BorderRadius borderRadius = BorderRadius.circular(8);

    final ButtonStyle style = switch (type) {
      WeuiButtonType.primary => ElevatedButton.styleFrom(
          minimumSize: minimumSize,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      WeuiButtonType.warn => ElevatedButton.styleFrom(
          minimumSize: minimumSize,
          backgroundColor: const Color(0xFFFA5151),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      WeuiButtonType.defaultType => ElevatedButton.styleFrom(
          minimumSize: minimumSize,
          backgroundColor: AppColors.disabledBg,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.textDisabled,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
    };

    return SizedBox(
      width: block ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}
