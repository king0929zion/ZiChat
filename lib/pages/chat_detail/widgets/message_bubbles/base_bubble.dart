import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';

/// 基础气泡组件（带箭头）
class BaseBubble extends StatelessWidget {
  const BaseBubble({
    super.key,
    required this.backgroundColor,
    required this.child,
    required this.isOutgoing,
    this.constraints,
    this.padding,
  });

  final Color backgroundColor;
  final Widget child;
  final bool isOutgoing;
  final BoxConstraints? constraints;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          constraints: constraints ?? const BoxConstraints(minHeight: 40),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          ),
          child: child,
        ),
        // 箭头：宽高 8x8，旋转 45度
        Positioned(
          top: 16,
          right: isOutgoing ? -4 : null,
          left: isOutgoing ? null : -4,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 8,
              height: 8,
              color: backgroundColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// 带按压效果的气泡包装器
class TappableBubble extends StatefulWidget {
  const TappableBubble({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;

  @override
  State<TappableBubble> createState() => _TappableBubbleState();
}

class _TappableBubbleState extends State<TappableBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled && widget.onTap == null && widget.onLongPress == null) {
      return widget.child;
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

