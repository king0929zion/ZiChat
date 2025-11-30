import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';

/// 聊天底部工具栏
class ChatToolbar extends StatelessWidget {
  const ChatToolbar({
    super.key,
    required this.controller,
    required this.voiceMode,
    required this.showEmoji,
    required this.showFn,
    required this.hasText,
    required this.onVoiceToggle,
    required this.onEmojiToggle,
    required this.onFnToggle,
    required this.onSend,
    required this.onSendByAi,
    required this.onFocus,
  });

  final TextEditingController controller;
  final bool voiceMode;
  final bool showEmoji;
  final bool showFn;
  final bool hasText;
  final VoidCallback onVoiceToggle;
  final VoidCallback onEmojiToggle;
  final VoidCallback onFnToggle;
  final VoidCallback onSend;
  final VoidCallback onSendByAi;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundChat,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 语音/键盘切换按钮
          _ToolbarIconButton(
            onPressed: onVoiceToggle,
            asset: voiceMode
                ? AppAssets.iconKeyboard
                : AppAssets.iconVoiceRecord,
          ),
          const SizedBox(width: 10),
          // 输入框或语音按钮
          Expanded(
            child: voiceMode
                ? const _VoiceButton()
                : _InputField(
                    controller: controller,
                    onFocus: onFocus,
                  ),
          ),
          const SizedBox(width: 10),
          // 表情按钮
          _ToolbarIconButton(
            onPressed: onEmojiToggle,
            asset: showEmoji ? AppAssets.iconKeyboard : AppAssets.iconEmoji,
          ),
          const SizedBox(width: 10),
          // 发送/更多按钮
          AnimatedSwitcher(
            duration: AppStyles.animationFast,
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: hasText
                ? _SendButton(
                    key: const ValueKey('send'),
                    onSend: onSend,
                    onLongPress: onSendByAi,
                  )
                : _ToolbarIconButton(
                    key: const ValueKey('fn'),
                    onPressed: onFnToggle,
                    asset: AppAssets.iconCirclePlus,
                  ),
          ),
        ],
      ),
    );
  }
}

/// 工具栏图标按钮
class _ToolbarIconButton extends StatefulWidget {
  const _ToolbarIconButton({
    super.key,
    required this.onPressed,
    required this.asset,
  });

  final VoidCallback onPressed;
  final String asset;

  @override
  State<_ToolbarIconButton> createState() => _ToolbarIconButtonState();
}

class _ToolbarIconButtonState extends State<_ToolbarIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: SizedBox(
          width: 28,
          height: 28,
          child: SvgPicture.asset(
            widget.asset,
            width: 28,
            height: 28,
          ),
        ),
      ),
    );
  }
}

/// 输入框组件
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.onFocus,
  });

  final TextEditingController controller;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: controller,
        onTap: onFocus,
        decoration: const InputDecoration(
          hintText: '发送消息',
          hintStyle: TextStyle(
            fontSize: 18,
            color: AppColors.textHint,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
        maxLines: 1,
        textInputAction: TextInputAction.send,
      ),
    );
  }
}

/// 语音按钮组件
class _VoiceButton extends StatefulWidget {
  const _VoiceButton();

  @override
  State<_VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<_VoiceButton> {
  bool _isPressed = false;

  void _handleLongPressStart(LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    setState(() => _isPressed = true);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = false);
  }

  void _handleLongPressCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _handleLongPressStart,
      onLongPressEnd: _handleLongPressEnd,
      onLongPressCancel: _handleLongPressCancel,
      child: AnimatedContainer(
        duration: AppStyles.animationFast,
        height: 38,
        decoration: BoxDecoration(
          color: _isPressed ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          border: _isPressed
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          _isPressed ? '松开 发送' : '按住 说话',
          style: TextStyle(
            fontSize: 16,
            color: _isPressed ? AppColors.primary : AppColors.textPrimary,
            fontWeight: _isPressed ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// 发送按钮组件
class _SendButton extends StatefulWidget {
  const _SendButton({
    super.key,
    required this.onSend,
    required this.onLongPress,
  });

  final VoidCallback onSend;
  final VoidCallback onLongPress;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onSend();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    widget.onLongPress();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      onLongPress: _handleLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            '发送',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

