import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/pages/model_config_page.dart';
import 'package:zichat/pages/settings_language_page.dart';
import 'package:zichat/utils/cupertino_toast.dart';

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

  void _showToast(String message) {
    CupertinoToast.show(context, message);
  }

  void _toggleLandscape() {
    setState(() {
      _landscapeOn = !_landscapeOn;
    });
    _showToast(_landscapeOn ? '已开启横屏模式' : '已关闭横屏模式');
  }

  void _toggleNfc() {
    setState(() {
      _nfcOn = !_nfcOn;
    });
    _showToast(_nfcOn ? '已开启 NFC 功能' : '已关闭 NFC 功能');
  }

  Future<void> _openLanguageDialog() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsLanguagePage()),
    );
    // 重新加载语言设置
    // final prefs = await SharedPreferences.getInstance();
    // final lang = prefs.getString('app_language') ?? 'zh-CN';
    // setState(() {
    //   _language = lang;
    // });
  }

  void _showFeatureDevToast() {
    _showToast('功能开发中');
  }

  void _openAiSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ModelConfigPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFEFEFF4);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            color: bg,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    children: [
                      const _SectionTitle(label: '界面与显示'),
                      _SettingsRow(
                        label: '深色模式',
                        right: _RightValueArrow(text: '已关闭'),
                        onTap: _showFeatureDevToast,
                      ),
                      _SettingsRow(
                        label: '横屏模式',
                        right: _ToggleSwitch(
                          active: _landscapeOn,
                          onChanged: (_) => _toggleLandscape(),
                        ),
                      ),
                      _SettingsRow(
                        label: 'NFC 功能',
                        right: _ToggleSwitch(
                          active: _nfcOn,
                          onChanged: (_) => _toggleNfc(),
                        ),
                      ),
                      _SettingsRow(
                        label: '自动下载微信安装包',
                        right: const _RightValueArrow(
                          text: '仅在 Wi-Fi 下下载',
                        ),
                        onTap: _showFeatureDevToast,
                      ),
                      _SettingsRow(
                        label: '语言',
                        right: _RightValueArrow(text: _languageLabel),
                        onTap: _openLanguageDialog,
                      ),
                      _SettingsRow(
                        label: '字体大小',
                        right: const _ArrowOnly(),
                        onTap: _showFeatureDevToast,
                      ),
                      const _SettingsDivider(),
                      const _SectionTitle(label: '智能功能'),
                      _SettingsRow(
                        label: 'AI 设置',
                        right: const _ArrowOnly(),
                        onTap: _openAiSettings,
                      ),
                      const _SettingsDivider(),
                      const _SectionTitle(label: '其他'),
                      _SettingsRow(
                        label: '存储空间',
                        right: const _ArrowOnly(),
                        onTap: _showFeatureDevToast,
                      ),
                      _SettingsRow(
                        label: '发现页管理',
                        right: const _ArrowOnly(),
                        onTap: _showFeatureDevToast,
                      ),
                      _SettingsRow(
                        label: '辅助功能',
                        right: const _ArrowOnly(),
                        onTap: _showFeatureDevToast,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 52,
      color: const Color(0xFFEFEFF4),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            padding: const EdgeInsets.all(8),
            icon: SvgPicture.asset(
              'assets/icon/common/go-back.svg',
              width: 12,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xFF1D2129),
                BlendMode.srcIn,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '通用',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D2129),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 36,
            height: 36,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFFEDEDED),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF86909C),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      color: const Color(0xFFEDEDED),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.right,
    this.onTap,
  });

  final String label;
  final Widget right;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell
(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE5E6EB),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                color: Color(0xFF1D2129),
              ),
            ),
            right,
          ],
        ),
      ),
    );
  }
}

class _RightValueArrow extends StatelessWidget {
  const _RightValueArrow({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            color: Color(0xFF86909C),
          ),
        ),
        const SizedBox(width: 8),
        const _ArrowIcon(),
      ],
    );
  }
}

class _ArrowOnly extends StatelessWidget {
  const _ArrowOnly();

  @override
  Widget build(BuildContext context) {
    return const _ArrowIcon();
  }
}

class _ArrowIcon extends StatelessWidget {
  const _ArrowIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icon/common/arrow-right.svg',
      width: 12,
      height: 12,
      colorFilter: const ColorFilter.mode(
        Colors.black26,
        BlendMode.srcIn,
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({
    required this.active,
    required this.onChanged,
  });

  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF34C759) : const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(15.5),
        ),
        padding: const EdgeInsets.all(2),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: active ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.15),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.1),
                  offset: const Offset(0, 0),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
