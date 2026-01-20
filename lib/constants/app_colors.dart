import 'package:flutter/material.dart';

/// 应用全局颜色常量
class AppColors {
  AppColors._();

  // 主题色
  static const Color primary = Color(0xFF07C160);
  static const Color primaryLight = Color(0xFF95EC69);
  static const Color primaryDark = Color(0xFF06AD56);

  // 背景色
  static const Color background = Color(0xFFF7F7F7);
  static const Color backgroundChat = Color(0xFFEDEDED);
  static const Color surface = Colors.white;

  // 文字颜色
  static const Color textPrimary = Color(0xE6000000); // rgba(0,0,0,0.9)
  static const Color textSecondary = Color(0x8C000000); // rgba(0,0,0,0.55)
  static const Color textHint = Color(0x4D000000); // rgba(0,0,0,0.3)
  static const Color textDisabled = Color(0x26000000); // rgba(0,0,0,0.15)
  static const Color textWhite = Colors.white;
  static const Color disabledBg = Color(0x0D000000); // rgba(0,0,0,0.05)

  // 链接色（WeUI 默认链接）
  static const Color link = Color(0xFF576B95);

  // 边框和分割线
  static const Color border = Color(0x1A000000); // rgba(0,0,0,0.1)
  static const Color divider = Color(0x1A000000); // rgba(0,0,0,0.1)

  // 消息气泡
  static const Color bubbleOutgoing = Color(0xFF95EC69);
  static const Color bubbleIncoming = Colors.white;

  // 转账相关
  static const Color transferPending = Color(0xFFFF9852);
  static const Color transferAccepted = Color(0xFFFFD8AD);

  // 红包相关
  static const Color redPacketStart = Color(0xFFFB4A3C);
  static const Color redPacketEnd = Color(0xFFEF3A2E);

  // 状态色
  static const Color online = Color(0xFF23C343);
  static const Color unreadBadge = Color(0xFFFA5151);
  static const Color error = Color(0xFFFA5151);

  // 遮罩
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x26000000);

  // 阴影
  static const Color shadow = Color(0x0F000000); // rgba(0,0,0,0.06)
}

