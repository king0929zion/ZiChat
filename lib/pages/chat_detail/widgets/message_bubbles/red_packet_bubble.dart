import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/models/chat_message.dart';
import 'base_bubble.dart';

/// 红包消息气泡
class RedPacketBubble extends StatefulWidget {
  const RedPacketBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
    this.onTap,
  });

  final ChatMessage message;
  final bool isOutgoing;
  final VoidCallback? onTap;

  @override
  State<RedPacketBubble> createState() => _RedPacketBubbleState();
}

class _RedPacketBubbleState extends State<RedPacketBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _isOpened = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isOpened) return;
    
    HapticFeedback.heavyImpact();
    
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });

    setState(() {
      _isOpened = true;
    });

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.message.text ?? '恭喜发财，大吉大利';
    final String note = widget.message.note ?? '微信红包';
    final String status = widget.message.status ?? '微信红包';

    return TappableBubble(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: child,
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                gradient: LinearGradient(
                  colors: _isOpened
                      ? [
                          AppColors.redPacketStart.withOpacity(0.6),
                          AppColors.redPacketEnd.withOpacity(0.6),
                        ]
                      : [AppColors.redPacketStart, AppColors.redPacketEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: _isOpened
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.redPacketEnd.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildRedPacketIcon(),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textWhite,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isOpened ? '已领取' : status,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textWhite.withOpacity(0.7),
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
                  color: AppColors.redPacketEnd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedPacketIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _isOpened ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 0.5,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.yellow.shade600,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '¥',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.redPacketEnd,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

