import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 统一的 Cupertino 风格提示服务
/// 提供 iOS 风格的 Toast、Alert、ActionSheet 等提示组件
class CupertinoToast {
  /// 显示 Toast（默认2秒）
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlayState = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        duration: duration,
      ),
    );
    overlayState.insert(entry);

    Future.delayed(duration, () {
      entry.remove();
    });
  }

  /// 显示短时间 Toast（2秒）
  static void showShort(
    BuildContext context,
    String message,
  ) {
    show(context, message, duration: const Duration(seconds: 2));
  }

  /// 显示长时间 Toast（3.5秒）
  static void showLong(
    BuildContext context,
    String message,
  ) {
    show(context, message, duration: const Duration(seconds: 3));
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.2,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            widget.message,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

/// 显示 iOS 风格 Alert 对话框
Future<void> showCupertinoAlert({
  required BuildContext context,
  required String title,
  String? content,
  String confirmText = '确定',
  String cancelText = '取消',
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  bool isDestructive = false,
}) async {
  return showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: content != null ? Text(content) : null,
      actions: [
        if (cancelText.isNotEmpty)
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel?.call();
            },
            child: Text(
              cancelText,
              style: TextStyle(
                color: isDestructive
                    ? CupertinoColors.systemRed
                    : CupertinoColors.label,
              ),
            ),
          ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          isDefaultAction: true,
          child: Text(
            confirmText,
            style: TextStyle(
              color: isDestructive
                  ? CupertinoColors.systemRed
                  : CupertinoColors.activeBlue,
            ),
          ),
        ),
      ],
    ),
  );
}

/// 显示 iOS 风格 Action Sheet
Future<T?> showCupertinoActionSheet<T>({
  required BuildContext context,
  required String title,
  String? message,
  required List< CupertinoActionSheetAction> actions,
  String? cancelText,
  VoidCallback? onCancel,
}) async {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: title.isNotEmpty ? Text(title) : null,
      message: message != null ? Text(message) : null,
      actions: actions,
      cancelButton: cancelText != null
          ? CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel?.call();
              },
              isDefaultAction: true,
              child: Text(cancelText),
            )
          : null,
    ),
  );
}

/// 显示加载指示器
Future<void> showCupertinoLoading({
  required BuildContext context,
  String message = '加载中...',
}) async {
  return showCupertinoDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => WillPopScope(
      onWillPop: () async => false,
      child: CupertinoAlertDialog(
        title: Text(message),
        content: const Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: CupertinoActivityIndicator(),
        ),
      ),
    ),
  );
}

/// 隐藏加载指示器
void hideCupertinoLoading(BuildContext context) {
  Navigator.of(context).pop();
}
