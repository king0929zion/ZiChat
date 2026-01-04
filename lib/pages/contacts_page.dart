import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/friend.dart';
import 'package:zichat/models/real_friend.dart';
import 'package:zichat/pages/add_friend_page.dart';
import 'package:zichat/pages/friend_info_page.dart';
import 'package:zichat/pages/new_friends_page.dart';
import 'package:zichat/services/avatar_utils.dart';
import 'package:zichat/services/user_data_manager.dart';
import 'package:zichat/storage/friend_storage.dart';
import 'package:zichat/storage/real_friend_storage.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Friend> _customFriends = [];
  List<RealFriend> _realFriends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
    UserDataManager.instance.addListener(_onUserDataChanged);
  }

  @override
  void dispose() {
    UserDataManager.instance.removeListener(_onUserDataChanged);
    super.dispose();
  }

  void _onUserDataChanged() {
    if (mounted) {
      _loadFriends();
    }
  }

  void _loadFriends() {
    setState(() {
      _customFriends = FriendStorage.getAllFriends();
      _realFriends = RealFriendStorage.getApprovedFriends();
    });
  }

  void _onRealFriendTap(RealFriend friend) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FriendInfoPage(friendId: friend.id),
      ),
    ).then((_) => _loadFriends());
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFEDEDED);
    const Color line = Color(0xFFE5E6EB);
    const Color textSub = Color(0xFF86909C);

    final totalAiFriends = _customFriends.length;
    final totalRealFriends = _realFriends.length;
    final totalFriends = totalAiFriends + totalRealFriends;

    return SizedBox.expand(
      child: Container(
        color: bg,
        child: ListView(
        children: [
          // 顶部卡片入口
          Container(
            margin: EdgeInsets.zero,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: line, width: 0.5),
                bottom: BorderSide(color: line, width: 0.5),
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _cards.length; i++) ...[
                  _ContactEntry(
                    imageAsset: _cards[i].image,
                    label: _cards[i].text,
                    onTap: i == 0
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const NewFriendsPage()),
                            );
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('打开 ${_cards[i].text}')),
                            );
                          },
                  ),
                  if (i != _cards.length - 1)
                    const Divider(height: 0, indent: 68, color: line),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 真实好友
          if (_realFriends.isNotEmpty) ...[
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ContactsSectionHeader(label: '朋友'),
                  for (int i = 0; i < _realFriends.length; i++)
                    _RealFriendItem(
                      friend: _realFriends[i],
                      showDivider: i != _realFriends.length - 1,
                      onTap: () => _onRealFriendTap(_realFriends[i]),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 我创建的 AI 好友
          if (_customFriends.isNotEmpty) ...[
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ContactsSectionHeader(label: 'AI 好友'),
                  for (int i = 0; i < _customFriends.length; i++)
                    _CustomFriendItem(
                      friend: _customFriends[i],
                      showDivider: i != _customFriends.length - 1,
                      onEdit: () async {
                        final result = await Navigator.of(context).push<Friend>(
                          MaterialPageRoute(
                            builder: (_) => AddFriendPage(editFriend: _customFriends[i]),
                          ),
                        );
                        if (result != null) {
                          _loadFriends();
                        }
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('删除好友'),
                            content: Text('确定要删除"${_customFriends[i].name}"吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('删除', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FriendStorage.deleteFriend(_customFriends[i].id);
                          _loadFriends();
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                '$totalFriends 位联系人',
                style: const TextStyle(
                  fontSize: 14,
                  color: textSub,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// 真实好友列表项
class _RealFriendItem extends StatelessWidget {
  const _RealFriendItem({
    required this.friend,
    required this.showDivider,
    required this.onTap,
  });

  final RealFriend friend;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 16),
            AvatarUtils.buildAvatarWidget(
              friend.avatar.isEmpty ? AvatarUtils.defaultFriendAvatar : friend.avatar,
              size: 42,
              borderRadius: 4,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                alignment: Alignment.centerLeft,
                decoration: showDivider
                    ? const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE5E6EB),
                            width: 0.5,
                          ),
                        ),
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF1D2129),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (friend.signature != null && friend.signature!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        friend.signature!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF86909C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 自定义好友列表项
class _CustomFriendItem extends StatelessWidget {
  const _CustomFriendItem({
    required this.friend,
    required this.showDivider,
    required this.onEdit,
    required this.onDelete,
  });

  final Friend friend;
  final bool showDivider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('编辑好友'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onEdit();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('删除好友', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 16),
            AvatarUtils.buildAvatarWidget(
              friend.avatar.isEmpty ? AvatarUtils.defaultFriendAvatar : friend.avatar,
              size: 42,
              borderRadius: 4,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                alignment: Alignment.centerLeft,
                decoration: showDivider
                    ? const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE5E6EB),
                            width: 0.5,
                          ),
                        ),
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF1D2129),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (friend.prompt.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        friend.prompt,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF86909C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactEntry extends StatelessWidget {
  const _ContactEntry({
    required this.imageAsset,
    required this.label,
    this.onTap,
  });

  final String imageAsset;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                imageAsset,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  color: Color(0xFF1D2129),
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/icon/common/arrow-right.svg',
              width: 12,
              height: 12,
              colorFilter: const ColorFilter.mode(
                Colors.black26,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactsSectionHeader extends StatelessWidget {
  const _ContactsSectionHeader({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      color: const Color(0xFFEDEDED),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF86909C),
        ),
      ),
    );
  }
}

class _CardEntry {
  const _CardEntry({required this.text, required this.image});
  final String text;
  final String image;
}

const List<_CardEntry> _cards = [
  _CardEntry(text: '新的朋友', image: 'assets/icon/contacts/new-friend.jpeg'),
  _CardEntry(
      text: '仅聊天的朋友', image: 'assets/icon/contacts/chats-only-friends.jpeg'),
  _CardEntry(text: '群聊', image: 'assets/icon/contacts/group-chat.jpeg'),
  _CardEntry(text: '标签', image: 'assets/icon/contacts/tags.jpeg'),
  _CardEntry(text: '公众号', image: 'assets/icon/contacts/official-account.jpeg'),
  _CardEntry(
      text: '企业微信联系人', image: 'assets/icon/contacts/wecom-contacts.jpeg'),
];
