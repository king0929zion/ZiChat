import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/real_friend.dart';
import 'package:zichat/pages/add_contacts_page.dart';
import 'package:zichat/pages/friend_info_page.dart';
import 'package:zichat/services/avatar_utils.dart';
import 'package:zichat/storage/real_friend_storage.dart';
import 'package:zichat/utils/cupertino_toast.dart';

class NewFriendsPage extends StatefulWidget {
  const NewFriendsPage({super.key});

  @override
  State<NewFriendsPage> createState() => _NewFriendsPageState();
}

class _NewFriendsPageState extends State<NewFriendsPage> {
  List<RealFriend> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    setState(() {
      _pendingRequests = RealFriendStorage.getPendingRequests();
      _isLoading = false;
    });
  }

  void _onRequestTap(RealFriend request) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FriendInfoPage(friendId: request.id),
      ),
    ).then((_) => _loadRequests());
  }

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
              AppAssets.iconGoBack,
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
          CupertinoToast.show(context, '搜索朋友功能暂未开放');
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
                AppAssets.iconSearch,
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 合并真实请求和模拟请求
    final allRequests = [..._pendingRequests];

    if (allRequests.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: Text(
            '暂无新的好友请求',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8A8F99),
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          for (int i = 0; i < allRequests.length; i++)
            _FriendRequestItem(
              request: allRequests[i],
              isLast: i == allRequests.length - 1,
              onTap: () => _onRequestTap(allRequests[i]),
            ),
        ],
      ),
    );
  }
}

class _FriendRequestItem extends StatelessWidget {
  const _FriendRequestItem({
    required this.request,
    required this.isLast,
    required this.onTap,
  });

  final RealFriend request;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: isLast
            ? null
            : BoxDecoration(
                border: const Border(
                  bottom: BorderSide(
                    color: Color(0xFFF0F0F0),
                    width: 0.5,
                  ),
                ),
              ),
        child: Row(
          children: [
            AvatarUtils.buildAvatarWidget(
              request.avatar,
              size: 42,
              borderRadius: 6,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1F23),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '微信号：${request.wechatId}',
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
                  AppAssets.iconArrowRight,
                  width: 12,
                  height: 12,
                  colorFilter: const ColorFilter.mode(
                    Color(0x80000000),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _getStatusText(),
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

  String _getStatusText() {
    switch (request.status) {
      case FriendRequestStatus.pending:
        return '等待验证';
      case FriendRequestStatus.approved:
        return '已通过';
      case FriendRequestStatus.rejected:
        return '已拒绝';
    }
  }
}
