import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zichat/constants/app_styles.dart';

/// 消息长按操作菜单
class MessageActionMenu extends StatelessWidget {
  const MessageActionMenu({
    super.key,
    required this.message,
    required this.isOutgoing,
    required this.onCopy,
    required this.onDelete,
    required this.onForward,
    this.onRevoke,
    this.onMultiSelect,
    this.onQuote,
  });

  final String message;
  final bool isOutgoing;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback onForward;
  final VoidCallback? onRevoke;
  final VoidCallback? onMultiSelect;
  final VoidCallback? onQuote;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4C4C4C),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: Icons.content_copy_outlined,
                label: '复制',
                onTap: onCopy,
              ),
              _ActionButton(
                icon: Icons.send_outlined,
                label: '转发',
                onTap: onForward,
              ),
              if (onQuote != null)
                _ActionButton(
                  icon: Icons.format_quote_outlined,
                  label: '引用',
                  onTap: onQuote!,
                ),
              if (onMultiSelect != null)
                _ActionButton(
                  icon: Icons.check_circle_outline,
                  label: '多选',
                  onTap: onMultiSelect!,
                ),
              _ActionButton(
                icon: Icons.delete_outline,
                label: '删除',
                onTap: onDelete,
              ),
              if (isOutgoing && onRevoke != null)
                _ActionButton(
                  icon: Icons.undo_outlined,
                  label: '撤回',
                  onTap: onRevoke!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: AppStyles.animationFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _pressed ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 显示消息操作菜单的 Overlay
class MessageActionOverlay {
  static OverlayEntry? _overlayEntry;
  static VoidCallback? _onDismiss;

  static void show({
    required BuildContext context,
    required GlobalKey messageKey,
    required String message,
    required bool isOutgoing,
    required Function(String) onAction,
  }) {
    dismiss();

    final renderBox = messageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    double top = position.dy - 70;
    if (top < 50) {
      top = position.dy + size.height + 10;
    }

    double left = position.dx + size.width / 2 - 150;
    if (left < 10) left = 10;
    if (left + 300 > screenSize.width) {
      left = screenSize.width - 310;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: dismiss,
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: TweenAnimationBuilder<double>(
              duration: AppStyles.animationFast,
              tween: Tween(begin: 0.8, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: MessageActionMenu(
                message: message,
                isOutgoing: isOutgoing,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: message));
                  onAction('copy');
                  dismiss();
                  _showToast(context, '已复制');
                },
                onDelete: () {
                  onAction('delete');
                  dismiss();
                },
                onForward: () {
                  onAction('forward');
                  dismiss();
                },
                onRevoke: isOutgoing ? () {
                  onAction('revoke');
                  dismiss();
                } : null,
                onQuote: () {
                  onAction('quote');
                  dismiss();
                },
                onMultiSelect: () {
                  onAction('multiSelect');
                  dismiss();
                },
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    HapticFeedback.mediumImpact();
  }

  static void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _onDismiss?.call();
    _onDismiss = null;
  }

  static void _showToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 0,
        right: 0,
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 200),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + 0.2 * value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF4C4C4C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 1), () {
      entry.remove();
    });
  }
}

