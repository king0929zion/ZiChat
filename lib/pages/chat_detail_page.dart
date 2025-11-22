import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zichat/pages/chat_options_page.dart';
import 'package:zichat/pages/transfer_page.dart';
import 'package:zichat/pages/transfer_receive_page.dart';
import 'package:zichat/storage/chat_storage.dart';

// 消息数据模型
class _ChatMessage {
  const _ChatMessage({
    required this.id,
    required this.type,
    this.direction,
    this.name,
    this.text,
    this.avatar,
    this.image,
    this.duration,
    this.amount,
    this.status,
    this.note,
  });

  final String id;
  final String type; // text, image, voice, red-packet, transfer, timestamp, system, recall
  final String? direction; // in, out
  final String? name;
  final String? text;
  final String? avatar;
  final String? image;
  final String? duration;
  final String? amount;
  final String? status;
  final String? note;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'direction': direction,
      'name': name,
      'text': text,
      'avatar': avatar,
      'image': image,
      'duration': duration,
      'amount': amount,
      'status': status,
      'note': note,
    };
  }

  factory _ChatMessage.fromMap(Map<String, dynamic> map) {
    return _ChatMessage(
      id: map['id'] as String,
      type: map['type'] as String,
      direction: map['direction'] as String?,
      name: map['name'] as String?,
      text: map['text'] as String?,
      avatar: map['avatar'] as String?,
      image: map['image'] as String?,
      duration: map['duration'] as String?,
      amount: map['amount'] as String?,
      status: map['status'] as String?,
      note: map['note'] as String?,
    );
  }
}

