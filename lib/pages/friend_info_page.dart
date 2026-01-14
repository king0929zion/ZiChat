import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/models/real_friend.dart';
import 'package:zichat/pages/chat_detail/chat_detail_page.dart';
import 'package:zichat/services/avatar_utils.dart';
import 'package:zichat/storage/real_friend_storage.dart';
import 'package:zichat/utils/cupertino_toast.dart';

class FriendInfoPage extends StatefulWidget {
  const FriendInfoPage({
    super.key,
    this.friendId,
  });

  final String? friendId;

  @override
  State<FriendInfoPage> createState() => _FriendInfoPageState();
}

class _FriendInfoPageState extends State<FriendInfoPage> {
  RealFriend? _friend;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriend();
  }

  void _loadFriend() {
    if (widget.friendId != null) {
      setState(() {
        _friend = RealFriendStorage.getFriend(widget.friendId!);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRequest() async {
    HapticFeedback.mediumImpact();

    if (_friend == null) return;

    await RealFriendStorage.approveRequest(_friend!.id);
    _loadFriend();

    if (mounted) {
      CupertinoToast.show(context, '已通过验证');
    }
  }

  Future<void> _rejectRequest() async {
    HapticFeedback.mediumImpact();

    if (_friend == null) return;

    await RealFriendStorage.rejectRequest(_friend!.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _startChat() {
    if (_friend == null) return;

    // 跳转到聊天页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(
          chatId: 'real_${_friend!.id}',
          title: _friend!.name,
          unread: _friend!.unread,
          avatar: _friend!.avatar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_friend == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('好友资料')),
        body: const Center(child: Text('好友不存在')),
      );
    }

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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildProfileCard(_friend!),
                        const SizedBox(height: 12),
                        _buildActionCard(context, _friend!),
                      ],
                    ),
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
                '好友资料',
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

  Widget _buildProfileCard(RealFriend friend) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AvatarUtils.buildAvatarWidget(
            friend.avatar,
            size: 64,
            borderRadius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NameRow(name: friend.name, status: friend.status),
                const SizedBox(height: 4),
                Text(
                  '微信号：${friend.wechatId}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8A8F99),
                  ),
                ),
                if (friend.signature != null && friend.signature!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '个性签名：${friend.signature}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1D1F23),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, RealFriend friend) {
    final isPending = friend.status == FriendRequestStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          if (isPending) ...[
            SizedBox(
              height: 46,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _approveRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF07C160),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '通过验证',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _rejectRequest,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF4D4F)),
                  foregroundColor: const Color(0xFFFF4D4F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '拒绝',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 46,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF07C160),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '发消息',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  CupertinoToast.show(context, '备注功能暂未开放');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDCDCDC)),
                  foregroundColor: const Color(0xFF1D1F23),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '设置备注和标签',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({
    required this.name,
    required this.status,
  });

  final String name;
  final FriendRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D1F23),
          ),
        ),
        const SizedBox(width: 8),
        if (status == FriendRequestStatus.pending)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x26FF9B57),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '等待验证',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFFF9B57),
              ),
            ),
          ),
      ],
    );
  }
}
