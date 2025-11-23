import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/pages/post_moment_page.dart';

class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _scrolled = false;
  late List<_MomentPost> _posts;
  int? _activeMenuPostId;
  int? _commentPostId;
  bool _showCommentBar = false;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _posts = List<_MomentPost>.from(_mockMoments);
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 60;
      if (scrolled != _scrolled) {
        setState(() {
          _scrolled = scrolled;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        top: true,
        bottom: true,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            color: const Color(0xFFF7F7F7),
            child: Stack(
              children: [
                _buildScrollContent(),
                _buildHeader(context),
                _buildCommentBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _scrolled ? const Color(0xFFF7F7F7) : Colors.transparent,
        border: _scrolled
            ? const Border(
                bottom: BorderSide(
                  color: Color(0x1A000000),
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            padding: const EdgeInsets.all(8),
            icon: SvgPicture.asset(
              'assets/icon/common/go-back.svg',
              width: 12,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xFF1D2129),
                BlendMode.srcIn,
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _scrolled ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Text(
              '朋友圈',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              final text = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_) => const PostMomentPage()),
              );
              if (text != null && text.trim().isNotEmpty) {
                _insertPost(text.trim());
              }
            },
            padding: const EdgeInsets.all(8),
            icon: SvgPicture.asset(
              'assets/icon/common/camera-outline.svg',
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollContent() {
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      children: [
        const _MomentsCover(),
        _MomentsFeed(
          posts: _posts,
          onToggleLike: _handleLikeFromMenu,
          onToggleMenu: _toggleMenu,
          onComment: _startComment,
          activeMenuPostId: _activeMenuPostId,
        ),
      ],
    );
  }

  void _insertPost(String text) {
    final content = text.trim();
    if (content.isEmpty) return;
    setState(() {
      final now = DateTime.now().millisecondsSinceEpoch;
      _posts.insert(
        0,
        _MomentPost(
          id: now,
          userName: '我',
          userAvatar: 'assets/me.png',
          content: content,
          images: const [],
          time: '刚刚',
          likes: const [],
          comments: const [],
        ),
      );
    });
  }

  void _toggleMenu(int postId) {
    setState(() {
      _activeMenuPostId = _activeMenuPostId == postId ? null : postId;
    });
  }

  void _handleLikeFromMenu(int postId) {
    _toggleLike(postId);
    setState(() {
      if (_activeMenuPostId == postId) {
        _activeMenuPostId = null;
      }
    });
  }

  void _startComment(int postId) {
    setState(() {
      _commentPostId = postId;
      _showCommentBar = true;
      _activeMenuPostId = null;
    });
    _commentController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_commentFocusNode);
      }
    });
  }

  void _submitComment() {
    final int? postId = _commentPostId;
    final String text = _commentController.text.trim();
    if (postId == null || text.isEmpty) {
      setState(() {
        _showCommentBar = false;
      });
      FocusScope.of(context).unfocus();
      return;
    }

    setState(() {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index == -1) return;
      final post = _posts[index];
      final comments = List<_MomentComment>.from(post.comments)
        ..add(_MomentComment(user: '我', content: text));
      _posts[index] = _MomentPost(
        id: post.id,
        userName: post.userName,
        userAvatar: post.userAvatar,
        content: post.content,
        images: post.images,
        time: post.time,
        likes: post.likes,
        comments: comments,
      );
      _showCommentBar = false;
      _commentPostId = null;
    });
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  Widget _buildCommentBar(BuildContext context) {
    if (!_showCommentBar) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F7F7),
          border: Border(
            top: BorderSide(
              color: Color(0xFFE5E6EB),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                focusNode: _commentFocusNode,
                decoration: const InputDecoration(
                  hintText: '评论',
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {},
              icon: SvgPicture.asset(
                'assets/icon/keyboard-panel/emoji-icon.svg',
                width: 22,
                height: 22,
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              height: 32,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF07C160),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: _submitComment,
                child: const Text(
                  '发送',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLike(int postId) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index == -1) return;
      final post = _posts[index];
      final likes = List<String>.from(post.likes);
      const me = '我';
      if (likes.contains(me)) {
        likes.remove(me);
      } else {
        likes.add(me);
      }
      _posts[index] = _MomentPost(
        id: post.id,
        userName: post.userName,
        userAvatar: post.userAvatar,
        content: post.content,
        images: post.images,
        time: post.time,
        likes: likes,
        comments: post.comments,
      );
    });
  }
}