// 模拟消息数据
final List<_ChatMessage> _mockMessages = [
  const _ChatMessage(id: 't1', type: 'timestamp', text: '今天 09:20'),
  const _ChatMessage(
    id: 'm1',
    type: 'text',
    direction: 'in',
    name: 'Liam',
    avatar: 'assets/me.png',
    text: '新需求这周能联调吗？我准备把埋点整理一版。',
  ),
  const _ChatMessage(
    id: 'm2',
    type: 'text',
    direction: 'out',
    avatar: 'assets/avatar.png',
    text: '已经提测了,晚上前给你最新构建。',
  ),
  const _ChatMessage(
    id: 'm3a',
    type: 'image',
    direction: 'in',
    avatar: 'assets/me.png',
    image: 'assets/add-contacts-bg.jpeg',
  ),
  const _ChatMessage(
    id: 'm3b',
    type: 'image',
    direction: 'in',
    avatar: 'assets/me.png',
    image: 'assets/cn-service-up.jpg',
  ),
  const _ChatMessage(
    id: 'm4',
    type: 'voice',
    direction: 'out',
    avatar: 'assets/avatar.png',
    duration: '12"',
  ),
  const _ChatMessage(
    id: 'm5',
    type: 'red-packet',
    direction: 'in',
    avatar: 'assets/me.png',
    text: '恭喜发财，大吉大利',
    note: '产品红包',
    status: '微信红包',
  ),
  const _ChatMessage(
    id: 'm6',
    type: 'transfer',
    direction: 'out',
    avatar: 'assets/avatar.png',
    amount: '520.00',
    note: '新版动效',
    status: '待对方确认',
  ),
  const _ChatMessage(id: 't2', type: 'timestamp', text: '昨天 23:18'),
  const _ChatMessage(id: 'm7', type: 'recall', text: '你撤回了一条消息'),
  const _ChatMessage(
    id: 'm9',
    type: 'text',
    direction: 'in',
    name: 'Liam',
    avatar: 'assets/me.png',
    text: '收到，合并完再 ping 你。',
  ),
  const _ChatMessage(
    id: 'm10',
    type: 'text',
    direction: 'out',
    avatar: 'assets/avatar.png',
    text: '辛苦啦～',
  ),
];

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({
    super.key,
    required this.chatId,
    required this.title,
    required this.unread,
  });

  final String chatId;
  final String title;
  final int unread;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  bool _voiceMode = false;
  bool _showEmoji = false;
  bool _showFn = false;
  List<_ChatMessage> _messages = [];
  final List<String> _recentEmojis = [];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      // 监听输入变化，用于切换“发送”按钮与“+”按钮
      setState(() {});
    });
    _loadMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(maxExtent);
      }
    });
  }

  Future<void> _loadMessages() async {
    final bool hasStored = ChatStorage.hasMessages(widget.chatId);
    final List<Map<String, dynamic>> stored =
        await ChatStorage.loadMessages(widget.chatId);
    setState(() {
      if (!hasStored && stored.isEmpty && widget.chatId == 'c1') {
        // 首次进入第一个会话时，用内置的模拟消息做示例
        _messages = List<_ChatMessage>.from(_mockMessages);
      } else {
        _messages = stored.map(_ChatMessage.fromMap).toList();
      }
    });
    _scrollToBottom();
  }

  Future<void> _saveMessages() async {
    final list = _messages.map((m) => m.toMap()).toList();
    await ChatStorage.saveMessages(widget.chatId, list);
  }

  void _toggleVoice() {
    setState(() {
      _voiceMode = !_voiceMode;
      _showEmoji = false;
      _showFn = false;
    });
  }

  void _toggleEmoji() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showEmoji = !_showEmoji;
      _showFn = false;
    });
    _scrollToBottom();
  }

  void _handleEmojiTap(String emoji) {
    setState(() {
      final text = _inputController.text;
      final selection = _inputController.selection;
      int insertIndex =
          selection.isValid ? selection.end.clamp(0, text.length) : text.length;

      final newText = text.substring(0, insertIndex) +
          emoji +
          text.substring(insertIndex);
      _inputController.text = newText;
      _inputController.selection = TextSelection.collapsed(
        offset: insertIndex + emoji.length,
      );

      _recentEmojis.remove(emoji);
      _recentEmojis.insert(0, emoji);
      if (_recentEmojis.length > 20) {
        _recentEmojis.removeLast();
      }
    });
  }

  void _handleEmojiDelete() {
    setState(() {
      final text = _inputController.text;
      if (text.isEmpty) return;

      final selection = _inputController.selection;
      int end = selection.isValid ? selection.end : text.length;
      if (end <= 0 || end > text.length) {
        end = text.length;
      }
      if (end == 0) return;

      final before = text.substring(0, end);
      final after = text.substring(end);
      if (before.isEmpty) return;
      final newBefore = before.substring(0, before.length - 1);
      final newText = newBefore + after;
      _inputController.text = newText;
      _inputController.selection =
          TextSelection.collapsed(offset: newBefore.length);
    });
  }

  void _toggleFn() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showFn = !_showFn;
      _showEmoji = false;
    });
    _scrollToBottom();
  }

  void _closePanels() {
    setState(() {
      _showEmoji = false;
      _showFn = false;
    });
  }

  bool get _hasText => _inputController.text.trim().isNotEmpty;

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          type: 'text',
          direction: 'out',
          avatar: 'assets/avatar.png',
          text: text,
        ),
      );
      _inputController.clear();
    });
    _saveMessages();
    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          id: 'img-${DateTime.now().millisecondsSinceEpoch}',
          type: 'image',
          direction: 'out',
          avatar: 'assets/avatar.png',
          image: file.path,
        ),
      );
      _showFn = false;
    });
    _saveMessages();
    _scrollToBottom();
  }

  void _handleFnTap(_FnItem item) {
    // 根据功能类型执行不同操作，目前先实现图片发送
    switch (item.label) {
      case '相册':
        _pickImage(ImageSource.gallery);
        break;
      case '拍摄':
        _pickImage(ImageSource.camera);
        break;
      case '转账':
        setState(() {
          _showFn = false;
        });
        Navigator.of(context)
            .push<double>(
          MaterialPageRoute(builder: (_) => const TransferPage()),
        )
            .then((amount) {
          if (!mounted || amount == null || amount <= 0) return;
          setState(() {
            _messages.add(
              _ChatMessage(
                id: 'tr-${DateTime.now().millisecondsSinceEpoch}',
                type: 'transfer',
                direction: 'out',
                avatar: 'assets/avatar.png',
                amount: amount.toStringAsFixed(2),
                note: '转账',
                status: '待对方确认',
              ),
            );
          });
          _saveMessages();
          _scrollToBottom();
        });
        break;
      default:
        // 其它功能目前保留占位，不产生实际效果
        break;
    }
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
            child: Column(
              children: [
                _Header(
                  title: widget.title,
                  unread: widget.unread,
                  onBack: () => Navigator.of(context).pop(),
                  onMore: () async {
                    final bool? cleared = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => ChatOptionsPage(chatId: widget.chatId),
                      ),
                    );
                    if (!mounted) return;
                    if (cleared == true) {
                      setState(() {
                        _messages = [];
                      });
                    }
                  },
                ),
                Expanded(
                  child: Container(
                    color: const Color(0xFFEDEDED),
                    child: GestureDetector(
                      onTap: _closePanels,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, index) =>
                            _MessageItem(message: _messages[index]),
                      ),
                    ),
                  ),
                ),
                _Toolbar(
                  controller: _inputController,
                  voiceMode: _voiceMode,
                  showEmoji: _showEmoji,
                  showFn: _showFn,
                  hasText: _hasText,
                  onVoiceToggle: _toggleVoice,
                  onEmojiToggle: _toggleEmoji,
                  onFnToggle: _toggleFn,
                  onSend: _send,
                  onFocus: _closePanels,
                ),
                if (_showEmoji)
                  SizedBox(
                    height: 280,
                    child: _EmojiPanel(
                      recentEmojis: _recentEmojis,
                      onEmojiTap: _handleEmojiTap,
                      onEmojiDelete: _handleEmojiDelete,
                    ),
                  ),
                if (_showFn)
                  SizedBox(
                    height: 220,
                    child: _FnPanel(
                      onItemTap: _handleFnTap,
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

// Header 组件：顶部标题栏
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.unread,
    required this.onBack,
    required this.onMore,
  });

  final String title;
  final int unread;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icon/common/go-back.svg',
                    width: 12,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF1D2129),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$unread',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1D2129),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onMore,
              padding: EdgeInsets.zero,
              icon: SvgPicture.asset(
                'assets/icon/three-dot.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF1D2129),
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

// MessageItem 组件：单条消息
class _MessageItem extends StatelessWidget {
  const _MessageItem({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    // 时间戳、系统消息、撤回消息
    if (message.type == 'timestamp') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Center(
          child: Text(
            message.text ?? '',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFB2B2B2),
            ),
          ),
        ),
      );
    }

    if (message.type == 'system' || message.type == 'recall') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Center(
          child: Text(
            message.text ?? '',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFB2B2B2),
            ),
          ),
        ),
      );
    }

    // 普通消息
    final bool isOutgoing = message.direction == 'out';
    final String avatar = message.avatar ??
        (isOutgoing ? 'assets/avatar.png' : 'assets/me.png');

    final rowChildren = <Widget>[
      _Avatar(avatar: avatar),
      const SizedBox(width: 8),
      Expanded(
        child: _MessageContent(
          message: message,
          isOutgoing: isOutgoing,
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14), // HTML: margin-bottom: 14px
      child: Row(
        mainAxisAlignment:
            isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isOutgoing ? rowChildren.reversed.toList() : rowChildren,
      ),
    );
  }
}

