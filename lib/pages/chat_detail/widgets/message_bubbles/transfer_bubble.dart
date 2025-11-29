import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/models/chat_message.dart';
import 'package:zichat/pages/transfer_receive_page.dart';
import 'base_bubble.dart';

/// 转账消息气泡
class TransferBubble extends StatefulWidget {
  const TransferBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
  });

  final ChatMessage message;
  final bool isOutgoing;

  @override
  State<TransferBubble> createState() => _TransferBubbleState();
}

class _TransferBubbleState extends State<TransferBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleTap(BuildContext context) {
    HapticFeedback.mediumImpact();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransferReceivePage(
          amount: widget.message.amount ?? '0.00',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String amount = widget.message.amount ?? '0.00';
    final String rawStatus = widget.message.status ?? '';

    final bool isAccepted = rawStatus.toLowerCase().contains('accepted') ||
        rawStatus.contains('已收');

    final Color bubbleColor =
        isAccepted ? AppColors.transferAccepted : AppColors.transferPending;

    String descText;
    if (rawStatus.trim().isNotEmpty) {
      descText = rawStatus.trim();
    } else if (isAccepted) {
      descText = '已收款';
    } else if (widget.message.direction == 'out') {
      descText = '待对方确认收款';
    } else {
      descText = '待收款';
    }

    return TappableBubble(
      onTap: () => _handleTap(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 235,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIcon(isAccepted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAmountText(amount, isAccepted),
                          const SizedBox(height: 2),
                          Text(
                            descText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Color(0x99FFFFFF),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: const Text(
                    '微信转账',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 箭头
          Positioned(
            top: 16,
            right: widget.isOutgoing ? -4 : null,
            left: widget.isOutgoing ? null : -4,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 8,
                height: 8,
                color: bubbleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(bool isAccepted) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        if (isAccepted) {
          return child!;
        }
        // 未收款时添加闪烁效果
        final shimmer = 0.7 + 0.3 * (1 + math.sin(_shimmerController.value * 2 * math.pi)) / 2;
        return Opacity(
          opacity: shimmer,
          child: child,
        );
      },
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SvgPicture.asset(
            AppAssets.iconTransferOutline,
            width: 32,
            height: 32,
            colorFilter: const ColorFilter.mode(
              AppColors.textWhite,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountText(String amount, bool isAccepted) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppStyles.animationNormal,
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: Alignment.centerLeft,
          child: Text(
            '¥$amount',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textWhite,
            ),
          ),
        );
      },
    );
  }
}

