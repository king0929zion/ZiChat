import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';

class SettingsChatPage extends StatefulWidget {
  const SettingsChatPage({super.key});

  @override
  State<SettingsChatPage> createState() => _SettingsChatPageState();
}

class _SettingsChatPageState extends State<SettingsChatPage> {
  // Mock states
  bool _useEarpiece = false;
  bool _independentSendButton = true;
  bool _imageSearch = false;
  bool _autoDownload = true;
  bool _keepOriginal = false;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
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
        title: const Text('聊天'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 12),
            _SettingsItem(
              label: '聊天背景',
              onTap: () => _showSnack('功能开发中'),
            ),
             const SizedBox(height: 12),
            _SwitchItem(
              label: '使用听筒播放语音消息',
              value: _useEarpiece,
              onChanged: (v) => setState(() => _useEarpiece = v),
            ),
            const _Divider(),
            _SwitchItem(
              label: '使用独立的发送按钮',
              subtitle: '开启后，键盘上的发送按钮会被替换成换行。',
              value: _independentSendButton,
              onChanged: (v) => setState(() => _independentSendButton = v),
            ),
            const _Divider(),
            _SwitchItem(
              label: '聊天图片搜索',
              subtitle: '开启后，可以通过图片信息搜索聊天中的图片。',
              value: _imageSearch,
              onChanged: (v) => setState(() => _imageSearch = v),
            ),
            const SizedBox(height: 12),
             _SwitchItem(
              label: '自动下载在其他设备查看的内容',
              subtitle: '内容包括「图片、视频和文件」',
              value: _autoDownload,
              onChanged: (v) => setState(() => _autoDownload = v),
            ),
            const _Divider(),
             _SwitchItem(
              label: '保留查看过的原图、原视频',
              subtitle: '开启后，保留「已发送」和「已接收并查看」的原图原视频在WeChat。开启前的原图原视频不受影响。',
              value: _keepOriginal,
              onChanged: (v) => setState(() => _keepOriginal = v),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                label,
                style: const TextStyle(fontSize: 17, color: AppColors.textPrimary),
              ),
              SvgPicture.asset(
              AppAssets.iconArrowRight,
               width: 12,
               height: 12,
               colorFilter:
                   const ColorFilter.mode(Colors.black26, BlendMode.srcIn),
              ),
            ],
          ),
        ),
    );
  }
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minHeight: 56),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          _ToggleSwitch(active: value, onChanged: onChanged),
        ],
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
        duration: AppStyles.animationNormal,
        curve: AppStyles.curveDefault,
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(15.5),
        ),
        padding: const EdgeInsets.all(2),
        child: AnimatedAlign(
          duration: AppStyles.animationNormal,
          curve: AppStyles.curveDefault,
          alignment: active ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.08),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(left: 16),
      child: const Divider(height: 1, color: AppColors.divider),
    );
  }
}
