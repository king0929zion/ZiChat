import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/friend.dart';
import 'package:zichat/pages/add_friend_page.dart';
import 'package:zichat/pages/new_friends_page.dart';
import 'package:zichat/storage/friend_storage.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Friend> _customFriends = [];
  
  @override
  void initState() {
    super.initState();
    _loadCustomFriends();
  }
  
  void _loadCustomFriends() {
    setState(() {
      _customFriends = FriendStorage.getAllFriends();
    });
  }
  
  Future<void> _openAddFriendPage() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.of(context).push<Friend>(
      MaterialPageRoute(builder: (_) => const AddFriendPage()),
    );
    if (result != null) {
      _loadCustomFriends();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFEDEDED);
    const Color line = Color(0xFFE5E6EB);
    const Color textSub = Color(0xFF86909C);
    
    final totalFriends = _friends.length + _customFriends.length;

    return Container(
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
                          _loadCustomFriends();
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
                          _loadCustomFriends();
                        }
                      },
                    ),
                  // 添加更多好友按钮
                  _AddFriendButton(onTap: _openAddFriendPage),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // 分组联系人
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // 如果没有自定义好友，显示添加按钮
                if (_customFriends.isEmpty) ...[
                  _AddFriendButton(onTap: _openAddFriendPage),
                  const Divider(height: 0, indent: 68, color: line),
                ],
                for (final section in _groupedFriends)
                  ...[
                    _ContactsSectionHeader(label: section.initial),
                    for (int i = 0; i < section.items.length; i++)
                      _ContactsListItem(
                        name: section.items[i].displayName,
                        avatar: section.items[i].avatar,
                        showDivider: i != section.items.length - 1,
                      ),
                  ]
              ],
            ),
          ),
          const SizedBox(height: 8),
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
    );
  }
}

/// 添加好友按钮
class _AddFriendButton extends StatelessWidget {
  const _AddFriendButton({required this.onTap});
  
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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.person_add_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '添加 AI 好友',
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF07C160),
                  fontWeight: FontWeight.w500,
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
            const SizedBox(width: 16),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: friend.avatar.startsWith('assets/')
                  ? Image.asset(
                      friend.avatar,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 42,
                      height: 42,
                      color: AppColors.background,
                      child: const Icon(Icons.person, size: 24),
                    ),
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

class _ContactsListItem extends StatelessWidget {
  const _ContactsListItem({
    required this.name,
    required this.avatar,
    this.showDivider = true,
  });

  final String name;
  final String avatar;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                avatar,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
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
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF1D2129),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
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

class _Friend {
  const _Friend({
    required this.displayName,
    required this.avatar,
    required this.initial,
  });
  final String displayName;
  final String avatar;
  final String initial;
}

class _FriendSection {
  const _FriendSection({required this.initial, required this.items});
  final String initial;
  final List<_Friend> items;
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

const List<_Friend> _friends = [
  _Friend(displayName: '安奕', avatar: 'assets/avatar.png', initial: 'A'),
  _Friend(displayName: '白茶', avatar: 'assets/avatar-default.jpeg', initial: 'B'),
  _Friend(displayName: '陈川', avatar: 'assets/bella.jpeg', initial: 'C'),
  _Friend(displayName: '丁可', avatar: 'assets/me.png', initial: 'D'),
  _Friend(displayName: '付博', avatar: 'assets/avatar.png', initial: 'F'),
  _Friend(displayName: '顾深', avatar: 'assets/avatar-default.jpeg', initial: 'G'),
  _Friend(displayName: '韩叙', avatar: 'assets/avatar.png', initial: 'H'),
  _Friend(displayName: '金悦', avatar: 'assets/avatar-default.jpeg', initial: 'J'),
  _Friend(displayName: '刘洛', avatar: 'assets/bella.jpeg', initial: 'L'),
  _Friend(displayName: '陆一鸣', avatar: 'assets/avatar.png', initial: 'L'),
  _Friend(displayName: '莫灵', avatar: 'assets/avatar.png', initial: 'M'),
  _Friend(displayName: '乔木', avatar: 'assets/avatar-default.jpeg', initial: 'Q'),
  _Friend(displayName: '孙晓', avatar: 'assets/bella.jpeg', initial: 'S'),
  _Friend(displayName: '唐跃', avatar: 'assets/avatar.png', initial: 'T'),
  _Friend(displayName: '王析', avatar: 'assets/avatar-default.jpeg', initial: 'W'),
  _Friend(displayName: '许诺', avatar: 'assets/avatar.png', initial: 'X'),
  _Friend(displayName: '袁野', avatar: 'assets/avatar-default.jpeg', initial: 'Y'),
  _Friend(displayName: '张源', avatar: 'assets/avatar.png', initial: 'Z'),
  _Friend(displayName: '赵城', avatar: 'assets/avatar-default.jpeg', initial: 'Z'),
];

List<_FriendSection> get _groupedFriends {
  final Map<String, List<_Friend>> map = {};
  for (final f in _friends) {
    map.putIfAbsent(f.initial, () => []).add(f);
  }
  final initials = map.keys.toList()..sort();
  return initials
      .map((i) => _FriendSection(initial: i, items: map[i]!))
      .toList();
}
