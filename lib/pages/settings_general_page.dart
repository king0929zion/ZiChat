import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/pages/model_config_page.dart';
import 'package:zichat/pages/settings_language_page.dart';
import 'package:zichat/widgets/weui/weui.dart';

class SettingsGeneralPage extends StatefulWidget {
  const SettingsGeneralPage({super.key});

  @override
  State<SettingsGeneralPage> createState() => _SettingsGeneralPageState();
}

class _SettingsGeneralPageState extends State<SettingsGeneralPage> {
  bool _landscapeOn = false;
  bool _nfcOn = true;
  final String _language = 'zh-CN';

  String get _languageLabel => _language == 'zh-CN' ? '简体中文' : '英语';

  void _toast(String message) => WeuiToast.show(context, message: message);

  void _toggleLandscape(bool value) {
    setState(() => _landscapeOn = value);
    _toast(value ? '已开启横屏模式' : '已关闭横屏模式');
  }

  void _toggleNfc(bool value) {
    setState(() => _nfcOn = value);
    _toast(value ? '已开启 NFC 功能' : '已关闭 NFC 功能');
  }

  Future<void> _openLanguagePage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsLanguagePage()),
    );
  }

  void _openAiSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ModelConfigPage()),
    );
  }

  void _showFeatureDevToast() => _toast('功能开发中');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('通用'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                WeuiCellGroup(
                  title: '界面与显示',
                  children: [
                    WeuiCell(
                      title: '深色模式',
                      value: '已关闭',
                      onTap: _showFeatureDevToast,
                    ),
                    WeuiCell(
                      title: '横屏模式',
                      showArrow: false,
                      trailing: WeuiSwitch(
                        value: _landscapeOn,
                        onChanged: _toggleLandscape,
                      ),
                    ),
                    WeuiCell(
                      title: 'NFC 功能',
                      showArrow: false,
                      trailing: WeuiSwitch(
                        value: _nfcOn,
                        onChanged: _toggleNfc,
                      ),
                    ),
                    WeuiCell(
                      title: '自动下载微信安装包',
                      value: '仅在 Wi-Fi 下下载',
                      onTap: _showFeatureDevToast,
                    ),
                    WeuiCell(
                      title: '语言',
                      value: _languageLabel,
                      onTap: _openLanguagePage,
                    ),
                    WeuiCell(
                      title: '字体大小',
                      onTap: _showFeatureDevToast,
                    ),
                  ],
                ),
                WeuiCellGroup(
                  title: '智能功能',
                  children: [
                    WeuiCell(title: 'AI 设置', onTap: _openAiSettings),
                  ],
                ),
                WeuiCellGroup(
                  title: '其他',
                  children: [
                    WeuiCell(title: '存储空间', onTap: _showFeatureDevToast),
                    WeuiCell(title: '发现页管理', onTap: _showFeatureDevToast),
                    WeuiCell(title: '辅助功能', onTap: _showFeatureDevToast),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

