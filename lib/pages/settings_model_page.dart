import 'package:flutter/material.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/pages/api_list_page.dart';

/// AI 模型选择设置页面（已弃用，重定向到 API 管理）
@Deprecated('请使用 API 管理功能')
class SettingsModelPage extends StatelessWidget {
  const SettingsModelPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 自动跳转到 API 管理页面
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ApiListPage()),
      );
    });

    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

