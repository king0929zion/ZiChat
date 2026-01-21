import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';

class WeuiCircleIconButton extends StatelessWidget {
  const WeuiCircleIconButton({
    super.key,
    required this.assetName,
    this.onTap,
    this.size = 44,
    this.iconSize = 18,
    this.backgroundColor = const Color(0x0D000000),
    this.iconColor = AppColors.textPrimary,
  });

  final String assetName;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap?.call();
                },
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  assetName,
                  width: iconSize,
                  height: iconSize,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WeuiPillSearchBar extends StatelessWidget {
  const WeuiPillSearchBar({
    super.key,
    required this.controller,
    this.hintText = '搜索',
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            AppAssets.iconSearch,
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              AppColors.textHint,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 17,
                height: 1.2,
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 17,
                  height: 1.2,
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.clear();
                onChanged?.call('');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Icon(
                  Icons.cancel,
                  size: 18,
                  color: AppColors.textHint,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ModelServiceCard extends StatelessWidget {
  const ModelServiceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.color = const Color(0xFFF2F2F2),
    this.radius = 18,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap?.call();
              },
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ProviderAvatar extends StatelessWidget {
  const ProviderAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.radius = 12,
  });

  final String name;
  final double size;
  final double radius;

  static const List<Color> _palette = [
    Color(0xFF5B8FF9),
    Color(0xFF61DDAA),
    Color(0xFFF6BD16),
    Color(0xFF7262FD),
    Color(0xFF78D3F8),
    Color(0xFFF6903D),
    Color(0xFF9661BC),
    Color(0xFFF08BB4),
    Color(0xFF6DC8EC),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = _colorFromName(name);
    final text = _initials(name);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: bg,
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Color _colorFromName(String value) {
    int hash = 0;
    for (final unit in value.runes) {
      hash = 0x1fffffff & (hash + unit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    final index = math.max(0, hash) % _palette.length;
    return _palette[index];
  }

  String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'AI';
    final chars = trimmed.characters.toList();
    if (chars.isEmpty) return 'AI';
    if (chars.length == 1) return chars[0].toUpperCase();
    final first = chars[0];
    final second = chars[1];
    final isAscii = (String s) =>
        s.codeUnits.every((c) => c >= 0x21 && c <= 0x7E);
    if (isAscii(first) && isAscii(second)) {
      return (first + second).toUpperCase();
    }
    return first.toUpperCase();
  }
}

class WeuiInsetCard extends StatelessWidget {
  const WeuiInsetCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.padding = EdgeInsets.zero,
    this.radius = 14,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class WeuiSectionTitle extends StatelessWidget {
  const WeuiSectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class WeuiBadge extends StatelessWidget {
  const WeuiBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppStyles.radiusXLarge),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.24),
          width: 0.5,
        ),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 12,
          height: 1.1,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class WeuiTag extends StatelessWidget {
  const WeuiTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppStyles.radiusXLarge),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.24),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          height: 1.1,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
