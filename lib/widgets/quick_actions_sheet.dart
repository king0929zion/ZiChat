import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/pages/add_contacts_page.dart';
import 'package:zichat/pages/code_scanner_page.dart';
import 'package:zichat/pages/money_qrcode_page.dart';
import 'package:zichat/widgets/weui/weui.dart';

/// 显示快速操作弹窗 (仿微信右上角弹出菜单)
void showQuickActionsSheet(BuildContext context) {
  final double statusBarHeight = MediaQuery.of(context).padding.top;
  final double screenWidth = MediaQuery.of(context).size.width;
  
  // 估算右上角加号按钮的位置
  // Header高度 52, 右边距 12, 按钮宽高 36
  // 按钮中心垂直位置: statusBarHeight + (52 - 36) / 2
  const double buttonSize = 36.0;
  const double rightMargin = 12.0;
  const double headerHeight = 52.0;
  
  final double buttonTop = statusBarHeight + (headerHeight - buttonSize) / 2;
  final double buttonRight = rightMargin;
  final double buttonLeft = screenWidth - buttonRight - buttonSize;
  
  // 菜单显示在按钮正下方微偏左
  final RelativeRect position = RelativeRect.fromLTRB(
    buttonLeft,
    buttonTop + buttonSize + 5, // 按钮下方 5px
    buttonRight,
    0,
  );

  showMenu<String>(
    context: context,
    position: position,
    color: const Color(0xFF4C4C4C),
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    items: [
      _buildMenuItem(context, '发起群聊', Icons.chat_bubble_outline, 'group_chat'),
      _buildMenuItem(context, '添加朋友', Icons.person_add_alt_1, 'add_friend'),
      _buildMenuItem(context, '扫一扫', Icons.qr_code_scanner, 'scan'),
      _buildMenuItem(context, '收付款', Icons.account_balance_wallet_outlined, 'money'),
    ],
  ).then((value) {
    if (value == null) return;
      switch (value) {
        case 'group_chat':
        WeuiToast.show(context, message: '发起群聊功能暂未开放');
        break;
        case 'add_friend':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddContactsPage()),
        );
        break;
      case 'scan':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CodeScannerPage()),
        );
        break;
      case 'money':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MoneyQrcodePage()),
        );
        break;
    }
  });
}

PopupMenuItem<String> _buildMenuItem(
  BuildContext context,
  String label,
  IconData icon,
  String value,
) {
  return PopupMenuItem<String>(
    value: value,
    height: 48,
    padding: EdgeInsets.zero,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

