import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/models/chat_message.dart';
import 'message_bubbles/message_bubbles.dart';
import 'message_action_menu.dart';

/// 单条消息组件
class MessageItem extends StatefulWidget {
  const MessageItem({
    super.key,
    required this.message,
    this.showAnimation = true,
    this.onDelete,
    this.onQuote,
  });

  final ChatMessage message;
  final bool showAnimation;
  final VoidCallback? onDelete;
  final Function(String)? onQuote;

  @override
  State<MessageItem> createState() => _MessageItemState();
}

class _MessageItemState extends State<MessageItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppStyles.animationNormal,
    );
    
    _slideAnimation = Tween<double>(
      begin: widget.message.isOutgoing ? 20.0 : -20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.showAnimation) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 时间戳、系统消息、撤回消息
    if (widget.message.type == 'timestamp') {
      return _buildTimestamp();
    }

    if (widget.message.type == 'system' || widget.message.type == 'recall') {
      return _buildSystemMessage();
    }

    // 普通消息
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: _buildNormalMessage(),
    );
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.overlayLight,
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          ),
          child: Text(
            widget.message.text ?? '',
            style: AppStyles.timestamp,
          ),
        ),
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.overlayLight,
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          ),
          child: Text(
            widget.message.text ?? '',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalMessage() {
    final bool isOutgoing = widget.message.isOutgoing;
    final String avatar = widget.message.avatar ??
        (isOutgoing ? 'assets/avatar.png' : 'assets/me.png');

    final rowChildren = <Widget>[
      _MessageAvatar(avatar: avatar),
      const SizedBox(width: 8),
      Expanded(
        child: _MessageContent(
          message: widget.message,
          isOutgoing: isOutgoing,
          onLongPress: () => _showActionMenu(context),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isOutgoing ? rowChildren.reversed.toList() : rowChildren,
      ),
    );
  }

  final GlobalKey _messageKey = GlobalKey();

  void _showActionMenu(BuildContext context) {
    MessageActionOverlay.show(
      context: context,
      messageKey: _messageKey,
      message: widget.message.text ?? '',
      isOutgoing: widget.message.isOutgoing,
      onAction: (action) {
        switch (action) {
          case 'copy':
            // 已在 Overlay 中处理
            break;
          case 'delete':
            widget.onDelete?.call();
            break;
          case 'quote':
            widget.onQuote?.call(widget.message.text ?? '');
            break;
          case 'forward':
            // TODO: 实现转发
            break;
          case 'revoke':
            // TODO: 实现撤回
            break;
          case 'multiSelect':
            // TODO: 实现多选
            break;
        }
      },
    );
  }
}

/// 头像组件
class _MessageAvatar extends StatelessWidget {
  const _MessageAvatar({required this.avatar});

  final String avatar;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'avatar_$avatar',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        child: Image.asset(
          avatar,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 40,
              height: 40,
              color: AppColors.background,
              child: const Icon(
                Icons.person,
                color: AppColors.textSecondary,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 消息内容组件
class _MessageContent extends StatefulWidget {
  const _MessageContent({
    required this.message,
    required this.isOutgoing,
    this.onLongPress,
  });

  final ChatMessage message;
  final bool isOutgoing;
  final VoidCallback? onLongPress;

  @override
  State<_MessageContent> createState() => _MessageContentState();
}

class _MessageContentState extends State<_MessageContent> {
  final GlobalKey _bubbleKey = GlobalKey();
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Widget bubble;

    switch (widget.message.type) {
      case 'image':
        bubble = ImageBubble(message: widget.message);
        break;
      case 'voice':
        bubble = VoiceBubble(message: widget.message, isOutgoing: widget.isOutgoing);
        break;
      case 'red-packet':
        bubble = RedPacketBubble(message: widget.message, isOutgoing: widget.isOutgoing);
        break;
      case 'transfer':
        bubble = TransferBubble(message: widget.message, isOutgoing: widget.isOutgoing);
        break;
      default:
        bubble = TextBubble(message: widget.message, isOutgoing: widget.isOutgoing);
    }

    return Align(
      alignment: widget.isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Column(
          crossAxisAlignment:
              widget.isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              key: _bubbleKey,
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _showActionMenu();
              },
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              onLongPressEnd: (_) => setState(() => _pressed = false),
              child: AnimatedScale(
                scale: _pressed ? 0.95 : 1.0,
                duration: AppStyles.animationFast,
                child: bubble,
              ),
            ),
            // 只显示发送失败状态
            if (widget.message.sendStatus == 'failed')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.error_outline,
                  size: 14,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showActionMenu() {
    final renderBox = _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    MessageActionOverlay.show(
      context: context,
      messageKey: _bubbleKey,
      message: widget.message.text ?? '',
      isOutgoing: widget.isOutgoing,
      onAction: (action) {
        // 操作在 Overlay 中处理
      },
    );
  }
}

