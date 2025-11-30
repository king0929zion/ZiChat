import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/pages/chat_detail/chat_detail_page.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: _mockChats.length,
        itemBuilder: (context, index) {
          final chat = _mockChats[index];
          final bool isLast = index == _mockChats.length - 1;

          return _ChatListItem(
            chat: chat,
            isLast: isLast,
            index: index,
          );
        },
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
  });

  final _ChatItem chat;
  final bool isLast;
  final int index;

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

  void _handleTap() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ChatDetailPage(
            chatId: widget.chat.id,
            title: widget.chat.title,
            unread: widget.chat.unread,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // iOS 风格的页面切换：新页面从右滑入 + 轻微缩放 + 淡入
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
          
          // 当前页面轻微缩小和淡出
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
                      unread: widget.chat.unread,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            child: Image.asset(
              avatar,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          if (unread > 0)
            Positioned(
              top: -6,
              right: -6,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: AppStyles.animationNormal,
                curve: Curves.elasticOut,
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

class _ChatItem {
  const _ChatItem({
    required this.id,
    required this.title,
    required this.avatar,
    required this.latestMessage,
    required this.latestTime,
    required this.unread,
    required this.muted,
  });

  final String id;
  final String title;
  final String avatar;
  final String latestMessage;
  final String latestTime;
  final int unread;
  final bool muted;
}

const List<_ChatItem> _mockChats = [
  _ChatItem(
    id: 'c1',
    title: '产品例会',
    avatar: 'assets/group-chat.jpg',
    latestMessage: '本周 PRD 已同步，记得过目。',
    latestTime: '09:41',
    unread: 2,
    muted: false,
  ),
  _ChatItem(
    id: 'c2',
    title: '设计讨论',
    avatar: 'assets/avatar.png',
    latestMessage: '收到，晚上补充状态。',
    latestTime: '昨天',
    unread: 0,
    muted: true,
  ),
  _ChatItem(
    id: 'c3',
    title: '文件传输助手',
    avatar: 'assets/avatar-default.jpeg',
    latestMessage: '图片',
    latestTime: '昨天',
    unread: 0,
    muted: false,
  ),
  _ChatItem(
    id: 'c4',
    title: 'Call with Tim',
    avatar: 'assets/me.png',
    latestMessage: '[视频通话]',
    latestTime: '周三',
    unread: 5,
    muted: false,
  ),
  _ChatItem(
    id: 'c5',
    title: '客户反馈',
    avatar: 'assets/bella.jpeg',
    latestMessage: '素材已发，请查收。',
    latestTime: '周二',
    unread: 1,
    muted: false,
  ),
];
