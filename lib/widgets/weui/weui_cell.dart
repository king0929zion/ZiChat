import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';

class WeuiCell extends StatelessWidget {
  const WeuiCell({
    super.key,
    required this.title,
    this.description,
    this.value,
    this.leading,
    this.trailing,
    this.showArrow = true,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.height = 56,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final String title;
  final String? description;
  final String? value;
  final Widget? leading;
  final Widget? trailing;
  final bool showArrow;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bool clickable = enabled && (onTap != null || onLongPress != null);
    final Color textColor =
        enabled ? AppColors.textPrimary : AppColors.textHint;

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: clickable
            ? () {
                HapticFeedback.selectionClick();
                onTap?.call();
              }
            : null,
        onLongPress: clickable
            ? () {
                HapticFeedback.mediumImpact();
                onLongPress?.call();
              }
            : null,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          color: textColor,
                        ),
                      ),
                      if (description != null && description!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (value != null && value!.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ] else if (showArrow) ...[
                  const SizedBox(width: 8),
                  SvgPicture.asset(
                    AppAssets.iconArrowRight,
                    width: 12,
                    height: 12,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textHint,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
