import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/models/chat_message.dart';
import 'package:zichat/pages/chat_options_page.dart';
import 'package:zichat/pages/transfer_page.dart';
import 'package:zichat/services/ai_chat_service.dart';
import 'package:zichat/storage/chat_storage.dart';
import 'widgets/widgets.dart';

/// 聊天详情页 - 重构版本
/// 
/// 特性:
/// - SVG 预加载优化
/// - 完整的动画系统
/// - 触觉反馈
/// - 组件化架构
/// - 流畅的手势交互
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
  bool _aiRequesting = false;
  List<ChatMessage> _messages = [];
  final List<String> _recentEmojis = [];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
    _loadMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {});
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        if (animated) {
          _scrollController.animateTo(
            maxExtent,
            duration: AppStyles.animationNormal,
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(maxExtent);
        }
      }
    });
  }

  Future<void> _loadMessages() async {
    final List<Map<String, dynamic>> stored =
        await ChatStorage.loadMessages(widget.chatId);
    setState(() {
      _messages = stored.map(ChatMessage.fromMap).toList();
    });
    _scrollToBottom(animated: false);
  }

  Future<void> _saveMessages() async {
    final list = _messages.map((m) => m.toMap()).toList();
    await ChatStorage.saveMessages(widget.chatId, list);
  }

  void _toggleVoice() {
    HapticFeedback.selectionClick();
    setState(() {
      _voiceMode = !_voiceMode;
      _showEmoji = false;
      _showFn = false;
    });
  }

  void _toggleEmoji() {
    HapticFeedback.selectionClick();
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
    HapticFeedback.selectionClick();
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
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {
      _showFn = !_showFn;
      _showEmoji = false;
    });
    _scrollToBottom();
  }

  void _closePanels() {
    if (_showEmoji || _showFn) {
      setState(() {
        _showEmoji = false;
        _showFn = false;
      });
    }
  }

  bool get _hasText => _inputController.text.trim().isNotEmpty;

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _messages.add(ChatMessage.text(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        isOutgoing: true,
      ));
      _inputController.clear();
    });
    _saveMessages();
    _scrollToBottom();
  }

  List<Map<String, String>> _buildAiHistory() {
    final List<ChatMessage> textMessages = _messages
        .where((m) => m.type == 'text' && (m.text?.trim().isNotEmpty ?? false))
        .toList();
    if (textMessages.length <= 1) {
      return <Map<String, String>>[];
    }

    const int maxHistory = 10;
    final List<ChatMessage> historyMessages =
        textMessages.sublist(0, textMessages.length - 1);
    final int start = historyMessages.length > maxHistory
        ? historyMessages.length - maxHistory
        : 0;
    final List<ChatMessage> recent = historyMessages.sublist(start);

    final List<Map<String, String>> history = <Map<String, String>>[];
    for (final ChatMessage m in recent) {
      final String content = (m.text ?? '').trim();
      if (content.isEmpty) continue;
      final String role = m.direction == 'out' ? 'user' : 'assistant';
      history.add(<String, String>{
        'role': role,
        'content': content,
      });
    }
    return history;
  }

  Future<void> _sendByAi() async {
    final String text = _inputController.text.trim();
    if (text.isEmpty || _aiRequesting) return;

    _send();

    setState(() {
      _aiRequesting = true;
    });

    // 先显示"正在输入"状态
    final typingId = 'typing-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _messages.add(ChatMessage.system(
        id: typingId,
        text: '对方正在输入...',
      ));
    });
    _scrollToBottom();

    final buffer = StringBuffer();
    bool firstChunkReceived = false;
    final aiMessageId = 'ai-${DateTime.now().millisecondsSinceEpoch}';

    try {
      await for (final chunk in AiChatService.sendChatStream(
        chatId: widget.chatId,
        userInput: text,
      )) {
        if (!mounted) return;
        
        // 收到第一个字符时，移除"正在输入"，创建真正的消息
        if (!firstChunkReceived) {
          firstChunkReceived = true;
          setState(() {
            _messages.removeWhere((m) => m.id == typingId);
            _messages.add(ChatMessage.text(
              id: aiMessageId,
              text: '',
              isOutgoing: false,
            ));
          });
        }
        
        buffer.write(chunk);
        
        // 实时更新消息内容
        setState(() {
          final index = _messages.indexWhere((m) => m.id == aiMessageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
              text: buffer.toString(),
            );
          }
        });
        _scrollToBottom();
      }

      if (!mounted) return;
      
      // 流式完成后，按反斜线分句处理
      final fullText = buffer.toString();
      final parts = fullText
          .split('\\')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      setState(() {
        // 移除临时消息
        _messages.removeWhere((m) => m.id == aiMessageId);
        
        // 添加分句后的消息
        if (parts.isEmpty && fullText.trim().isNotEmpty) {
          _messages.add(ChatMessage.text(
            id: aiMessageId,
            text: fullText.trim(),
            isOutgoing: false,
          ));
        } else {
          for (int i = 0; i < parts.length; i++) {
            _messages.add(ChatMessage.text(
              id: '$aiMessageId-$i',
              text: parts[i],
              isOutgoing: false,
            ));
          }
        }
        _aiRequesting = false;
      });

      _saveMessages();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // 移除所有临时消息
        _messages.removeWhere((m) => m.id == typingId || m.id == aiMessageId);
        
        _messages.add(ChatMessage.system(
          id: 'sys-${DateTime.now().millisecondsSinceEpoch}',
          text: '出错了：$e',
        ));
        _aiRequesting = false;
      });
      _saveMessages();
      _scrollToBottom();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (file == null) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _messages.add(ChatMessage.image(
        id: 'img-${DateTime.now().millisecondsSinceEpoch}',
        imagePath: file.path,
        isOutgoing: true,
      ));
      _showFn = false;
    });
    _saveMessages();
    _scrollToBottom();
  }

  void _handleFnTap(FnItem item) {
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
            _messages.add(ChatMessage.transfer(
              id: 'tr-${DateTime.now().millisecondsSinceEpoch}',
              amount: amount.toStringAsFixed(2),
              isOutgoing: true,
            ));
          });
          _saveMessages();
          _scrollToBottom();
        });
        break;
      default:
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.label} 功能暂未开放'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        break;
    }
  }

  void _handleBack() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  Future<void> _handleMore() async {
    HapticFeedback.lightImpact();
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
  }

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
                // Header
                ChatHeader(
                  title: widget.title,
                  unread: widget.unread,
                  onBack: _handleBack,
                  onMore: _handleMore,
                ),
                  // Message List
                  Expanded(
                    child: GestureDetector(
                      onTap: _closePanels,
                      child: _MessageList(
                        scrollController: _scrollController,
                        messages: _messages,
                        isAiRequesting: _aiRequesting,
                      ),
                    ),
                  ),
                  // Toolbar
                  ChatToolbar(
                    controller: _inputController,
                    voiceMode: _voiceMode,
                    showEmoji: _showEmoji,
                    showFn: _showFn,
                    hasText: _hasText,
                    onVoiceToggle: _toggleVoice,
                    onEmojiToggle: _toggleEmoji,
                    onFnToggle: _toggleFn,
                    onSend: _send,
                    onSendByAi: _sendByAi,
                    onFocus: _closePanels,
                  ),
                  // Emoji Panel
                  AnimatedSize(
                    duration: AppStyles.animationNormal,
                    curve: Curves.easeOutCubic,
                    child: _showEmoji
                        ? SizedBox(
                            height: 280,
                            child: EmojiPanel(
                              recentEmojis: _recentEmojis,
                              onEmojiTap: _handleEmojiTap,
                              onEmojiDelete: _handleEmojiDelete,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  // Function Panel
                  AnimatedSize(
                    duration: AppStyles.animationNormal,
                    curve: Curves.easeOutCubic,
                    child: _showFn
                        ? SizedBox(
                            height: 220,
                            child: FnPanel(
                              onItemTap: _handleFnTap,
                            ),
                          )
                        : const SizedBox.shrink(),
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

/// 消息列表组件
class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.scrollController,
    required this.messages,
    required this.isAiRequesting,
  });

  final ScrollController scrollController;
  final List<ChatMessage> messages;
  final bool isAiRequesting;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundChat,
      child: ListView.builder(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        cacheExtent: 500,
        itemCount: messages.length,
        itemBuilder: (_, index) {
          final message = messages[index];
          // 只对最后几条消息使用动画
          final showAnimation = index >= messages.length - 3;
          return MessageItem(
            key: ValueKey(message.id),
            message: message,
            showAnimation: showAnimation,
          );
        },
      ),
    );
  }
}

