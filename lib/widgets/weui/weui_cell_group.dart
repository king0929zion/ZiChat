import 'package:flutter/material.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';

class WeuiCellGroup extends StatelessWidget {
  const WeuiCellGroup({
    super.key,
    this.title,
    required this.children,
    this.margin = const EdgeInsets.only(top: 8),
    this.dividerIndent = 16,
    this.inset = false,
    this.borderRadius,
  });

  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final double dividerIndent;
  final bool inset;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final groupRadius = borderRadius ??
        (inset ? BorderRadius.circular(AppStyles.radiusMedium) : BorderRadius.zero);
    final BoxBorder groupBorder = inset
        ? Border.all(color: AppColors.border, width: 0.5)
        : const Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          );

    Widget groupBody = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: groupRadius,
        border: groupBorder,
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: EdgeInsets.only(left: dividerIndent),
                child: const Divider(height: 1, color: AppColors.divider),
              ),
          ],
        ],
      ),
    );

    if (groupRadius != BorderRadius.zero) {
      groupBody = ClipRRect(borderRadius: groupRadius, child: groupBody);
    }

    return Container(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          Padding(
            padding: inset
                ? const EdgeInsets.symmetric(horizontal: 16)
                : EdgeInsets.zero,
            child: groupBody,
          ),
        ],
      ),
    );
  }
}
