import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/models/chat_message.dart';
import 'package:zichat/widgets/weui/weui.dart';
import 'base_bubble.dart';

/// 文本消息气泡
class TextBubble extends StatelessWidget {
  const TextBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
    this.onLongPress,
  });

  final ChatMessage message;
  final bool isOutgoing;
  final VoidCallback? onLongPress;

  void _showContextMenu(BuildContext context, Offset position) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 8),
              Text('复制'),
            ],
          ),
          onTap: () {
            Clipboard.setData(ClipboardData(text: message.text ?? ''));
            WeuiToast.show(
              context,
              message: '已复制',
              duration: const Duration(seconds: 1),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isOutgoing
        ? AppColors.bubbleOutgoing
        : AppColors.bubbleIncoming;

    return TappableBubble(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress?.call();
      },
      child: GestureDetector(
        onLongPressStart: (details) {
          HapticFeedback.mediumImpact();
          _showContextMenu(context, details.globalPosition);
        },
        child: BaseBubble(
          backgroundColor: bgColor,
          isOutgoing: isOutgoing,
          child: Text(
            message.text ?? '',
            style: AppStyles.messageText,
          ),
        ),
      ),
    );
  }
}

