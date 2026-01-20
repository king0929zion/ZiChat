import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zichat/constants/app_colors.dart';

class WeuiSwitch extends StatelessWidget {
  const WeuiSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  bool get _clickable => enabled && onChanged != null;

  @override
  Widget build(BuildContext context) {
    final bool isOn = value;
    final Color trackColor = isOn ? AppColors.primary : AppColors.border;
    final Duration trackDuration = const Duration(milliseconds: 100);
    final Duration thumbDuration = const Duration(milliseconds: 350);
    const Curve thumbCurve = Cubic(0.4, 0.4, 0.25, 1.35);

    final Widget body = AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: _clickable ? 1 : 0.1,
      child: AnimatedContainer(
        duration: trackDuration,
        curve: Curves.linear,
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedAlign(
          duration: thumbDuration,
          curve: thumbCurve,
          alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      toggled: isOn,
      enabled: _clickable,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _clickable
            ? () {
                HapticFeedback.selectionClick();
                onChanged?.call(!isOn);
              }
            : null,
        child: body,
      ),
    );
  }
}

