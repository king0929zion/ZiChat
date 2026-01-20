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

    final Size minimumSize = Size(block ? double.infinity : 0, height);

    final BorderRadius borderRadius = BorderRadius.circular(
      size == WeuiButtonSize.small ? 4 : 8,
    );

    final EdgeInsetsGeometry padding = switch (size) {
      WeuiButtonSize.normal => const EdgeInsets.symmetric(horizontal: 24),
      WeuiButtonSize.medium => const EdgeInsets.symmetric(horizontal: 20),
      WeuiButtonSize.small => const EdgeInsets.symmetric(horizontal: 12),
    };

    return SizedBox(
      width: block ? double.infinity : null,
      height: height,
      child: switch (type) {
        WeuiButtonType.defaultType => OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: minimumSize,
              padding: padding,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              disabledForegroundColor: AppColors.textDisabled,
              side: const BorderSide(color: AppColors.border, width: 1),
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
            ),
            child: child,
          ),
        WeuiButtonType.warn => ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: minimumSize,
              padding: padding,
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
              disabledBackgroundColor: AppColors.disabledBg,
              disabledForegroundColor: AppColors.textDisabled,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
            ),
            child: child,
          ),
        WeuiButtonType.primary => ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: minimumSize,
              padding: padding,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
            ),
            child: child,
          ),
      },
    );
  }
}