// Avatar 组件：头像
class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatar});

  final String avatar;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        avatar,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
  }
}

// MessageContent 组件：消息内容（包括昵称和气泡）
class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.message,
    required this.isOutgoing,
  });

  final _ChatMessage message;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    final bubble = _Bubble(
      message: message,
      isOutgoing: isOutgoing,
    );

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: bubble,
      ),
    );
  }
}

// Bubble 组件：根据消息类型渲染不同的气泡
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isOutgoing,
  });

  final _ChatMessage message;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case 'image':
        return _ImageBubble(imageAsset: message.image ?? '');
      case 'voice':
        return _VoiceBubble(message: message, isOutgoing: isOutgoing);
      case 'red-packet':
        return _RedPacketBubble(message: message, isOutgoing: isOutgoing);
      case 'transfer':
        return _TransferBubble(message: message, isOutgoing: isOutgoing);
      default:
        return _TextBubble(message: message, isOutgoing: isOutgoing);
    }
  }
}

// TextBubble：文本消息气泡
class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.message,
    required this.isOutgoing,
  });

  final _ChatMessage message;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isOutgoing ? const Color(0xFF95EC69) : Colors.white;

    return _BaseBubble(
      backgroundColor: bgColor,
      isOutgoing: isOutgoing,
      child: Text(
        message.text ?? '',
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF111111),
          height: 1.4, // HTML: line-height: 1.4
        ),
      ),
    );
  }
}

// ImageBubble：图片消息
class _ImageBubble extends StatelessWidget {
  const _ImageBubble({required this.imageAsset});

  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (imageAsset.startsWith('assets/')) {
      child = Image.asset(
        imageAsset,
        width: 240,
        fit: BoxFit.cover,
      );
    } else {
      child = Image.file(
        File(imageAsset),
        width: 240,
        fit: BoxFit.cover,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: child,
    );
  }
}

