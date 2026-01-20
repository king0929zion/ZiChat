import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/pages/settings_page.dart';
import 'package:zichat/pages/services_page.dart';
import 'package:zichat/pages/my_qrcode_page.dart';
import 'package:zichat/pages/me/my_profile_page.dart';
import 'package:zichat/services/user_data_manager.dart';
import 'package:zichat/services/avatar_utils.dart';
import 'package:zichat/storage/friend_storage.dart';
import 'package:zichat/storage/user_profile_storage.dart';
import 'package:zichat/widgets/weui/weui.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> with WidgetsBindingObserver {
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    WidgetsBinding.instance.addObserver(this);
    // 监听用户数据变化
    UserDataManager.instance.addListener(_onUserDataChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    UserDataManager.instance.removeListener(_onUserDataChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 应用恢复时刷新数据
    if (state == AppLifecycleState.resumed) {
      _loadProfile();
    }
  }

  void _onUserDataChanged() {
    if (mounted) {
      _loadProfile();
    }
  }

  void _loadProfile() {
    setState(() {
      _profile = UserDataManager.instance.profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          _buildProfileCard(context),
          const SizedBox(height: 12),
          _buildSection(context, [
            _MeItem(
              icon: 'assets/icon/me/pay-success-outline.svg',
              label: '支付与服务',
              iconColor: AppColors.primary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ServicesPage()),
                );
              },
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection(context, [
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
              iconColor: AppColors.primary,
            ),
            const _MeItem(
              icon: 'assets/icon/keyboard-panel/emoji-icon.svg',
              label: '表情',
              iconColor: Color(0xFFEEAA4D),
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection(context, [
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
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MyProfilePage()),
          );
          _loadProfile();
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 16, 32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarUtils.buildAvatarWidget(
                _profile.avatar,
                size: 64,
                borderRadius: 8,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profile.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
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
                              color: AppColors.textSecondary,
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
                                AppAssets.iconQrCode,
                                width: 16,
                                height: 16,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.textSecondary,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SvgPicture.asset(
                                AppAssets.iconArrowRight,
                                width: 10,
                                height: 16,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.textHint,
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
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              const Text(
                                '状态',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
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
                              border: Border.all(color: AppColors.border, width: 0.5),
                            ),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                                _avatarStack(),
                                const SizedBox(width: 4),
                                const Text(
                                  '还有 9 位朋友',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.unreadBadge,
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
      ),
    );
  }

  Widget _avatarStack() {
    return FutureBuilder<List<String>>(
      future: _getFriendAvatars(),
      builder: (context, snapshot) {
        final avatars = snapshot.data ?? [];
        return SizedBox(
          height: 16,
          width: 32,
          child: Stack(
            children: [
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * 10.0,
                  child: _MiniAvatar(avatars.length > i ? avatars[i] : ''),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<String>> _getFriendAvatars() async {
    final friends = FriendStorage.getAllFriends();
    return friends.take(3).map((f) => f.avatar).toList();
  }

  Widget _buildSection(BuildContext context, List<_MeItem> items) {
    void showTodo() => WeuiToast.show(context, message: '功能开发中');

    return WeuiCellGroup(
      children: [
        for (final item in items)
          WeuiCell(
            title: item.label,
            leading: SvgPicture.asset(
              item.icon,
              width: 20,
              height: 20,
              colorFilter: item.iconColor != null
                  ? ColorFilter.mode(item.iconColor!, BlendMode.srcIn)
                  : null,
            ),
            onTap: item.onTap ?? showTodo,
          ),
      ],
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar(this.asset);
  final String asset;
  @override
  Widget build(BuildContext context) {
    if (asset.isEmpty) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.disabledBg,
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Icon(Icons.person, size: 10, color: AppColors.textHint),
      );
    }
    return AvatarUtils.buildAvatarWidget(
      asset,
      size: 16,
      borderRadius: 3,
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
