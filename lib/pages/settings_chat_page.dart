import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/widgets/weui/weui.dart';

class SettingsChatPage extends StatefulWidget {
  const SettingsChatPage({super.key});

  @override
  State<SettingsChatPage> createState() => _SettingsChatPageState();
}

class _SettingsChatPageState extends State<SettingsChatPage> {
  bool _useEarpiece = false;
  bool _independentSendButton = true;
  bool _imageSearch = false;
  bool _autoDownload = true;
  bool _keepOriginal = false;

  void _toast(String message) => WeuiToast.show(context, message: message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('聊天'),
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
                  children: [
                    WeuiCell(
                      title: '聊天背景',
                      onTap: () => _toast('功能开发中'),
                    ),
                  ],
                ),
                WeuiCellGroup(
                  children: [
                    WeuiCell(
                      title: '使用听筒播放语音消息',
                      showArrow: false,
                      trailing: WeuiSwitch(
                        value: _useEarpiece,
                        onChanged: (v) => setState(() => _useEarpiece = v),
                      ),
                    ),
                    WeuiCell(
                      title: '使用独立的发送按钮',
                      description: '开启后，键盘上的发送按钮会被替换成换行。',
                      showArrow: false,
                      trailing: WeuiSwitch(
                        value: _independentSendButton,
                        onChanged: (v) =>
                            setState(() => _independentSendButton = v),
                      ),
                    ),
                    WeuiCell(
                      title: '聊天图片搜索',
                      description: '开启后，可以通过图片信息搜索聊天中的图片。',
                      showArrow: false,
                      trailing: WeuiSwitch(
                        value: _imageSearch,
                        onChanged: (v) => setState(() => _imageSearch = v),
                      ),
                    ),
                  ],
                ),
                WeuiCellGroup(
                  children: [
                    WeuiCell(
                      title: '自动下载在其他设备查看的内容',
                      description: '内容包括「图片、视频和文件」',
                      showArrow: false,
                      trailing: WeuiSwitch(
                        value: _autoDownload,
                        onChanged: (v) => setState(() => _autoDownload = v),
                      ),
                    ),
                    WeuiCell(
                      title: '保留查看过的原图、原视频',
                      description:
                          '开启后，保留「已发送」和「已接收并查看」的原图原视频在 WeChat。开启前的原图原视频不受影响。',
                      showArrow: false,
                      trailing: WeuiSwitch(
                        value: _keepOriginal,
                        onChanged: (v) => setState(() => _keepOriginal = v),
                      ),
                    ),
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

