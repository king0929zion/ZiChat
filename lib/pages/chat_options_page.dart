import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/pages/ai_contact_prompt_page.dart';
import 'package:zichat/pages/ai_soul_panel_page.dart';
import 'package:zichat/pages/chat_background_page.dart';
import 'package:zichat/pages/chat_search_page.dart';
import 'package:zichat/services/ai_chat_service.dart';
import 'package:zichat/services/avatar_utils.dart';
import 'package:zichat/storage/friend_storage.dart';
import 'package:zichat/storage/chat_storage.dart';
import 'package:zichat/widgets/weui/weui.dart';

class ChatOptionsPage extends StatelessWidget {
  const ChatOptionsPage({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundChat,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            color: AppColors.backgroundChat,
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
    return WeuiCellGroup(
      margin: EdgeInsets.zero,
      children: [
        WeuiCell(
          title: '查找聊天记录',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatSearchPage(
                  chatId: chatId,
                  chatName: '聊天记录',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AiPromptItem extends StatelessWidget {
  const _AiPromptItem({required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    return WeuiCellGroup(
      margin: EdgeInsets.zero,
      children: [
        WeuiCell(
          title: 'AI 提示词',
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
        ),
      ],
    );
  }
}

class _BackgroundItem extends StatelessWidget {
  const _BackgroundItem({required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context) {
    return WeuiCellGroup(
      margin: EdgeInsets.zero,
      children: [
        WeuiCell(
          title: '设置当前聊天背景',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatBackgroundPage(chatId: chatId),
              ),
            );
          },
        ),
      ],
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
    return WeuiCellGroup(
      margin: EdgeInsets.zero,
      children: [
        _DestructiveCell(
          title: '清空聊天记录',
          onTap: () => _handleClear(context),
        ),
      ],
    );
  }
}

class _DestructiveCell extends StatelessWidget {
  const _DestructiveCell({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        highlightColor: AppColors.disabledBg,
        splashColor: Colors.transparent,
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
                    color: AppColors.error,
                  ),
                ),
                SvgPicture.asset(
                  AppAssets.iconArrowRight,
                  width: 12,
                  height: 12,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textHint,
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
      color: AppColors.backgroundChat,
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
                AppAssets.iconGoBack,
                width: 12,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '聊天信息',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
      padding: const EdgeInsets.only(top: 8),
      children: [
        _MembersSection(chatId: chatId),
        const SizedBox(height: 8),
        _SearchChatItem(chatId: chatId),
        const SizedBox(height: 8),
        _AiPromptItem(chatId: chatId),
        const SizedBox(height: 8),
        const _SwitchCard(),
        const SizedBox(height: 8),
        _BackgroundItem(chatId: chatId),
        const SizedBox(height: 8),
        _ClearChatItem(chatId: chatId),
        const SizedBox(height: 8),
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

        return WeuiCellGroup(
          margin: EdgeInsets.zero,
          dividerIndent: 0,
          children: [
            Padding(
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
                            color: AppColors.textSecondary,
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
                    child: Material(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: AppColors.border, width: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: InkWell(
                        onTap: () => WeuiToast.show(context, message: '功能开发中'),
                        borderRadius: BorderRadius.circular(4),
                        highlightColor: AppColors.disabledBg,
                        splashColor: Colors.transparent,
                        child: Center(
                          child: SvgPicture.asset(
                            AppAssets.iconPlus,
                            width: 32,
                            height: 32,
                            colorFilter: const ColorFilter.mode(
                              AppColors.textHint,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    return WeuiCellGroup(
      margin: EdgeInsets.zero,
      children: [
        for (final item in items)
          WeuiCell(
            title: item.title,
            onTap: () => WeuiToast.show(context, message: '功能开发中'),
          ),
      ],
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard();

  @override
  Widget build(BuildContext context) {
    return const WeuiCellGroup(
      margin: EdgeInsets.zero,
      children: [
        _SwitchItem(title: '消息免打扰', initialOn: false),
        _SwitchItem(title: '置顶聊天', initialOn: true),
        _SwitchItem(title: '消息提醒', initialOn: false),
      ],
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
    return WeuiCell(
      title: widget.title,
      showArrow: false,
      trailing: IgnorePointer(
        ignoring: true,
        child: WeuiSwitch(
          value: _on,
          onChanged: (_) {},
        ),
      ),
      onTap: () {
        setState(() {
          _on = !_on;
        });
      },
    );
  }
}