// VoiceBubble：语音消息气泡
class _VoiceBubble extends StatelessWidget {
  const _VoiceBubble({
    required this.message,
    required this.isOutgoing,
  });

  final _ChatMessage message;
  final bool isOutgoing;

  int _parseDuration(String? source) {
    if (source == null || source.isEmpty) return 1;
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(source);
    if (match == null) return 1;
    final value = double.tryParse(match.group(0) ?? '1') ?? 1;
    final result = value.round();
    return result <= 0 ? 1 : result;
  }

  @override
  Widget build(BuildContext context) {
    final duration = _parseDuration(message.duration);
    final int width = duration < 6 ? 90 + duration * 8 : 200;
    final Color bgColor = isOutgoing ? const Color(0xFF95EC69) : Colors.white;

    return SizedBox(
      width: width.toDouble(),
      child: _BaseBubble(
        backgroundColor: bgColor,
        isOutgoing: isOutgoing,
        child: Row(
          mainAxisAlignment:
              isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isOutgoing) ...[
              Text(
                '语音 $duration"',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1D2129),
                ),
              ),
              const SizedBox(width: 8),
            ],
            SvgPicture.asset(
              'assets/icon/keyboard-panel/voice-record.svg',
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                Color(0xFF1D2129),
                BlendMode.srcIn,
              ),
            ),
            if (isOutgoing) ...[
              const SizedBox(width: 8),
              Text(
                '语音 $duration"',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1D2129),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// RedPacketBubble：红包消息气泡
class _RedPacketBubble extends StatelessWidget {
  const _RedPacketBubble({
    required this.message,
    required this.isOutgoing,
  });

  final _ChatMessage message;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    final String title = message.text ?? '恭喜发财，大吉大利';
    final String note = message.note ?? '微信红包';
    final String status = message.status ?? '微信红包';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [Color(0xFFFB4A3C), Color(0xFFEF3A2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note,
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
        Positioned(
          top: 16,
          right: isOutgoing ? -4 : null,
          left: isOutgoing ? null : -4,
          child: Transform.rotate(
            angle: pi / 4,
            child: Container(
              width: 8,
              height: 8,
              color: const Color(0xFFEF3A2E),
            ),
          ),
        ),
      ],
    );
  }
}

// TransferBubble：转账消息气泡
class _TransferBubble extends StatelessWidget {
  const _TransferBubble({
    required this.message,
    required this.isOutgoing,
  });

  final _ChatMessage message;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    final String amount = message.amount ?? '0.00';
    final String rawStatus = message.status ?? '';

    final bool isAccepted =
        rawStatus.toLowerCase().contains('accepted') || rawStatus.contains('已收');

    final Color bubbleColor =
        isAccepted ? const Color(0xFFFFD8AD) : const Color(0xFFFF9852);

    String descText;
    if (rawStatus.trim().isNotEmpty) {
      descText = rawStatus.trim();
    } else if (isAccepted) {
      descText = '已收款';
    } else if (message.direction == 'out') {
      descText = '待对方确认收款';
    } else {
      descText = '待收款';
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransferReceivePage(amount: amount),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 235,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icon/chats/transfer-outline.svg',
                          width: 32,
                          height: 32,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¥$amount',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            descText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Color(0x99FFFFFF),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: const Text(
                    '微信转账',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: isOutgoing ? -4 : null,
            left: isOutgoing ? null : -4,
            child: Transform.rotate(
              angle: pi / 4,
              child: Container(
                width: 8,
                height: 8,
                color: bubbleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// BaseBubble：基础气泡（带箭头）
class _BaseBubble extends StatelessWidget {
  const _BaseBubble({
    required this.backgroundColor,
    required this.child,
    required this.isOutgoing,
  });

  final Color backgroundColor;
  final Widget child;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // HTML: padding: 8px 10px
          constraints: const BoxConstraints(minHeight: 40), // HTML: min-height: 40px
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4), // HTML: border-radius: 4px
          ),
          child: child,
        ),
        // 箭头：宽高 8x8，旋转 45度，位置 top: 16px, left/right: -4px
        Positioned(
          top: 16,
          right: isOutgoing ? -4 : null,
          left: isOutgoing ? null : -4,
          child: Transform.rotate(
            angle: pi / 4, // 45度 = pi/4
            child: Container(
              width: 8,
              height: 8,
              color: backgroundColor,
            ),
          ),
        ),
      ],
    );
  }
}

