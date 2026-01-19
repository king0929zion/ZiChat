import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';

/// 聊天详情页顶部导航栏
class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.title,
    required this.unread,
    required this.onBack,
    required this.onMore,
    this.isTyping = false,
  });

  final String title;
  final int unread;
  final VoidCallback onBack;
  final VoidCallback onMore;
  final bool isTyping;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: AppColors.backgroundChat,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        children: [
          // 返回按钮
          Align(
            alignment: Alignment.centerLeft,
            child: _BackButton(
              unread: unread,
              onTap: onBack,
            ),
          ),
          // 标题（正在输入时显示状态）
          Align(
            alignment: Alignment.center,
            child: Text(
              isTyping ? '对方正在输入...' : title,
              style: AppStyles.titleLarge,
            ),
          ),
          // 更多按钮
          Align(
            alignment: Alignment.centerRight,
            child: _MoreButton(onTap: onMore),
          ),
        ],
      ),
    );
  }
}

/// 返回按钮组件
class _BackButton extends StatefulWidget {
  const _BackButton({
    required this.unread,
    required this.onTap,
  });

  final int unread;
  final VoidCallback onTap;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppAssets.iconGoBack,
            width: 12,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          if (widget.unread > 0)
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '${widget.unread}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 更多按钮组件
class _MoreButton extends StatefulWidget {
  const _MoreButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_MoreButton> createState() => _MoreButtonState();
}

class _MoreButtonState extends State<_MoreButton> {
  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SvgPicture.asset(
          AppAssets.iconThreeDot,
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            AppColors.textPrimary,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

