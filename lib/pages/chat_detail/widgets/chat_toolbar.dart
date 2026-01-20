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
                    onSend: onSend,
                  ),
          ),
          const SizedBox(width: 10),
          // 表情按钮
          _ToolbarIconButton(
            onPressed: onEmojiToggle,
            asset: showEmoji ? AppAssets.iconKeyboard : AppAssets.iconEmoji,
          ),
          const SizedBox(width: 10),
          // 发送/更多按钮（不做切换动画，收敛整体动效）
          hasText
              ? _SendButton(
                  onSend: onSend,
                  onLongPress: onSendByAi,
                )
              : _ToolbarIconButton(
                  onPressed: onFnToggle,
                  asset: AppAssets.iconCirclePlus,
                ),
        ],
      ),
    );
  }
}

/// 工具栏图标按钮
class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    super.key,
    required this.onPressed,
    required this.asset,
  });

  final VoidCallback onPressed;
  final String asset;

  void _handleTap() {
    HapticFeedback.selectionClick();
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(16),
          highlightColor: AppColors.disabledBg,
          splashColor: Colors.transparent,
          child: Center(
            child: SvgPicture.asset(
              asset,
              width: 28,
              height: 28,
            ),
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
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onFocus;
  final VoidCallback onSend;

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
        onSubmitted: (_) => onSend(),
        decoration: const InputDecoration(
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
          color: _isPressed
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          border: _isPressed ? Border.all(color: AppColors.primary, width: 1.5) : null,
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

/// 发送按钮组件（纯色平面材质，不做悬浮阴影）
class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.onSend,
    required this.onLongPress,
  });

  final VoidCallback onSend;
  final VoidCallback onLongPress;

  void _handleTap() {
    HapticFeedback.lightImpact();
    onSend();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    onLongPress();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
      child: InkWell(
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        highlightColor: Colors.white.withValues(alpha: 0.12),
        splashColor: Colors.transparent,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
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