class _MomentsCover extends StatelessWidget {
  const _MomentsCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.only(bottom: 30),
      child: Stack(
        children: [
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Image.network(
              'https://img1.baidu.com/it/u=713295211,1805964126&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=281',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 96,
            bottom: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  'Bella',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Color(0x80000000),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 5,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/me.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentsFeed extends StatelessWidget {
  const _MomentsFeed({
    required this.posts,
    required this.onToggleLike,
    required this.onToggleMenu,
    required this.onComment,
    required this.activeMenuPostId,
  });

  final List<_MomentPost> posts;
  final ValueChanged<int> onToggleLike;
  final ValueChanged<int> onToggleMenu;
  final ValueChanged<int> onComment;
  final int? activeMenuPostId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: posts
          .map(
            (item) => _MomentItem(
              post: item,
              onToggleLike: onToggleLike,
              onToggleMenu: onToggleMenu,
              onComment: onComment,
              menuVisible: activeMenuPostId == item.id,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MomentPost {
  const _MomentPost({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.images,
    required this.time,
    required this.likes,
    required this.comments,
  });

  final int id;
  final String userName;
  final String userAvatar;
  final String content;
  final List<String> images;
  final String time;
  final List<String> likes;
  final List<_MomentComment> comments;
}

class _MomentComment {
  const _MomentComment({
    required this.user,
    required this.content,
  });

  final String user;
  final String content;
}

const List<_MomentPost> _mockMoments = [
  _MomentPost(
    id: 1,
    userName: '小美',
    userAvatar: 'assets/bella.png',
    content: '今天的日落太美了 🌅',
    images: [
      'https://img1.baidu.com/it/u=713295211,1805964126&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=281',
    ],
    time: '10 分钟前',
    likes: ['小王', '小李'],
    comments: [
      _MomentComment(user: '小王', content: '哇，太好看了！'),
      _MomentComment(user: '小李', content: '这是在哪儿？'),
    ],
  ),
  _MomentPost(
    id: 2,
    userName: '小王',
    userAvatar: 'assets/avatar.png',
    content: '刚跑完马拉松！🏃‍♂️',
    images: [
      'https://img1.baidu.com/it/u=713295211,1805964126&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=281',
      'https://img1.baidu.com/it/u=713295211,1805964126&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=281',
      'https://img1.baidu.com/it/u=713295211,1805964126&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=281',
    ],
    time: '1 小时前',
    likes: ['小美'],
    comments: [],
  ),
  _MomentPost(
    id: 3,
    userName: '小李',
    userAvatar: 'assets/avatar.png',
    content: '和朋友们一起吃好吃的 🍲',
    images: [
      'https://img1.baidu.com/it/u=713295211,1805964126&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=281',
      'https://img1.baidu.com/it/u=713295211,1805964126&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=281',
      'https://img1.baidu.com/it/u=713295211,1805964126&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=281',
      'https://img1.baidu.com/it/u=713295211,1805964126&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=281',
      'https://img1.baidu.com/it/u=713295211,1805964126&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=281',
    ],
    time: '3 小时前',
    likes: [],
    comments: [],
  ),
];

class _MomentItem extends StatelessWidget {
  const _MomentItem({
    required this.post,
    required this.onToggleLike,
    required this.onToggleMenu,
    required this.onComment,
    required this.menuVisible,
  });

  final _MomentPost post;
  final ValueChanged<int> onToggleLike;
  final ValueChanged<int> onToggleMenu;
  final ValueChanged<int> onComment;
  final bool menuVisible;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFFF2F2F2), width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(right: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                post.userAvatar,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: _MomentContent(
              post: post,
              onToggleLike: onToggleLike,
              onToggleMenu: onToggleMenu,
              onComment: onComment,
              menuVisible: menuVisible,
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentContent extends StatelessWidget {
  const _MomentContent({
    required this.post,
    required this.onToggleLike,
    required this.onToggleMenu,
    required this.onComment,
    required this.menuVisible,
  });

  final _MomentPost post;
  final ValueChanged<int> onToggleLike;
  final ValueChanged<int> onToggleMenu;
  final ValueChanged<int> onComment;
  final bool menuVisible;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.userName,
          style: const TextStyle(
            color: Color(0xFF576B95),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          post.content,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            height: 1.5,
          ),
        ),
        if (post.images.isNotEmpty) ...[
          const SizedBox(height: 8),
          _MomentImages(images: post.images),
        ],
        const SizedBox(height: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  post.time,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB2B2B2),
                  ),
                ),
                GestureDetector(
                  onTap: () => onToggleMenu(post.id),
                  child: Container(
                    width: 32,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'assets/icon/three-dot.svg',
                      width: 18,
                      height: 14,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF1D2129),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (menuVisible)
              Positioned(
                right: 40,
                top: -4,
                child: _MomentOperationMenu(
                  hasLiked: post.likes.contains('我'),
                  onLike: () => onToggleLike(post.id),
                  onComment: () => onComment(post.id),
                ),
              ),
          ],
        ),
        if (post.likes.isNotEmpty || post.comments.isNotEmpty) ...[
          const SizedBox(height: 8),
          _MomentCommentsArea(post: post),
        ],
      ],
    );
  }
}

class _MomentImages extends StatelessWidget {
  const _MomentImages({
    required this.images,
  });

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    String gridClass;
    if (images.length == 1) {
      gridClass = 'cols-1';
    } else if (images.length == 2 || images.length == 4) {
      gridClass = 'cols-2';
    } else {
      gridClass = 'cols-3';
    }

    int crossAxisCount;
    switch (gridClass) {
      case 'cols-1':
        crossAxisCount = 1;
        break;
      case 'cols-2':
        crossAxisCount = 2;
        break;
      default:
        crossAxisCount = 3;
    }

    final double itemSize = 90;

    return SizedBox(
      width: crossAxisCount * itemSize + (crossAxisCount - 1) * 4,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final src = images[index];
          return Container(
            width: itemSize,
            height: itemSize,
            color: const Color(0xFFF0F0F0),
            child: Image.network(
              src,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}

class _MomentCommentsArea extends StatelessWidget {
  const _MomentCommentsArea({
    required this.post,
  });

  final _MomentPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.likes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    'assets/icon/discover/heart-outline.svg',
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF576B95),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      post.likes.join('，'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF576B95),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (post.comments.isNotEmpty)
              const Divider(
                height: 0,
                thickness: 0.5,
                color: Color(0xFFE5E6EB),
              ),
          ],
          if (post.comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: post.comments
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: c.user,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF576B95),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(
                                text: '：',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1D2129),
                                ),
                              ),
                              TextSpan(
                                text: c.content,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1D2129),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _MomentOperationMenu extends StatelessWidget {
  const _MomentOperationMenu({
    required this.hasLiked,
    required this.onLike,
    required this.onComment,
  });

  final bool hasLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 32,
        constraints: const BoxConstraints(minWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF4C4C4C),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OpButton(
              icon: 'assets/icon/discover/heart-outline.svg',
              label: hasLiked ? '取消' : '赞',
              onTap: onLike,
            ),
            Container(
              width: 1,
              height: 20,
              color: const Color(0xFF333333),
            ),
            _OpButton(
              icon: 'assets/icon/discover/comment-outline.svg',
              label: '评论',
              onTap: onComment,
            ),
          ],
        ),
      ),
    );
  }
}

class _OpButton extends StatelessWidget {
  const _OpButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon,
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
