import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/pages/add_contacts_page.dart';
import 'package:zichat/pages/friend_info_page.dart';

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
    const Color bg = Color(0xFFF2F2F2);

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
                    padding: EdgeInsets.zero,
                    children: [
                      _buildSearchContainer(context),
                      _buildPhoneContacts(),
                      _buildFriendRequests(context),
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
      color: const Color(0xFFF2F2F2),
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
                '新的朋友',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D2129),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddContactsPage()),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '添加朋友',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF07C160),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContainer(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('搜索朋友功能暂未开放')),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icon/common/search.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Color(0x7F000000),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '微信号/手机号',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF9DA0A8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneContacts() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icon/discover/mobile-phone.svg',
            width: 32,
            height: 32,
          ),
          const SizedBox(height: 6),
          const Text(
            '手机联系人',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF1D1F23),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRequests(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          for (int i = 0; i < _mockRequests.length; i++)
            _FriendRequestItem(
              data: _mockRequests[i],
              isLast: i == _mockRequests.length - 1,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FriendInfoPage()),
                );
              },
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

class _FriendRequestItem extends StatelessWidget {
  const _FriendRequestItem({
    required this.data,
    required this.isLast,
    required this.onTap,
  });

  final _FriendRequest data;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: Color(0xFFF0F0F0),
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                data.avatar,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1F23),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8A8F99),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icon/common/arrow-right.svg',
                  width: 12,
                  height: 12,
                  colorFilter: const ColorFilter.mode(
                    Color(0x80000000),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  data.status,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6E727A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
