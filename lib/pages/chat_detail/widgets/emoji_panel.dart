import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';

/// Emoji 面板组件
class EmojiPanel extends StatefulWidget {
  const EmojiPanel({
    super.key,
    required this.recentEmojis,
    required this.onEmojiTap,
    required this.onEmojiDelete,
  });

  final List<String> recentEmojis;
  final ValueChanged<String> onEmojiTap;
  final VoidCallback onEmojiDelete;

  @override
  State<EmojiPanel> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel>
    {

  static const List<String> _allEmojis = [
    '😀', '😁', '😂', '🤣', '😊', '😍', '😘', '😚',
    '😎', '🤩', '😇', '🙂', '🙃', '😉', '😌', '😴',
    '😤', '🤔', '🤗', '🤭', '🥳', '😢', '😭', '😡',
    '🤯', '😱', '😳', '🤤', '😋', '😜', '🤪', '😏',
    '🥰', '🤓', '🧐', '😒', '😔', '😞', '😣', '😖',
    '😫', '😩', '🥺', '😤', '😠', '😡', '🤬', '😈',
    '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '🤙',
    '👋', '🤚', '🖐️', '✋', '🖖', '👏', '🙌', '👐',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundChat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopIcons(),
          const SizedBox(height: 8),
          _buildHandleBar(),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.recentEmojis.isNotEmpty) ...[
                    const Text(
                      '最近使用',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildEmojiWrap(widget.recentEmojis),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    '所有表情',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildEmojiWrap(_allEmojis),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildDeleteRow(),
        ],
      ),
    );
  }

  Widget _buildTopIcons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildTopIcon(Icons.search, active: false),
          const SizedBox(width: 16),
          _buildTopIcon(Icons.emoji_emotions, active: true),
          const SizedBox(width: 16),
          _buildTopIcon(Icons.favorite_border, active: false),
          const SizedBox(width: 16),
          _buildTopIcon(Icons.back_hand, active: false),
        ],
      ),
    );
  }

  Widget _buildTopIcon(IconData icon, {required bool active}) {
    return AnimatedContainer(
      duration: AppStyles.animationFast,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: Icon(
        icon,
        size: 20,
        color: active ? AppColors.textPrimary : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildHandleBar() {
    return Center(
      child: Container(
        width: 80,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.overlayLight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildEmojiWrap(List<String> emojis) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: emojis.map((e) => _EmojiItem(
        emoji: e,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onEmojiTap(e);
        },
      )).toList(),
    );
  }

  Widget _buildDeleteRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 12, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: _DeleteButton(onTap: widget.onEmojiDelete),
      ),
    );
  }
}

/// 单个 Emoji 组件
class _EmojiItem extends StatefulWidget {
  const _EmojiItem({
    required this.emoji,
    required this.onTap,
  });

  final String emoji;
  final VoidCallback onTap;

  @override
  State<_EmojiItem> createState() => _EmojiItemState();
}

class _EmojiItemState extends State<_EmojiItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppStyles.animationFast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
          width: 32,
          height: 32,
          child: Center(
            child: Text(
              widget.emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }
}

/// 删除按钮组件
class _DeleteButton extends StatefulWidget {
  const _DeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: AppStyles.animationFast,
        width: 44,
        height: 32,
        decoration: BoxDecoration(
          color: _isPressed ? AppColors.background : AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

