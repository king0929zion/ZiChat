import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/pages/add_friend_page.dart';
import 'package:zichat/pages/ai_contact_prompt_page.dart';
import 'package:zichat/pages/chat_detail/chat_detail_page.dart';
import 'package:zichat/services/avatar_utils.dart';
import 'package:zichat/services/chat_event_manager.dart';
import 'package:zichat/storage/friend_storage.dart';
import 'package:zichat/widgets/weui/weui.dart';

class FriendDetailPage extends StatelessWidget {
  const FriendDetailPage({
    super.key,
    required this.friendId,
  });

  final String friendId;

  String _formatDisplayId(String id) {
    final raw = id.replaceFirst('friend_', '');
    if (raw.length <= 10) return raw;
    return raw.substring(raw.length - 10);
  }

  Future<void> _openChat(BuildContext context) async {
    final friend = FriendStorage.getFriend(friendId);
    if (friend == null) return;

    final dynamicUnread = ChatEventManager.instance.getUnreadCount(friendId);
    final totalUnread = friend.unread + dynamicUnread;
    final pendingMessage = ChatEventManager.instance.getPendingMessage(friendId);

    // 清理未读
    ChatEventManager.instance.clearUnread(friendId);
    await FriendStorage.clearUnread(friendId);

    // ignore: use_build_context_synchronously
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(
          chatId: friend.id,
          title: friend.name,
          avatar: friend.avatar,
          unread: totalUnread,
          pendingMessage: pendingMessage,
          friendPrompt: friend.prompt,
        ),
      ),
    );
  }

  Future<void> _showMoreSheet(BuildContext context) async {
    final friend = FriendStorage.getFriend(friendId);
    if (friend == null) return;

    await showWeuiActionSheet(
      context: context,
      actions: [
        WeuiActionSheetAction(
          label: '编辑好友',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddFriendPage(editFriend: friend),
              ),
            );
          },
        ),
        WeuiActionSheetAction(
          label: '删除好友',
          tone: WeuiActionSheetTone.destructive,
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('删除好友'),
                content: Text('确定要删除“${friend.name}”吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text(
                      '删除',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await FriendStorage.deleteFriend(friendId);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
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
        final friend = FriendStorage.getFriend(friendId);
        if (friend == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
          return const SizedBox.shrink();
        }

        final avatarPath = friend.avatar.isEmpty
            ? AvatarUtils.defaultFriendAvatar
            : friend.avatar;

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
                    _FriendDetailHeader(
                      onBack: () => Navigator.of(context).pop(),
                      onMore: () => _showMoreSheet(context),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          Container(
                            color: AppColors.surface,
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AvatarUtils.buildAvatarWidget(
                                  avatarPath,
                                  size: 72,
                                  borderRadius: 4,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        friend.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'ID：${_formatDisplayId(friend.id)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        '地区：AI 好友',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoTile(
                            title: '朋友资料',
                            subtitle: '编辑提示词/人设',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AiContactPromptPage(
                                    chatId: friend.id,
                                    title: friend.name,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _InfoTile(
                            title: '朋友圈',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('暂未实现')),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _ActionCard(
                            onMessage: () => _openChat(context),
                            onCall: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('暂未实现')),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FriendDetailHeader extends StatelessWidget {
  const _FriendDetailHeader({
    required this.onBack,
    required this.onMore,
  });

  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onBack,
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
          const Expanded(child: SizedBox.shrink()),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onMore,
              icon: SvgPicture.asset(
                AppAssets.iconThreeDot,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SvgPicture.asset(
                AppAssets.iconArrowRight,
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.onMessage,
    required this.onCall,
  });

  final VoidCallback onMessage;
  final VoidCallback onCall;

  Widget _buildAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: AppColors.textPrimary),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _buildAction(
            icon: Icons.chat_bubble_outline,
            label: '发消息',
            onTap: onMessage,
          ),
          const Divider(height: 0, color: AppColors.divider),
          _buildAction(
            icon: Icons.videocam_outlined,
            label: '音视频通话',
            onTap: onCall,
          ),
        ],
      ),
    );
  }
}
