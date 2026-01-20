import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zichat/constants/app_colors.dart';

enum WeuiActionSheetTone {
  normal,
  primary,
  destructive,
}

class WeuiActionSheetAction {
  const WeuiActionSheetAction({
    required this.label,
    required this.onTap,
    this.tone = WeuiActionSheetTone.normal,
    this.enabled = true,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onTap;
  final WeuiActionSheetTone tone;
  final bool enabled;
  final bool emphasized;
}

Future<void> showWeuiActionSheet({
  required BuildContext context,
  required List<WeuiActionSheetAction> actions,
  String cancelText = '取消',
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _WeuiActionSheetGroup(actions: actions),
              const SizedBox(height: 8),
              _WeuiActionSheetGroup(
                actions: [
                  WeuiActionSheetAction(
                    label: cancelText,
                    onTap: () {},
                    emphasized: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _WeuiActionSheetGroup extends StatelessWidget {
  const _WeuiActionSheetGroup({required this.actions});

  final List<WeuiActionSheetAction> actions;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              _WeuiActionSheetItem(action: actions[i]),
              if (i < actions.length - 1)
                const Divider(height: 1, color: AppColors.divider),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeuiActionSheetItem extends StatelessWidget {
  const _WeuiActionSheetItem({required this.action});

  final WeuiActionSheetAction action;

  Color get _textColor {
    if (!action.enabled) return AppColors.textHint;
    switch (action.tone) {
      case WeuiActionSheetTone.primary:
        return AppColors.primary;
      case WeuiActionSheetTone.destructive:
        return const Color(0xFFFA5151);
      case WeuiActionSheetTone.normal:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool clickable = action.enabled;

    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: clickable
            ? () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                action.onTap();
              }
            : null,
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text(
              action.label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: action.emphasized ? FontWeight.w600 : FontWeight.w500,
                color: _textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
