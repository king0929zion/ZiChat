import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/pages/settings_general_page.dart';
import 'package:zichat/pages/settings_chat_page.dart';
import 'package:zichat/pages/settings_ai_page.dart';
import 'package:zichat/widgets/weui/weui.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    void showTodo() {
      WeuiToast.show(context, message: '功能开发中');
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          padding: const EdgeInsets.all(8),
          icon: SvgPicture.asset(
            AppAssets.iconGoBack,
            width: 12,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: true,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                WeuiCellGroup(
                  margin: const EdgeInsets.only(top: 12),
                  children: [
                    WeuiCell(title: '个人资料', onTap: showTodo),
                    WeuiCell(title: '账号安全', onTap: showTodo),
                  ],
                ),
                WeuiCellGroup(
                  margin: const EdgeInsets.only(top: 12),
                  children: [
                    WeuiCell(title: '未成年人模式', onTap: showTodo),
                    WeuiCell(title: '关怀模式', onTap: showTodo),
                  ],
                ),
                WeuiCellGroup(
                  margin: const EdgeInsets.only(top: 12),
                  children: [
                    WeuiCell(title: '通知', onTap: showTodo),
                    WeuiCell(
                      title: 'AI 设置',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsAiPage()),
                        );
                      },
                    ),
                    WeuiCell(
                      title: '聊天',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsChatPage(),
                          ),
                        );
                      },
                    ),
                    WeuiCell(
                      title: '通用',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsGeneralPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                WeuiCellGroup(
                  title: '隐私',
                  margin: const EdgeInsets.only(top: 12),
                  children: [
                    WeuiCell(title: '朋友权限', onTap: showTodo),
                    WeuiCell(title: '个人信息与权限', onTap: showTodo),
                  ],
                ),
                WeuiCellGroup(
                  margin: const EdgeInsets.only(top: 12),
                  children: [
                    WeuiCell(title: '关于微信', onTap: showTodo),
                    WeuiCell(title: '帮助与反馈', onTap: showTodo),
                  ],
                ),
                const SizedBox(height: 12),
                _WeuiCenterActionCell(label: '切换账号', onTap: showTodo),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeuiCenterActionCell extends StatelessWidget {
  const _WeuiCenterActionCell({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
