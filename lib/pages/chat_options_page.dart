import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/pages/ai_contact_prompt_page.dart';
import 'package:zichat/pages/ai_soul_panel_page.dart';
import 'package:zichat/pages/chat_background_page.dart';
import 'package:zichat/pages/chat_search_page.dart';
import 'package:zichat/services/ai_chat_service.dart';
import 'package:zichat/services/avatar_utils.dart';
import 'package:zichat/storage/friend_storage.dart';
import 'package:zichat/storage/chat_storage.dart';

class ChatOptionsPage extends StatelessWidget {
  const ChatOptionsPage({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      body: SafeArea(
        top: true,
        bottom: true,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            color: const Color(0xFFEDEDED),
            child: Column(
              children: [
                const _ChatOptionsHeader(),
                Expanded(child: _ChatOptionsBody(chatId: chatId)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchChatItem extends StatelessWidget {
  const _SearchChatItem({required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatSearchPage(
                chatId: chatId,
                chatName: '聊天记录',
              ),
            ),
          );
        },
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '查找聊天记录',
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF000000),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icon/common/arrow-right.svg',
                  width: 14,
                  height: 14,
                  colorFilter: const ColorFilter.mode(
                    Colors.black26,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiPromptItem extends StatelessWidget {
  const _AiPromptItem({required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AiContactPromptPage(
                chatId: chatId,
                title: '当前聊天',
              ),
            ),
          );
        },
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AI 提示词',
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF000000),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icon/common/arrow-right.svg',
                  width: 14,
                  height: 14,
                  colorFilter: const ColorFilter.mode(
                    Colors.black26,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundItem extends StatelessWidget {
  const _BackgroundItem({required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatBackgroundPage(chatId: chatId),
            ),
          );
        },
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '设置当前聊天背景',
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFF000000),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icon/common/arrow-right.svg',
                  width: 14,
                  height: 14,
                  colorFilter: const ColorFilter.mode(
                    Colors.black26,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearChatItem extends StatelessWidget {
  const _ClearChatItem({required this.chatId});

  final String chatId;

  Future<void> _handleClear(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('清空聊天记录'),
          content: const Text('确定要清空当前聊天的所有消息吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await ChatStorage.saveMessages(chatId, <Map<String, dynamic>>[]);
    AiChatService.clearHistory(chatId);
    // 通知上层页面已清空，并返回聊天详情页
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () => _handleClear(context),
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '清空聊天记录',
                  style: TextStyle(
                    fontSize: 17,
                    color: Color(0xFFFA5151),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icon/common/arrow-right.svg',
                  width: 14,
                  height: 14,
                  colorFilter: const ColorFilter.mode(
                    Colors.black26,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatOptionsHeader extends StatelessWidget {
  const _ChatOptionsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: const Color(0xFFEDEDED),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              icon: SvgPicture.asset(
                'assets/icon/common/go-back.svg',
                width: 12,
                height: 20,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '聊天信息',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D2129),
                ),
              ),
            ),
          ),
          const SizedBox(width: 36, height: 36),
        ],
      ),
    );
  }
}

class _ChatOptionsBody extends StatelessWidget {
  const _ChatOptionsBody({required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        _MembersSection(chatId: chatId),
        const SizedBox(height: 12),
        _SearchChatItem(chatId: chatId),
        const SizedBox(height: 12),
        _AiPromptItem(chatId: chatId),
        const SizedBox(height: 12),
        const _SwitchCard(),
        const SizedBox(height: 12),
        _BackgroundItem(chatId: chatId),
        const SizedBox(height: 12),
        _ClearChatItem(chatId: chatId),
        const SizedBox(height: 12),
        const _InfoListCard(items: [
          _InfoListItemData(title: '投诉'),
        ]),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: FriendStorage.listenable(),
      builder: (context, _, __) {
        final friend = FriendStorage.getFriend(chatId);
        final avatar = friend?.avatar ?? AvatarUtils.defaultFriendAvatar;
        final name = friend?.name ?? '聊天对象';

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI 头像 - 点击打开控制面板
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AiSoulPanelPage(chatId: chatId),
                    ),
                  );
                },
                child: Column(
                  children: [
                    AvatarUtils.buildAvatarWidget(
                      avatar,
                      size: 64,
                      borderRadius: AppStyles.radiusMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 64,
                height: 64,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: Color(0xFFD1D1D6), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: () {},
                  child: SvgPicture.asset(
                    'assets/icon/common/plus.svg',
                    width: 32,
                    height: 32,
                    colorFilter: const ColorFilter.mode(
                      Color(0x66000000),
                      BlendMode.srcIn,
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

class _InfoListItemData {
  const _InfoListItemData({
    required this.title,
  });

  final String title;
}

class _InfoListCard extends StatelessWidget {
  const _InfoListCard({
    required this.items,
  });

  final List<_InfoListItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            Column(
              children: [
                _InfoListItem(title: items[i].title),
                if (i != items.length - 1)
                  const Divider(
                    height: 0,
                    indent: 16,
                    color: Color(0x14000000),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InfoListItem extends StatelessWidget {
  const _InfoListItem({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  color: Color(0xFF000000),
                ),
              ),
              SvgPicture.asset(
                'assets/icon/common/arrow-right.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  Colors.black26,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: const [
          _SwitchItem(title: '消息免打扰', initialOn: false),
          Divider(height: 0, indent: 16, color: Color(0x14000000)),
          _SwitchItem(title: '置顶聊天', initialOn: true),
          Divider(height: 0, indent: 16, color: Color(0x14000000)),
          _SwitchItem(title: '消息提醒', initialOn: false),
        ],
      ),
    );
  }
}

class _SwitchItem extends StatefulWidget {
  const _SwitchItem({
    required this.title,
    required this.initialOn,
  });

  final String title;
  final bool initialOn;

  @override
  State<_SwitchItem> createState() => _SwitchItemState();
}

class _SwitchItemState extends State<_SwitchItem> {
  late bool _on;

  @override
  void initState() {
    super.initState();
    _on = widget.initialOn;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 17,
                color: Color(0xFF000000),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _on = !_on;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 51,
                height: 31,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.5),
                  color: _on ? const Color(0xFF34C759) : const Color(0xFFE5E5EA),
                ),
                child: Align(
                  alignment: _on ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
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
