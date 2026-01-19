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
                      physics: const BouncingScrollPhysics(),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final bool isLast = index == chats.length - 1;

                        // 获取动态未读数
                        final dynamicUnread =
                            ChatEventManager.instance.getUnreadCount(chat.id);
                        final totalUnread = chat.unread + dynamicUnread;

                        return _ChatListItem(
                          chat: chat,
                          isLast: isLast,
                          index: index,
                          dynamicUnread: totalUnread,
                          hasPendingMessage: ChatEventManager.instance
                              .hasPendingMessage(chat.id),
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
class _ChatListItem extends StatefulWidget {
  const _ChatListItem({
    required this.chat,
    required this.isLast,
    required this.index,
    this.dynamicUnread = 0,
    this.hasPendingMessage = false,
  });

  final _ChatItemData chat;
  final bool isLast;
  final int index;
  final int dynamicUnread;
  final bool hasPendingMessage;

  @override
  State<_ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<_ChatListItem>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.index * 50),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    HapticFeedback.lightImpact();
    
    // 清除未读数
    ChatEventManager.instance.clearUnread(widget.chat.id);
    
    // 如果是 AI 好友，清除存储的未读数
    if (widget.chat.isAiFriend) {
      await FriendStorage.clearUnread(widget.chat.id);
    }
    
    // 获取主动消息
    final pendingMessage = ChatEventManager.instance.getPendingMessage(widget.chat.id);

    if (!mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ChatDetailPage(
            chatId: widget.chat.id,
            title: widget.chat.title,
            avatar: widget.chat.avatar,
            unread: widget.dynamicUnread,
            pendingMessage: pendingMessage,
            friendPrompt: widget.chat.prompt,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          
          final fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ));
          
          final secondarySlide = Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.1, 0),
          ).animate(CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeOutCubic,
          ));
          
          return SlideTransition(
            position: secondarySlide,
            child: SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    // 返回时刷新列表
    if (mounted) {
      // ChatDetailPage 内会更新 FriendStorage/ChatEventManager，这里无需额外刷新
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: _handleTap,
          child: AnimatedContainer(
            duration: AppStyles.animationFast,
            color: _isPressed ? AppColors.background : AppColors.surface,
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: _ChatAvatar(
                      avatar: widget.chat.avatar,
                      unread: widget.dynamicUnread,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: double.infinity,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        border: widget.isLast
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
                                  widget.chat.title,
                                  style: AppStyles.titleMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.chat.latestTime,
                                style: AppStyles.caption,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.chat.latestMessage,
                                  style: AppStyles.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (widget.chat.muted)
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
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AvatarUtils.buildAvatarWidget(
            avatar.isEmpty ? AvatarUtils.defaultFriendAvatar : avatar,
            size: 48,
            borderRadius: AppStyles.radiusMedium,
          ),
          if (unread > 0)
            Positioned(
              top: -6,
              right: -6,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: AppStyles.animationNormal,
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.unreadBadge,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textWhite,
                    ),
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