// Toolbar 组件：底部输入工具栏
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.voiceMode,
    required this.showEmoji,
    required this.showFn,
    required this.hasText,
    required this.onVoiceToggle,
    required this.onEmojiToggle,
    required this.onFnToggle,
    required this.onSend,
    required this.onFocus,
  });

  final TextEditingController controller;
  final bool voiceMode;
  final bool showEmoji;
  final bool showFn;
  final bool hasText;
  final VoidCallback onVoiceToggle;
  final VoidCallback onEmojiToggle;
  final VoidCallback onFnToggle;
  final VoidCallback onSend;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7), // HTML: background: #F7F7F7
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E6EB), // HTML: border-top: 0.5px solid #E5E6EB
            width: 0.5,
          ),
        ),
      ),
      constraints: const BoxConstraints(minHeight: 56), // HTML: min-height: 56px
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8), // HTML: padding: 8px 10px
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧：语音/键盘切换按钮
          _ToolbarIconButton(
            onPressed: onVoiceToggle,
            asset: voiceMode
                ? 'assets/icon/keyboard-panel/keyboard.svg'
                : 'assets/icon/keyboard-panel/voice-record.svg',
          ),
          const SizedBox(width: 10), // HTML: gap: 10px
          // 中间：输入框或语音按钮
          Expanded(
            child: voiceMode
                ? _VoiceButton()
                : _InputField(
                    controller: controller,
                    onFocus: onFocus,
                  ),
          ),
          const SizedBox(width: 10), // HTML: gap: 10px
          // 右侧：表情按钮（始终存在，只在图标上切换键盘/表情）
          _ToolbarIconButton(
            onPressed: onEmojiToggle,
            asset: showEmoji
                ? 'assets/icon/keyboard-panel/keyboard.svg'
                : 'assets/icon/keyboard-panel/emoji-icon.svg',
          ),
          const SizedBox(width: 10), // HTML: gap: 10px
          // 最右：更多/发送按钮（互斥）
          if (hasText)
            GestureDetector(
              onTap: onSend,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF07C160),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '发送',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            _ToolbarIconButton(
              onPressed: onFnToggle,
              asset: 'assets/icon/common/circle-plus.svg',
            ),
        ],
      ),
    );
  }
}

// ToolbarIconButton：工具栏图标按钮
class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.onPressed,
    required this.asset,
  });

  final VoidCallback onPressed;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 28, // HTML: width: 28px
        height: 28, // HTML: height: 28px
        child: SvgPicture.asset(
          asset,
          width: 28,
          height: 28,
        ),
      ),
    );
  }
}

// InputField：输入框
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.onFocus,
  });

  final TextEditingController controller;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38, // HTML: height: 38px
      decoration: BoxDecoration(
        color: Colors.white, // HTML: background: #FFFFFF
        borderRadius: BorderRadius.circular(4), // HTML: border-radius: 4px
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: controller,
        onTap: onFocus,
        decoration: const InputDecoration(
          hintText: '发送消息', // HTML: placeholder
          hintStyle: TextStyle(
            fontSize: 18, // HTML: font-size: 18px
            color: Color(0xFFB2B2B2), // HTML: color: #B2B2B2
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          fontSize: 18,
          color: Color(0xFF111111),
        ),
      ),
    );
  }
}

// VoiceButton：按住说话按钮
class _VoiceButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text(
        '按住 说话',
        style: TextStyle(
          fontSize: 16,
          color: Color(0xFF111111),
        ),
      ),
    );
  }
}

// 功能面板配置
class _FnItem {
  const _FnItem({
    required this.label,
    required this.asset,
  });

  final String label;
  final String asset;
}

