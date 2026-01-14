import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/models/real_friend.dart';
import 'package:zichat/pages/friend_info_page.dart';
import 'package:zichat/services/avatar_utils.dart';
import 'package:zichat/storage/real_friend_storage.dart';
import 'package:zichat/utils/cupertino_toast.dart';

class AddContactsSearchPage extends StatefulWidget {
  const AddContactsSearchPage({super.key});

  @override
  State<AddContactsSearchPage> createState() => _AddContactsSearchPageState();
}

class _AddContactsSearchPageState extends State<AddContactsSearchPage> {
  final TextEditingController _controller = TextEditingController();

  // 模拟搜索结果（在实际应用中这些应该来自服务器）
  final List<_MockUser> _mockUsers = const [
    _MockUser(name: 'ZION.', wechatId: 'zion_mu', avatar: 'assets/bella.jpeg'),
    _MockUser(name: 'Bella', wechatId: 'bella_chen', avatar: 'assets/avatar.png'),
    _MockUser(name: '小紫', wechatId: 'xiaozi', avatar: 'assets/avatar-default.jpeg'),
  ];

  List<_SearchResult> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final val = _controller.text.trim();
    if (val.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    // 模拟搜索（实际应用中应该调用 API）
    Future.delayed(const Duration(milliseconds: 300), () {
      final lower = val.toLowerCase();
      final matches = _mockUsers
          .where((u) =>
              u.name.toLowerCase().contains(lower) ||
              u.wechatId.toLowerCase().contains(lower))
          .map((user) {
        final isFriend = RealFriendStorage.isFriend(user.wechatId);
        return _SearchResult(
          name: user.name,
          wechatId: user.wechatId,
          avatar: user.avatar,
          isFriend: isFriend,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _results = matches;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _addFriend(_SearchResult user) async {
    HapticFeedback.selectionClick();

    // 检查是否已经是好友
    if (user.isFriend) {
      // 跳转到好友资料页
      final friend = RealFriendStorage.findByWechatId(user.wechatId);
      if (friend != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FriendInfoPage(friendId: friend.id),
          ),
        );
      }
      return;
    }

    // 创建好友请求
    final request = RealFriend(
      id: 'request_${DateTime.now().millisecondsSinceEpoch}',
      name: user.name,
      avatar: user.avatar,
      wechatId: user.wechatId,
      signature: null,
      status: FriendRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    await RealFriendStorage.saveFriend(request);

    if (mounted) {
      CupertinoToast.show(context, '已发送好友验证申请');
    }
  }

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchInput(),
                  const SizedBox(height: 10),
                  const Text('可搜索：手机号、微信号', style: AppStyles.caption),
                  const SizedBox(height: 12),
                  Expanded(child: _buildResultList()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => HapticFeedback.selectionClick(),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '微信号/手机号',
                hintStyle: AppStyles.hint,
              ),
            ),
          ),
          if (_isSearching)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    final hasInput = _controller.text.trim().isNotEmpty;

    if (!hasInput) {
      return _buildEmptyState('输入手机号或微信号进行搜索');
    }

    if (_isSearching) {
      return _buildEmptyState('搜索中...');
    }

    if (_results.isEmpty) {
      return _buildEmptyState('未找到相关用户');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        itemCount: _results.length,
        separatorBuilder: (context, index) => const Divider(
          height: 0,
          color: AppColors.divider,
        ),
        itemBuilder: (context, index) {
          final user = _results[index];
          return _SearchResultItem(
            result: user,
            onAdd: () => _addFriend(user),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResult {
  const _SearchResult({
    required this.name,
    required this.wechatId,
    required this.avatar,
    required this.isFriend,
  });

  final String name;
  final String wechatId;
  final String avatar;
  final bool isFriend;
}

class _SearchResultItem extends StatelessWidget {
  const _SearchResultItem({
    required this.result,
    required this.onAdd,
  });

  final _SearchResult result;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          AvatarUtils.buildAvatarWidget(
            result.avatar,
            size: 44,
            borderRadius: 6,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '微信号：${result.wechatId}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: result.isFriend ? AppColors.surface : AppColors.primary,
              foregroundColor: result.isFriend ? AppColors.textSecondary : Colors.white,
              side: result.isFriend
                  ? const BorderSide(color: AppColors.divider)
                  : BorderSide.none,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              result.isFriend ? '发消息' : '添加',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockUser {
  const _MockUser({
    required this.name,
    required this.wechatId,
    required this.avatar,
  });

  final String name;
  final String wechatId;
  final String avatar;
}
