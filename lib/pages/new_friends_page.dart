import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/pages/add_contacts_page.dart';
import 'package:zichat/pages/friend_info_page.dart';
import 'package:zichat/widgets/weui/weui.dart';

class NewFriendsPage extends StatelessWidget {
  const NewFriendsPage({super.key});

  static const List<_FriendRequest> _mockRequests = [
    _FriendRequest(
      id: 'req1',
      name: 'ZION.',
      avatar: 'assets/bella.jpeg',
      message: 'Hi，我想加你为好友',
      status: '等待验证',
    ),
    _FriendRequest(
      id: 'req2',
      name: 'Bella',
      avatar: 'assets/avatar.png',
      message: '你好，我想加你为朋友',
      status: '已通过',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    void showTodo(String message) => WeuiToast.show(context, message: message);

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
        title: const Text('新的朋友'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddContactsPage()),
              );
            },
            child: const Text(
              '添加朋友',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        children: [
          WeuiCellGroup(
            children: [
              WeuiCell(
                title: '微信号/手机号',
                leading: SvgPicture.asset(
                  AppAssets.iconSearch,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textHint,
                    BlendMode.srcIn,
                  ),
                ),
                showArrow: false,
                onTap: () => showTodo('搜索朋友功能暂未开放'),
              ),
              WeuiCell(
                title: '手机联系人',
                leading: SvgPicture.asset(
                  'assets/icon/discover/mobile-phone.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textHint,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () => showTodo('手机联系人功能暂未实现'),
              ),
            ],
          ),
          WeuiCellGroup(
            children: [
              for (final request in _mockRequests)
                WeuiCell(
                  title: request.name,
                  description: request.message,
                  value: request.status,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      request.avatar,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FriendInfoPage()),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendRequest {
  const _FriendRequest({
    required this.id,
    required this.name,
    required this.avatar,
    required this.message,
    required this.status,
  });

  final String id;
  final String name;
  final String avatar;
  final String message;
  final String status;
}

