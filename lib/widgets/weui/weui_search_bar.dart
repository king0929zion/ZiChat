import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zichat/constants/app_colors.dart';

class WeuiSearchBar extends StatefulWidget {
  const WeuiSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = '搜索',
    this.onChanged,
    this.onSubmitted,
    this.onCancel,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCancel;
  final bool autofocus;

  @override
  State<WeuiSearchBar> createState() => _WeuiSearchBarState();
}

class _WeuiSearchBarState extends State<WeuiSearchBar> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _ownsFocusNode = false;
  bool _focusing = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusing = _focusNode.hasFocus;
    _focusNode.addListener(_handleFocusChanged);
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    widget.controller.removeListener(_handleTextChanged);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    setState(() => _focusing = _focusNode.hasFocus);
  }

  void _handleTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _clear() {
    HapticFeedback.selectionClick();
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  void _cancel() {
    HapticFeedback.selectionClick();
    _focusNode.unfocus();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bool showCancel = _focusing;
    final bool showClear = widget.controller.text.isNotEmpty;

    return Container(
      color: AppColors.backgroundChat,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(Icons.search, size: 20, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      autofocus: widget.autofocus,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      style: const TextStyle(
                        fontSize: 17,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: const TextStyle(
                          fontSize: 17,
                          color: AppColors.textHint,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                  if (showClear)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _clear,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.cancel,
                          size: 20,
                          color: AppColors.textHint,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeOut,
            child: showCancel
                ? Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: GestureDetector(
                      onTap: _cancel,
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 17,
                          color: AppColors.link,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

