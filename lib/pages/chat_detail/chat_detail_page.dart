import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/models/chat_message.dart';
import 'package:zichat/pages/chat_options_page.dart';
import 'package:zichat/pages/transfer_page.dart';
import 'package:zichat/services/ai_chat_service.dart';
import 'package:zichat/services/ai_tools_service.dart';
import 'package:zichat/services/image_gen_service.dart';
import 'package:zichat/services/user_data_manager.dart';
import 'package:zichat/storage/ai_config_storage.dart';
import 'package:zichat/storage/chat_storage.dart';
import 'package:zichat/storage/chat_background_storage.dart';
import 'package:zichat/storage/friend_storage.dart';
import 'package:zichat/widgets/weui/weui.dart';
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
    this.pendingMessage,
    this.friendPrompt,
    this.avatar,
  });

  final String chatId;
  final String title;
  final int unread;
  final String? pendingMessage;
  final String? friendPrompt;
  final String? avatar;

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
  String? _backgroundPath;
  
  // 分页加载相关
  static const int _pageSize = 30;
  int _currentOffset = 0;
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;
  List<ChatMessage> _allMessages = [];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
    _scrollController.addListener(_onScroll);
    _loadMessages();
    _loadBackground();
  }

  String? _getFriendPrompt() {
    return FriendStorage.getFriend(widget.chatId)?.prompt ?? widget.friendPrompt;
  }

  void _loadBackground() {
    _backgroundPath = ChatBackgroundStorage.getBackground(widget.chatId);
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

  /// 滚动监听 - 上拉加载更多历史
  void _onScroll() {
    if (_scrollController.position.pixels <= 100 && 
        _hasMoreMessages && 
        !_isLoadingMore) {
      _loadMoreMessages();
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      final maxExtent = position.maxScrollExtent;
      final distance = (maxExtent - position.pixels).abs();
      if (distance < 1) return;

      try {
        // 新消息到来时保持“贴底”，避免频繁的滚动动画造成“跳动”
        if (!animated || distance < 240) {
          _scrollController.jumpTo(maxExtent);
          return;
        }
        _scrollController.animateTo(
          maxExtent,
          duration: AppStyles.animationNormal,
          curve: Curves.easeOutCubic,
        );
      } catch (_) {}
    });
  }

  Future<void> _loadMessages() async {
    final List<Map<String, dynamic>> stored =
        await ChatStorage.loadMessages(widget.chatId);
    
    _allMessages = stored.map(ChatMessage.fromMap).toList();
    
    // 初始只加载最近的消息
    final totalCount = _allMessages.length;
    final startIndex = (totalCount - _pageSize).clamp(0, totalCount);
    
    setState(() {
      _messages = _allMessages.sublist(startIndex);
      _currentOffset = startIndex;
      _hasMoreMessages = startIndex > 0;
    });
    
    // 处理主动消息
    if (widget.pendingMessage != null && widget.pendingMessage!.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        final newMsg = ChatMessage.text(
          id: 'proactive-${DateTime.now().millisecondsSinceEpoch}',
          text: widget.pendingMessage!,
          isOutgoing: false,
        );
        setState(() {
          _messages.add(newMsg);
          _allMessages.add(newMsg);
        });
        _saveMessages();
      }
    }

    // 同步上下文历史（支持返回/重启后继续保持对话连贯）
    AiChatService.syncHistoryFromChatMessages(widget.chatId, _allMessages);
    
    _scrollToBottom(animated: false);
  }

  /// 加载更多历史消息
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;
    
    setState(() => _isLoadingMore = true);
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    final loadCount = _pageSize;
    final startIndex = (_currentOffset - loadCount).clamp(0, _currentOffset);
    final moreMessages = _allMessages.sublist(startIndex, _currentOffset);
    
    if (mounted) {
      final oldOffset = _scrollController.offset;
      final oldMaxExtent = _scrollController.position.maxScrollExtent;
      
      setState(() {
        _messages.insertAll(0, moreMessages);
        _currentOffset = startIndex;
        _hasMoreMessages = startIndex > 0;
        _isLoadingMore = false;
      });
      
      // 恢复滚动位置
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final newMaxExtent = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(oldOffset + (newMaxExtent - oldMaxExtent));
        }
      });
    }
  }

  Future<void> _saveMessages() async {
    // 合并当前显示的消息到 _allMessages
    _syncAllMessages();
    
    final list = _allMessages.map((m) => m.toMap()).toList();
    await ChatStorage.saveMessages(widget.chatId, list);
    
    // 更新好友的最后消息
    if (_allMessages.isNotEmpty) {
      final lastTextMessage = _allMessages.lastWhere(
        (m) => m.type == 'text' && m.text != null && m.text!.isNotEmpty,
        orElse: () => _allMessages.last,
      );
      String lastMsg = lastTextMessage.text ?? '';
      if (lastTextMessage.type == 'image') lastMsg = '[图片]';
      if (lastTextMessage.type == 'transfer') lastMsg = '[转账]';
      if (lastTextMessage.type == 'voice') lastMsg = '[语音]';
      if (lastMsg.isNotEmpty) {
        await FriendStorage.updateLastMessage(widget.chatId, lastMsg);
      }
    }

    AiChatService.syncHistoryFromChatMessages(widget.chatId, _allMessages);
  }

  /// 同步当前消息到 _allMessages
  void _syncAllMessages() {
    // 如果有分页，_allMessages 的前部分 + _messages 的后部分
    if (_currentOffset > 0) {
      // 保留 _allMessages 前 _currentOffset 条，替换后面的
      final prefix = _allMessages.sublist(0, _currentOffset);
      _allMessages = [...prefix, ..._messages];
    } else {
      _allMessages = List.from(_messages);
    }
  }

  /// 处理转账状态变更（用户确认收款）
  void _handleTransferStatusChanged(String messageId, String newStatus) {
    setState(() {
      // 更新 _messages 中的转账状态
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(status: newStatus);
      }
      // 同时更新 _allMessages
      final allIndex = _allMessages.indexWhere((m) => m.id == messageId);
      if (allIndex != -1) {
        _allMessages[allIndex] = _allMessages[allIndex].copyWith(status: newStatus);
      }
    });
    _saveMessages();
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

  AiBaseModelsConfig _readBaseModelsFromHive() {
    try {
      final raw = Hive.box(AiConfigStorage.boxName).get('base_models');
      if (raw is Map) {
        return AiBaseModelsConfig.fromMap(raw) ?? const AiBaseModelsConfig();
      }
    } catch (_) {}
    return const AiBaseModelsConfig();
  }

  bool _canUploadImage(AiBaseModelsConfig base) {
    if (!base.hasChatModel) return false;
    if (base.chatModelSupportsImage) return true;
    return base.hasVisionModel && base.visionModelSupportsImage;
  }

  Future<bool> _ensureChatModelConfigured({bool showToast = true}) async {
    final base = await AiConfigStorage.loadBaseModelsConfig();
    if (base != null && base.hasChatModel) return true;
    if (showToast && mounted) {
      WeuiToast.show(context, message: '请先在“AI 设置-默认助手配置”配置对话模型');
    }
    return false;
  }

  Future<bool> _ensureCanUploadImage({bool showToast = true}) async {
    final base = await AiConfigStorage.loadBaseModelsConfig();
    if (base == null || !base.hasChatModel) {
      if (showToast && mounted) {
        WeuiToast.show(context, message: '请先在“AI 设置-默认助手配置”配置对话模型');
      }
      return false;
    }

    final ok =
        base.chatModelSupportsImage || (base.hasVisionModel && base.visionModelSupportsImage);
    if (!ok && showToast && mounted) {
      WeuiToast.show(
        context,
        message: '要发送图片，请选择支持识图的对话模型，或配置视觉模型',
      );
    }
    return ok;
  }

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

  Future<void> _sendByAi() async {
    final String text = _inputController.text.trim();
    if (text.isEmpty || _aiRequesting) return;

    if (!await _ensureChatModelConfigured()) return;

    _send();

    await _requestAiReply(userInput: text);
  }

  Future<void> _requestAiReply({String? userInput}) async {
    if (_aiRequesting) return;

    setState(() {
      _aiRequesting = true;
    });

    final buffer = StringBuffer();
    final aiMessageId = 'ai-${DateTime.now().millisecondsSinceEpoch}';

    try {
      // 流式响应期间不显示临时消息，只显示"正在输入"状态
      await for (final chunk in AiChatService.sendChatStream(
        chatId: widget.chatId,
        userInput: userInput,
        friendPrompt: _getFriendPrompt(),
        contextMessages: _allMessages,
      )) {
        if (!mounted) return;
        if (chunk.isEmpty) continue;
        buffer.write(chunk);
      }

      if (!mounted) return;

      final fullText = buffer.toString();

      debugPrint('AI raw response length: ${fullText.length}');

      // 如果原始内容为空
      if (fullText.isEmpty) {
        setState(() {
          _messages.add(ChatMessage.system(
            id: 'sys-${DateTime.now().millisecondsSinceEpoch}',
            text: '未收到 AI 回复，请检查网络或 API 配置',
          ));
          _aiRequesting = false;
        });
        _saveMessages();
        return;
      }

      // 过滤 thinking 标签内容
      final filteredText = _removeThinkingContent(fullText);

      // 如果过滤后没有内容
      if (filteredText.isEmpty) {
        final hasThinking = fullText.contains('<think') ||
            fullText.contains('<thinking') ||
            fullText.contains('【思考】');

        setState(() {
          if (hasThinking) {
            final rawContent = fullText
                .replaceAll(RegExp(r'</?think[^>]*>', caseSensitive: false), '')
                .replaceAll(
                  RegExp(r'</?thinking[^>]*>', caseSensitive: false),
                  '',
                )
                .replaceAll('【思考】', '')
                .replaceAll('【/思考】', '')
                .trim();
            if (rawContent.isNotEmpty) {
              _messages.add(ChatMessage.text(
                id: aiMessageId,
                text: rawContent,
                isOutgoing: false,
              ));
            } else {
              _messages.add(ChatMessage.system(
                id: 'sys-${DateTime.now().millisecondsSinceEpoch}',
                text: 'AI 思考完成但未生成回复，请重试',
              ));
            }
          } else {
            _messages.add(ChatMessage.system(
              id: 'sys-${DateTime.now().millisecondsSinceEpoch}',
              text: '收到空回复，请重试',
            ));
          }
          _aiRequesting = false;
        });
        _saveMessages();
        return;
      }

      // 解析工具调用
      final toolCalls = AiToolsService.parseToolCalls(filteredText);

      // 移除工具标记后的文本
      final cleanText = AiToolsService.removeToolMarkers(filteredText);

      final parts = AiChatService.splitReplyParts(cleanText);

      if (parts.isEmpty) {
        setState(() {
          _messages.add(ChatMessage.system(
            id: 'sys-${DateTime.now().millisecondsSinceEpoch}',
            text: '收到空回复，请重试',
          ));
          _aiRequesting = false;
        });
      } else if (parts.length == 1) {
        setState(() {
          _messages.add(ChatMessage.text(
            id: aiMessageId,
            text: parts.first,
            isOutgoing: false,
          ));
          _aiRequesting = false;
        });
        _scrollToBottom(animated: false);
      } else {
        for (int i = 0; i < parts.length; i++) {
          if (i > 0) {
            await Future.delayed(const Duration(milliseconds: 180));
          }
          if (!mounted) return;
          setState(() {
            _messages.add(ChatMessage.text(
              id: '$aiMessageId-$i',
              text: parts[i],
              isOutgoing: false,
            ));
            if (i == parts.length - 1) {
              _aiRequesting = false;
            }
          });
          _scrollToBottom(animated: false);
        }
      }

      // 处理工具调用
      await _processToolCalls(toolCalls, aiMessageId);

      _saveMessages();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
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

  /// 处理 AI 工具调用
  Future<void> _processToolCalls(List<AiToolCall> toolCalls, String baseId) async {
    if (toolCalls.isEmpty) return;
    
    final random = math.Random();
    int toolIndex = 0;
    
    for (final call in toolCalls) {
      // 每个工具调用之间有自然延迟
      await Future.delayed(Duration(milliseconds: 500 + random.nextInt(1000)));
      
      if (!mounted) return;
      
      switch (call.type) {
        case AiToolType.sendTransfer:
          // 发送转账
          final amount = call.params['amount'] as double? ?? 0;
          if (amount > 0) {
            setState(() {
              _messages.add(ChatMessage.transfer(
                id: '$baseId-tool-$toolIndex',
                amount: amount.toStringAsFixed(2),
                note: '给你的小惊喜',
                isOutgoing: false,
              ));
            });
          }
          break;
          
        case AiToolType.sendEmoji:
          // 发送表情（暂时用文字替代）
          final emoji = call.params['emoji'] as String? ?? '';
          if (emoji.isNotEmpty) {
            setState(() {
              _messages.add(ChatMessage.text(
                id: '$baseId-tool-$toolIndex',
                text: '[$emoji]',
                isOutgoing: false,
              ));
            });
          }
          break;
          
        case AiToolType.generateImage:
          // AI 生成图片
          final prompt = call.params['prompt'] as String? ?? '';
          if (prompt.isNotEmpty) {
            // 显示加载中提示
            final genMsgId = '$baseId-gen-$toolIndex';
            setState(() {
              _messages.add(ChatMessage.system(
                id: genMsgId,
                text: '图片加载中...',
              ));
            });
            _scrollToBottom();
            
            try {
              final base64Image = await ImageGenService.generateImage(prompt: prompt);
              if (base64Image != null && mounted) {
                // 保存图片到本地
                final imagePath = await _saveBase64Image(base64Image, genMsgId);
                
                setState(() {
                  // 移除生成中提示
                  _messages.removeWhere((m) => m.id == genMsgId);
                  // 添加图片消息
                  _messages.add(ChatMessage.image(
                    id: '$baseId-tool-$toolIndex',
                    imagePath: imagePath,
                    isOutgoing: false,
                  ));
                });
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  _messages.removeWhere((m) => m.id == genMsgId);
                  _messages.add(ChatMessage.system(
                    id: '$baseId-tool-$toolIndex',
                    text: '图片生成失败: $e',
                  ));
                });
              }
            }
          }
          break;
      }
      
      toolIndex++;
      _scrollToBottom();
    }
  }
  
  /// AI 领取用户转账并回复
  Future<void> _scheduleAiReceiveTransfer(String transferId, double amount) async {
    if (_aiRequesting) return;
    
    final random = math.Random();
    // 延迟 2-5 秒领取
    final delay = 2000 + random.nextInt(3000);
    await Future.delayed(Duration(milliseconds: delay));
    
    if (!mounted) return;
    
    // 更新转账状态为已领取
    setState(() {
      final index = _messages.indexWhere((m) => m.id == transferId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          status: '已收款',
        );
      }
    });
    _saveMessages();
    
    // 再等 0.5-2 秒后 AI 回复
    await Future.delayed(Duration(milliseconds: 500 + random.nextInt(1500)));
    
    if (!mounted || _aiRequesting) return;
    
    // 构造一条关于收到转账的上下文消息，让 AI 回复
    setState(() {
      _aiRequesting = true;
    });
    
    final aiMessageId = 'ai-${DateTime.now().millisecondsSinceEpoch}';
    final buffer = StringBuffer();
    bool firstChunkReceived = false;
    
    try {
      // 告诉 AI 收到了多少钱
      final transferContext = '【系统提示：对方刚刚给你转了 $amount 元，你已经收下了。请自然地表达感谢或反应。】';
      
      await for (final chunk in AiChatService.sendChatStream(
        chatId: widget.chatId,
        userInput: transferContext,
        friendPrompt: _getFriendPrompt(),
        contextMessages: _allMessages,
      )) {
        if (!mounted) return;
        if (chunk.isEmpty) continue;
        
        if (!firstChunkReceived) {
          firstChunkReceived = true;
          setState(() {
            _messages.add(ChatMessage.text(
              id: aiMessageId,
              text: '',
              isOutgoing: false,
            ));
          });
        }
        
        buffer.write(chunk);
        final displayText = _removeThinkingContent(buffer.toString());
        
        if (displayText.isNotEmpty) {
          setState(() {
            final index = _messages.indexWhere((m) => m.id == aiMessageId);
            if (index != -1) {
              _messages[index] = _messages[index].copyWith(text: displayText);
            }
          });
          _scrollToBottom();
        }
      }
      
      if (!mounted) return;
      
      final fullText = buffer.toString();
      final filteredText = _removeThinkingContent(fullText);
      
      if (filteredText.isEmpty) {
        // 如果 AI 没有回复，使用默认回复
        final defaultReplies = [
          '收到啦，谢谢！',
          '哇 谢谢你！',
          '收到收到~',
          '谢谢你的转账！',
        ];
        final reply = defaultReplies[random.nextInt(defaultReplies.length)];
        setState(() {
          _messages.removeWhere((m) => m.id == aiMessageId);
          _messages.add(ChatMessage.text(
            id: aiMessageId,
            text: reply,
            isOutgoing: false,
          ));
        });
      } else {
        // 清理文本
        final cleanText = AiToolsService.removeToolMarkers(filteredText);
        setState(() {
          _messages.removeWhere((m) => m.id == aiMessageId);
          _messages.add(ChatMessage.text(
            id: aiMessageId,
            text: cleanText.trim(),
            isOutgoing: false,
          ));
        });
      }
      
      setState(() => _aiRequesting = false);
      _saveMessages();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == aiMessageId);
        _messages.add(ChatMessage.text(
          id: aiMessageId,
          text: '收到啦，谢谢！',
          isOutgoing: false,
        ));
        _aiRequesting = false;
      });
      _saveMessages();
    }
  }
  
  /// 保存 base64 图片到本地文件
  Future<String> _saveBase64Image(String base64Data, String id) async {
    final bytes = base64Decode(base64Data);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/generated_$id.png');
    await file.writeAsBytes(bytes);
    return file.path;
  }
  

  /// 移除 thinking 标签及其内容
  String _removeThinkingContent(String text) {
    String result = text;
    
    // 移除 <think>...</think>（包括未闭合的）
    result = result.replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'<think>[\s\S]*$', caseSensitive: false), ''); // 未闭合的
    
    // 移除 <thinking>...</thinking>
    result = result.replaceAll(RegExp(r'<thinking>[\s\S]*?</thinking>', caseSensitive: false), '');
    result = result.replaceAll(RegExp(r'<thinking>[\s\S]*$', caseSensitive: false), '');
    
    // 移除中文格式的思考标签
    result = result.replaceAll(RegExp(r'【思考】[\s\S]*?【/思考】'), '');
    result = result.replaceAll(RegExp(r'【思考】[\s\S]*$'), '');
    
    // 清理多余的空行
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return result.trim();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!await _ensureCanUploadImage()) return;
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

    // 图片消息也触发一次 AI 回复（支持视觉模型回退）
    await _requestAiReply();
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
          final transferId = 'tr-${DateTime.now().millisecondsSinceEpoch}';
          setState(() {
            _messages.add(ChatMessage.transfer(
              id: transferId,
              amount: amount.toStringAsFixed(2),
              isOutgoing: true,
            ));
          });
          _saveMessages();
          _scrollToBottom();
          // AI 自动领取转账并回复
          _scheduleAiReceiveTransfer(transferId, amount);
        });
        break;
      default:
        HapticFeedback.lightImpact();
        WeuiToast.show(context, message: '${item.label} 功能暂未开放');
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
      AiChatService.clearHistory(widget.chatId);
      setState(() {
        _messages = [];
        _allMessages = [];
        _currentOffset = 0;
        _hasMoreMessages = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserDataManager.instance,
      builder: (context, _) {
        return ValueListenableBuilder(
          valueListenable: FriendStorage.listenable(),
          builder: (context, __, ___) {
            final friend = FriendStorage.getFriend(widget.chatId);
            final title = friend?.name ?? widget.title;
            final friendAvatar = friend?.avatar ?? widget.avatar;
            final myAvatar = UserDataManager.instance.profile.avatar;

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
                          title: title,
                          unread: widget.unread,
                          onBack: _handleBack,
                          onMore: _handleMore,
                          isTyping: _aiRequesting,
                        ),
                        // Message List
                        Expanded(
                          child: GestureDetector(
                            onTap: _closePanels,
                            child: _MessageList(
                              scrollController: _scrollController,
                              messages: _messages,
                              isAiRequesting: _aiRequesting,
                              friendAvatar: friendAvatar,
                              myAvatar: myAvatar,
                              backgroundPath: _backgroundPath,
                              hasMoreMessages: _hasMoreMessages,
                              isLoadingMore: _isLoadingMore,
                              onTransferStatusChanged: _handleTransferStatusChanged,
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
                                  child: ValueListenableBuilder<Box>(
                                    valueListenable: Hive.box(
                                      AiConfigStorage.boxName,
                                    ).listenable(
                                      keys: const ['base_models'],
                                    ),
                                    builder: (context, _, __) {
                                      final base = _readBaseModelsFromHive();
                                      final canSendImage = _canUploadImage(base);
                                      final items = defaultFnItems
                                          .map((item) => (item.label == '相册' ||
                                                  item.label == '拍摄')
                                              ? FnItem(
                                                  label: item.label,
                                                  asset: item.asset,
                                                  enabled: canSendImage,
                                                )
                                              : item)
                                          .toList();

                                      return FnPanel(
                                        items: items,
                                        onItemTap: _handleFnTap,
                                      );
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 消息列表组件
class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.scrollController,
    required this.messages,
    required this.isAiRequesting,
    this.friendAvatar,
    this.myAvatar,
    this.backgroundPath,
    this.hasMoreMessages = false,
    this.isLoadingMore = false,
    this.onTransferStatusChanged,
  });

  final ScrollController scrollController;
  final List<ChatMessage> messages;
  final bool isAiRequesting;
  final String? friendAvatar;
  final String? myAvatar;
  final String? backgroundPath;
  final bool hasMoreMessages;
  final bool isLoadingMore;
  final void Function(String messageId, String newStatus)? onTransferStatusChanged;

  Color _getBackgroundColor() {
    if (backgroundPath == null) return AppColors.backgroundChat;
    if (backgroundPath!.startsWith('color:')) {
      final colorValue = int.tryParse(backgroundPath!.substring(6));
      if (colorValue != null) return Color(colorValue);
    }
    return AppColors.backgroundChat;
  }

  @override
  Widget build(BuildContext context) {
    final hasImageBackground = backgroundPath != null && 
        !backgroundPath!.startsWith('color:') && 
        File(backgroundPath!).existsSync();

    // 计算实际显示的项数（可能包含加载指示器）
    final itemCount = messages.length + (hasMoreMessages || isLoadingMore ? 1 : 0);

    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        image: hasImageBackground
            ? DecorationImage(
                image: FileImage(File(backgroundPath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: ListView.builder(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        cacheExtent: 500,
        itemCount: itemCount,
        itemBuilder: (_, index) {
          // 第一项显示加载提示
          if (hasMoreMessages || isLoadingMore) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: isLoadingMore
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textHint,
                          ),
                        )
                      : const Text(
                          '上拉加载更多',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                ),
              );
            }
            // 调整实际消息的索引
            final messageIndex = index - 1;
            final message = messages[messageIndex];
            final showAnimation = messageIndex >= messages.length - 3;
            return MessageItem(
              key: ValueKey(message.id),
              message: message,
              showAnimation: showAnimation,
              friendAvatar: friendAvatar,
              myAvatar: myAvatar,
              onTransferStatusChanged: onTransferStatusChanged,
            );
          }
          
          final message = messages[index];
          // 只对最后几条消息使用动画
          final showAnimation = index >= messages.length - 3;
          return MessageItem(
            key: ValueKey(message.id),
            message: message,
            showAnimation: showAnimation,
            friendAvatar: friendAvatar,
            myAvatar: myAvatar,
            onTransferStatusChanged: onTransferStatusChanged,
          );
        },
      ),
    );
  }
}

