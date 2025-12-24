import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/pages/settings_page.dart';
import 'package:zichat/pages/services_page.dart';
import 'package:zichat/pages/my_qrcode_page.dart';
import 'package:zichat/pages/me/my_profile_page.dart';
import 'package:zichat/storage/user_profile_storage.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = UserProfileStorage.getProfile();
  }

  void _loadProfile() {
    setState(() {
      _profile = UserProfileStorage.getProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFEFF4),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          _buildProfileCard(context),
          const SizedBox(height: 12),
          _buildSection([
            _MeItem(
              icon: 'assets/icon/me/pay-success-outline.svg',
              label: '支付与服务',
              iconColor: const Color(0xFF07C160),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ServicesPage()),
                );
              },
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection([
            const _MeItem(
              icon: 'assets/icon/me/favorites.svg',
              label: '收藏',
              iconColor: Color(0xFF5B8FD7),
            ),
            const _MeItem(
              icon: 'assets/icon/me/album-outline.svg',
              label: '朋友圈',
              iconColor: Color(0xFFEEAA4D),
            ),
            const _MeItem(
              icon: 'assets/icon/me/cards-offers.svg',
              label: '卡包',
              iconColor: Color(0xFF07C160),
            ),
            const _MeItem(
              icon: 'assets/icon/keyboard-panel/emoji-icon.svg',
              label: '表情',
              iconColor: Color(0xFFEEAA4D),
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection([
            _MeItem(
              icon: 'assets/icon/common/setting-outline.svg',
              label: '设置',
              iconColor: const Color(0xFF5B8FD7),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    ImageProvider avatarProvider;
    if (_profile.avatar.startsWith('assets/')) {
      avatarProvider = AssetImage(_profile.avatar);
    } else {
      avatarProvider = FileImage(File(_profile.avatar));
    }

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyProfilePage()),
        );
        _loadProfile();
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 60, 16, 32), // More spacing for status bar
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image(
                image: avatarProvider,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset('assets/me.png', width: 64, height: 64),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '微信号：${_profile.wechatId}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7F7F7F),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyQrcodePage(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/icon/qr-code.svg',
                              width: 16,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF7F7F7F),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SvgPicture.asset(
                              'assets/icon/common/arrow-right.svg',
                              width: 10,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                Color(0x73000000),
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 14, color: Color(0xFF7F7F7F)),
                            const SizedBox(width: 4),
                            const Text(
                              '状态',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF555555),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status bubble with friends
                      Container(
                         padding: const EdgeInsets.fromLTRB(4, 2, 8, 2),
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(14),
                           border: Border.all(color: const Color(0xFFE5E5E5)),
                         ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             _avatarStack(),
                             const SizedBox(width: 4),
                             const Text(
                               '还有 9 位朋友',
                               style: TextStyle(fontSize: 12, color: Color(0xFF7F7F7F)),
                             ),
                             const SizedBox(width: 4),
                             Container(
                               width: 6,
                               height: 6,
                               decoration: BoxDecoration(
                                 color: const Color(0xFFF54A45),
                                 shape: BoxShape.circle,
                               ),
                             ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarStack() {
    return SizedBox(
      height: 16,
      width: 32,
      child: Stack(
        children: const [
          Positioned(left: 0, child: _MiniAvatar('assets/bella.jpeg')),
          Positioned(left: 10, child: _MiniAvatar('assets/me.png')),
          Positioned(left: 20, child: _MiniAvatar('assets/avatar.png')),
        ],
      ),
    );
  }

  Widget _buildSection(List<_MeItem> items) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            _MeListTile(
              item: items[i],
              isLast: i == items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar(this.asset);
  final String asset;
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        asset,
        width: 16,
        height: 16,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _MeItem {
  const _MeItem({
    required this.icon,
    required this.label,
    this.iconColor,
    this.onTap,
  });

  final String icon;
  final String label;
  final Color? iconColor;
  final VoidCallback? onTap;
}

class _MeListTile extends StatelessWidget {
  const _MeListTile({
    required this.item,
    this.isLast = false,
  });

  final _MeItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Container(
        height: 54, // HTML: height: 54px
        padding: const EdgeInsets.only(left: 16, right: 12), // HTML: padding: 0 12px 0 16px
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: Color(0xFFEDEDED), // HTML: border-bottom: 0.5px solid #ededed
                    width: 0.5,
                  ),
                ), // HTML: .list-item:last-child { border-bottom: none; }
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              item.icon,
              width: 20, // HTML: width: 20px
              height: 20, // HTML: height: 20px
              colorFilter: item.iconColor != null
                  ? ColorFilter.mode(item.iconColor!, BlendMode.srcIn)
                  : null,
            ),
            const SizedBox(width: 14), // HTML: margin-right: 14px
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 16, // HTML: font-size: 16px
                  color: Color(0xFF111111), // HTML: color: #111
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/icon/common/arrow-right.svg',
              width: 8,
              height: 14,
              colorFilter: const ColorFilter.mode(
                Color(0x59000000), // HTML: opacity: 0.35
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
