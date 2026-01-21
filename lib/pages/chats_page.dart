import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/pages/chat_detail/chat_detail_page.dart';
import 'package:zichat/services/avatar_utils.dart';
import 'package:zichat/services/chat_event_manager.dart';
import 'package:zichat/storage/friend_storage.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}/${time.day}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: FriendStorage.listenable(),
      builder: (context, _, __) {
        final chats = FriendStorage.getAllFriends()
            .map((f) => _ChatItemData(
                  id: f.id,
                  title: f.name,
                  avatar: f.avatar,
                  latestMessage: f.lastMessage ?? '开始聊天吧',
                  latestTime: _formatTime(f.lastMessageTime),
                  latestMessageTime: f.lastMessageTime,
                  createdAt: f.createdAt,
                  unread: f.unread,
                  muted: false,
                  isAiFriend: true,
                  prompt: f.prompt,
                ))
            .toList()
          ..sort((a, b) {
            final aTime = a.latestMessageTime ?? a.createdAt;
            final bTime = b.latestMessageTime ?? b.createdAt;
            return bTime.compareTo(aTime);
          });

        return AnimatedBuilder(
          animation: ChatEventManager.instance,
          builder: (context, __) {
            return Container(
              color: AppColors.surface,
              child: chats.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const ClampingScrollPhysics(),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final bool isLast = index == chats.length - 1;

                        // 获取动态未读数
                        final dynamicUnread =
                            ChatEventManager.instance.getUnreadCount(chat.id);
                        final totalUnread = chat.unread + dynamicUnread;

                        return _ChatListItem(
                          key: ValueKey(chat.id),
                          chat: chat,
                          isLast: isLast,
                          dynamicUnread: totalUnread,
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无聊天',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '去通讯录添加一个 AI 好友吧',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

/// 聊天列表项组件
class _ChatListItem extends StatelessWidget {
  const _ChatListItem({
    super.key,
    required this.chat,
    required this.isLast,
    this.dynamicUnread = 0,
  });

  final _ChatItemData chat;
  final bool isLast;
  final int dynamicUnread;

  Future<void> _handleTap(BuildContext context) async {
    HapticFeedback.lightImpact();
    
    // 清除未读数
    ChatEventManager.instance.clearUnread(chat.id);
    
    // 如果是 AI 好友，清除存储的未读数
    if (chat.isAiFriend) {
      await FriendStorage.clearUnread(chat.id);
    }
    
    // 获取主动消息
    final pendingMessage = ChatEventManager.instance.getPendingMessage(chat.id);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(
          chatId: chat.id,
          title: chat.title,
          avatar: chat.avatar,
          unread: dynamicUnread,
          pendingMessage: pendingMessage,
          friendPrompt: chat.prompt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () => _handleTap(context),
        highlightColor: AppColors.background,
        splashColor: Colors.transparent,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: _ChatAvatar(
                  avatar: chat.avatar,
                  unread: dynamicUnread,
                ),
              ),
              Expanded(
                child: Container(
                  height: double.infinity,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : const Border(
                            bottom: BorderSide(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.title,
                              style: AppStyles.titleSmall.copyWith(fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            chat.latestTime,
                            style: AppStyles.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.latestMessage,
                              style: AppStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (chat.muted)
                            SvgPicture.asset(
                              'assets/icon/mute-ring.svg',
                              width: 16,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                AppColors.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 聊天头像组件
class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.avatar,
    required this.unread,
  });

  final String avatar;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AvatarUtils.buildAvatarWidget(
            avatar.isEmpty ? AvatarUtils.defaultFriendAvatar : avatar,
            size: 40,
            borderRadius: AppStyles.radiusSmall,
          ),
          if (unread > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.unreadBadge,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surface, width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 聊天列表数据模型
class _ChatItemData {
  const _ChatItemData({
    required this.id,
    required this.title,
    required this.avatar,
    required this.latestMessage,
    required this.latestTime,
    required this.latestMessageTime,
    required this.createdAt,
    required this.unread,
    required this.muted,
    this.isAiFriend = false,
    this.prompt,
  });

  final String id;
  final String title;
  final String avatar;
  final String latestMessage;
  final String latestTime;
  final DateTime? latestMessageTime;
  final DateTime createdAt;
  final int unread;
  final bool muted;
  final bool isAiFriend;
  final String? prompt;
}
