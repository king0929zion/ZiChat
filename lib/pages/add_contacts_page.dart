import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/pages/add_contacts_search_page.dart';
import 'package:zichat/pages/add_friend_page.dart';
import 'package:zichat/pages/code_scanner_page.dart';
import 'package:zichat/utils/cupertino_toast.dart';

class AddContactsPage extends StatelessWidget {
  const AddContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
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
        title: const Text('添加朋友', style: AppStyles.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              children: [
                _SearchEntrance(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddContactsSearchPage()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _MyWechatIdCard(
                  wechatId: 'zion_guoguoguo',
                  onCopy: () async {
                    await Clipboard.setData(const ClipboardData(text: 'zion_guoguoguo'));
                    if (context.mounted) {
                      CupertinoToast.show(context, '已复制微信号');
                    }
                  },
                  onQrCode: () {
                    CupertinoToast.show(context, '我的二维码页面暂未实现');
                  },
                ),
                const SizedBox(height: 12),
                _Section(
                  title: '添加方式',
                  children: [
                    _EntryTile(
                      icon: 'assets/icon/chats/scan-filled.svg',
                      iconBg: const Color(0xFF07C160),
                      title: '扫一扫',
                      subtitle: '扫描二维码名片',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CodeScannerPage()),
                        );
                      },
                    ),
                    _EntryTile(
                      icon: 'assets/icon/discover/mobile-phone.svg',
                      iconBg: const Color(0xFF3D7DFF),
                      title: '手机联系人',
                      subtitle: '添加或邀请通讯录中的朋友',
                      onTap: () {
                        CupertinoToast.show(context, '手机联系人功能暂未实现');
                      },
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'AI 好友',
                  children: [
                    _EntryTile(
                      icon: AppAssets.iconAddFriend,
                      iconBg: AppColors.primary,
                      title: '创建 AI 好友',
                      subtitle: '为好友设置头像与人设提示词',
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AddFriendPage()),
                        );
                        if (result != null && context.mounted) {
                          CupertinoToast.show(context, '已创建 AI 好友');
                        }
                      },
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '可通过微信号/手机号搜索、扫码添加，也可以创建项目内的 AI 好友。',
                    style: AppStyles.caption,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchEntrance extends StatelessWidget {
  const _SearchEntrance({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SvgPicture.asset(
                  AppAssets.iconSearch,
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textHint,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('微信号/手机号', style: AppStyles.hint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyWechatIdCard extends StatelessWidget {
  const _MyWechatIdCard({
    required this.wechatId,
    required this.onCopy,
    required this.onQrCode,
  });

  final String wechatId;
  final VoidCallback onCopy;
  final VoidCallback onQrCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('我的微信号', style: AppStyles.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      wechatId,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onCopy,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('复制'),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onQrCode,
                icon: SvgPicture.asset(
                  'assets/icon/qr-code.svg',
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(title, style: AppStyles.caption),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final String icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                icon,
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppStyles.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SvgPicture.asset(
              AppAssets.iconArrowRight,
              width: 12,
              height: 12,
              colorFilter: const ColorFilter.mode(
                AppColors.textHint,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