const List<_FnItem> _fnItems = [
  _FnItem(
    label: '相册',
    asset: 'assets/icon/keyboard-panel/album.svg',
  ),
  _FnItem(
    label: '拍摄',
    asset: 'assets/icon/keyboard-panel/camera.svg',
  ),
  _FnItem(
    label: '视频通话',
    asset: 'assets/icon/keyboard-panel/video-call.svg',
  ),
  _FnItem(
    label: '位置',
    asset: 'assets/icon/keyboard-panel/location.svg',
  ),
  _FnItem(
    label: '转账',
    asset: 'assets/icon/keyboard-panel/transfer.svg',
  ),
  _FnItem(
    label: '红包',
    asset: 'assets/icon/keyboard-panel/red-packet.svg',
  ),
  _FnItem(
    label: '语音输入',
    asset: 'assets/icon/keyboard-panel/voice-input.svg',
  ),
  _FnItem(
    label: '收藏',
    asset: 'assets/icon/keyboard-panel/favorites.svg',
  ),
];

// 功能面板：分页 + 网格
class _FnPanel extends StatefulWidget {
  const _FnPanel({
    required this.onItemTap,
  });

  final ValueChanged<_FnItem> onItemTap;

  @override
  State<_FnPanel> createState() => _FnPanelState();
}

class _FnPanelState extends State<_FnPanel> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int chunkSize = 8;
    final List<List<_FnItem>> pages = [];
    for (int i = 0; i < _fnItems.length; i += chunkSize) {
      pages.add(_fnItems.sublist(i, min(i + chunkSize, _fnItems.length)));
    }

    return Container(
      color: const Color(0xFFF7F7F7),
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const PageScrollPhysics(),
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() {
                  _pageIndex = index;
                });
              },
              itemBuilder: (context, pageIndex) {
                final items = pages[pageIndex];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: GridView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(24, 28, 24, 12), // HTML: padding: 28px 24px 12px
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 20, // HTML: row-gap: 20px
                        crossAxisSpacing: 10, // HTML: column-gap: 10px
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _FnCell(
                          item: item,
                          onTap: () => widget.onItemTap(item),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          if (pages.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (index) {
                  final bool active = index == _pageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: active ? 18 : 6,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0x59000000) // active: rgba(0,0,0,0.35)
                          : const Color(0x26000000), // normal: rgba(0,0,0,0.15)
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _FnCell extends StatelessWidget {
  const _FnCell({
    required this.item,
    required this.onTap,
  });

  final _FnItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x0D000000)), // rgba(0,0,0,0.05)
            ),
            child: Center(
              child: SvgPicture.asset(
                item.asset,
                width: 26,
                height: 26,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1D2129),
            ),
          ),
        ],
      ),
    );
  }
}

// Emoji 面板：最近使用 + 所有表情 + 删除按钮
class _EmojiPanel extends StatelessWidget {
  const _EmojiPanel({
    required this.recentEmojis,
    required this.onEmojiTap,
    required this.onEmojiDelete,
  });

  final List<String> recentEmojis;
  final ValueChanged<String> onEmojiTap;
  final VoidCallback onEmojiDelete;

  static const List<String> _allEmojis = [
    '😀', '😁', '😂', '🤣', '😊', '😍', '😘', '😚',
    '😎', '🤩', '😇', '🙂', '🙃', '😉', '😌', '😴',
    '😤', '🤔', '🤗', '🤭', '🥳', '😢', '😭', '😡',
    '🤯', '😱', '😳', '🤤', '😋', '😜', '🤪', '😏',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7F7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopIcons(),
          const SizedBox(height: 8),
          _buildHandleBar(),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recentEmojis.isNotEmpty) ...[
                    const Text(
                      '最近使用',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildEmojiWrap(recentEmojis),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    '所有表情',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildEmojiWrap(_allEmojis),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildDeleteRow(),
        ],
      ),
    );
  }

  Widget _buildTopIcons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildTopIcon(Icons.search, active: false),
          const SizedBox(width: 16),
          _buildTopIcon(Icons.emoji_emotions, active: true),
          const SizedBox(width: 16),
          _buildTopIcon(Icons.favorite_border, active: false),
          const SizedBox(width: 16),
          _buildTopIcon(Icons.back_hand, active: false),
        ],
      ),
    );
  }

  Widget _buildTopIcon(IconData icon, {required bool active}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 20,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildHandleBar() {
    return Center(
      child: Container(
        width: 80,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0x33000000),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildEmojiWrap(List<String> emojis) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: emojis
          .map(
            (e) => GestureDetector(
              onTap: () => onEmojiTap(e),
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Text(
                    e,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDeleteRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 12, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: onEmojiDelete,
          child: Container(
            width: 44,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE5E5E5), width: 0.5),
            ),
            child: const Center(
              child: Icon(
                Icons.backspace_outlined,
                size: 18,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
