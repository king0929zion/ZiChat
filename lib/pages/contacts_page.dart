import 'package:flutter/material.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/friend.dart';
import 'package:zichat/pages/add_friend_page.dart';
import 'package:zichat/pages/friend_detail_page.dart';
import 'package:zichat/pages/new_friends_page.dart';
import 'package:zichat/services/avatar_utils.dart';
import 'package:zichat/storage/friend_storage.dart';
import 'package:zichat/widgets/weui/weui.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  void _showTodo(String label) {
    WeuiToast.show(context, message: '打开 $label');
  }

  Future<void> _editFriend(Friend friend) async {
    await Navigator.of(context).push<Friend>(
      MaterialPageRoute(builder: (_) => AddFriendPage(editFriend: friend)),
    );
  }

  Future<void> _deleteFriend(Friend friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除好友'),
        content: Text('确定要删除"${friend.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FriendStorage.deleteFriend(friend.id);
    }
  }

  void _showFriendActions(Friend friend) {
    showWeuiActionSheet(
      context: context,
      actions: [
        WeuiActionSheetAction(
          label: '编辑好友',
          onTap: () {
            _editFriend(friend);
          },
        ),
        WeuiActionSheetAction(
          label: '删除好友',
          tone: WeuiActionSheetTone.destructive,
          onTap: () {
            _deleteFriend(friend);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: FriendStorage.listenable(),
      builder: (context, _, __) {
        final customFriends = FriendStorage.getAllFriends();
        final totalFriends = customFriends.length;

        return Container(
          color: AppColors.backgroundChat,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              WeuiCellGroup(
                margin: EdgeInsets.zero,
                children: [
                  for (int i = 0; i < _cards.length; i++)
                    WeuiCell(
                      title: _cards[i].text,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          _cards[i].image,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      onTap: () {
                        if (i == 0) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NewFriendsPage(),
                            ),
                          );
                          return;
                        }
                        _showTodo(_cards[i].text);
                      },
                    ),
                ],
              ),

              // 我创建的 AI 好友
              if (customFriends.isNotEmpty) ...[
                WeuiCellGroup(
                  title: 'AI 好友',
                  margin: const EdgeInsets.only(top: 12),
                  children: [
                    for (final friend in customFriends)
                      WeuiCell(
                        title: friend.name,
                        description:
                            friend.prompt.isNotEmpty ? friend.prompt : null,
                        leading: AvatarUtils.buildAvatarWidget(
                          friend.avatar.isEmpty
                              ? AvatarUtils.defaultFriendAvatar
                              : friend.avatar,
                          size: 42,
                          borderRadius: 4,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FriendDetailPage(friendId: friend.id),
                            ),
                          );
                        },
                        onLongPress: () => _showFriendActions(friend),
                      ),
                  ],
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    '$totalFriends 位联系人',
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
