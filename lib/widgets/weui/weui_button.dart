import 'package:flutter/material.dart';
import 'package:zichat/constants/app_colors.dart';

enum WeuiButtonType {
  primary,
  defaultType,
  warn,
}

class WeuiButton extends StatelessWidget {
  const WeuiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = WeuiButtonType.primary,
    this.block = true,
    this.height = 44,
  });

  final String label;
  final VoidCallback? onPressed;
  final WeuiButtonType type;
  final bool block;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Widget child = Text(label);

    final Size minimumSize = Size(block ? double.infinity : 0, height);

    switch (type) {
      case WeuiButtonType.primary:
        return SizedBox(
          width: block ? double.infinity : null,
          height: height,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(minimumSize: minimumSize),
            child: child,
          ),
        );
      case WeuiButtonType.warn:
        return SizedBox(
          width: block ? double.infinity : null,
          height: height,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: minimumSize,
              backgroundColor: const Color(0xFFFA5151),
            ),
            child: child,
          ),
        );
      case WeuiButtonType.defaultType:
        return SizedBox(
          width: block ? double.infinity : null,
          height: height,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: minimumSize,
              foregroundColor: AppColors.textPrimary,
            ),
            child: child,
          ),
        );
    }
  }
}

