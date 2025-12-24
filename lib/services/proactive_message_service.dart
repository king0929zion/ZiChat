import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:zichat/models/api_config.dart';
import 'package:zichat/services/notification_service.dart';
import 'package:zichat/storage/api_config_storage.dart';

/// 主动消息服务（简化版）
///
/// AI 可以根据时间随机主动发起对话
class ProactiveMessageService {
  static final ProactiveMessageService _instance = ProactiveMessageService._internal();
  static ProactiveMessageService get instance => _instance;

  ProactiveMessageService._internal();

  Timer? _checkTimer;
  Box<String>? _messageBox;
  bool _initialized = false;

  // 回调函数，当有主动消息时通知 UI
  Function(String chatId, String message)? onProactiveMessage;

  /// 初始化
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _messageBox = await Hive.openBox<String>('proactive_messages');
      _startChecking();
      _initialized = true;
    } catch (e) {
      debugPrint('ProactiveMessageService init error: $e');
    }
  }

  void dispose() {
    _checkTimer?.cancel();
  }

  /// 开始定时检查
  void _startChecking() {
    // 每 30 分钟检查一次
    _checkTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _checkAndTrigger();
    });
  }

  /// 检查并触发主动消息
  Future<void> _checkAndTrigger() async {
    // 检查是否有配置的 API
    final config = ApiConfigStorage.getActiveConfig();
    if (config == null || config.models.isEmpty) {
      return; // 没有配置 API，不触发
    }

    final now = DateTime.now();

    // 获取上次主动消息时间
    final lastProactiveStr = _messageBox?.get('last_proactive_time');
    final lastProactive = lastProactiveStr != null
        ? DateTime.tryParse(lastProactiveStr)
        : null;

    // 最小间隔 2 小时
    const minIntervalHours = 2;
    if (lastProactive != null &&
        now.difference(lastProactive).inHours < minIntervalHours) {
      return;
    }

    // 检查是否在活跃时间（避免深夜打扰）
    if (!_isActiveTime(now)) {
      return;
    }

    // 10% 概率触发
    if (math.Random().nextDouble() > 0.1) {
      return;
    }

    // 生成消息
    final message = await _generateRandomMessage(config);

    // 发送消息
    if (message != null && message.isNotEmpty) {
      await _messageBox?.put('last_proactive_time', now.toIso8601String());

      // 推送通知
      await NotificationService.instance.showMessageNotification(
        chatId: 'default',
        senderName: 'AI 助手',
        message: message,
      );

      // 通知 UI
      onProactiveMessage?.call('default', message);
    }
  }

  /// 检查是否在活跃时间
  bool _isActiveTime(DateTime now) {
    // 避免深夜打扰 (23:00 - 8:00)
    if (now.hour >= 23 || now.hour < 8) {
      return false;
    }
    return true;
  }

  /// 生成随机主动消息
  Future<String?> _generateRandomMessage(ApiConfig config) async {
    try {
      final prompts = [
        '突然想到你了，发条消息看看你在干嘛。生成一条简短的打招呼消息。',
        '刚才刷到个有意思的东西，想找人聊聊。生成一条简短消息。',
        '有点无聊，想找个朋友说说话。生成一条简短消息。',
        '刚才遇到一件事，突然想问你个问题。生成一条简短的好奇消息。',
        '最近怎么样，好久没聊了。生成一条简短问候消息。',
      ];

      final prompt = prompts[math.Random().nextInt(prompts.length)];

      final fullPrompt = '''
你是 AI 聊天助手，风格幽默、毒舌、逻辑鬼才。
$prompt

要求：
- 只输出消息内容，不要任何解释
- 简短，一两句话
- 口语化，像真人发消息
- 用 || 分隔多条消息
''';

      // 使用配置的第一个模型
      final model = config.models.first;
      final uri = _joinUri(config.baseUrl, 'chat/completions');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': [{'role': 'user', 'content': fullPrompt}],
          'temperature': 0.9,
          'max_tokens': 100,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;
        return content?.trim();
      }
    } catch (e) {
      debugPrint('Generate proactive message error: $e');
    }
    return null;
  }

  /// 获取待发送的主动消息（供 UI 调用）
  Future<String?> getPendingMessage(String chatId) async {
    final key = 'pending_$chatId';
    final message = _messageBox?.get(key);
    if (message != null) {
      await _messageBox?.delete(key);
    }
    return message;
  }

  /// 手动触发检查（测试用）
  Future<void> forceCheck() async {
    await _checkAndTrigger();
  }

  static Uri _joinUri(String base, String path) {
    if (base.endsWith('/')) {
      return Uri.parse('$base$path');
    }
    return Uri.parse('$base/$path');
  }
}

