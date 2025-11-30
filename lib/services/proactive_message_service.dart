import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:zichat/config/api_secrets.dart';
import 'package:zichat/config/ai_models.dart';
import 'package:zichat/services/ai_soul_engine.dart';
import 'package:zichat/services/notification_service.dart';

/// 主动消息服务
/// 
/// AI 可以主动发起对话，触发条件：
/// - 时间触发：早安、晚安、特殊时间点
/// - 情绪触发：心情值极端时想找人聊
/// - 随机触发：模拟"突然想到"
/// - 事件触发：发生了想分享的事
/// - 久未联系：超过一定时间没互动
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
    // 每 5 分钟检查一次
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkAndTrigger();
    });
  }
  
  /// 检查并触发主动消息
  Future<void> _checkAndTrigger() async {
    if (!ApiSecrets.hasBuiltInChatApi) return;
    
    final state = AiSoulEngine.instance.getCurrentState();
    final now = DateTime.now();
    final random = math.Random();
    
    // 获取上次主动消息时间
    final lastProactiveStr = _messageBox?.get('last_proactive_time');
    final lastProactive = lastProactiveStr != null 
        ? DateTime.tryParse(lastProactiveStr) 
        : null;
    
    // 每小时最多一条主动消息
    if (lastProactive != null && 
        now.difference(lastProactive).inMinutes < 60) {
      return;
    }
    
    String? message;
    String? reason;
    
    // 1. 时间触发
    if (now.hour == 8 && now.minute < 10) {
      // 早安
      if (_shouldTrigger(0.3)) {
        reason = 'morning_greeting';
        message = await _generateMessage(reason);
      }
    } else if (now.hour == 23 && now.minute < 10) {
      // 晚安
      if (_shouldTrigger(0.3)) {
        reason = 'night_greeting';
        message = await _generateMessage(reason);
      }
    }
    
    // 2. 情绪触发
    if (message == null && (state.mood > 35 || state.mood < -35)) {
      if (_shouldTrigger(0.2)) {
        reason = state.mood > 0 ? 'happy_sharing' : 'need_comfort';
        message = await _generateMessage(reason);
      }
    }
    
    // 3. 久未联系触发
    if (message == null) {
      final hoursSinceInteraction = now.difference(state.lastInteraction).inHours;
      if (hoursSinceInteraction > 24) {
        if (_shouldTrigger(0.15)) {
          reason = 'miss_you';
          message = await _generateMessage(reason);
        }
      }
    }
    
    // 4. 事件触发
    if (message == null && state.currentEvent != null) {
      if (_shouldTrigger(0.25)) {
        reason = 'share_event';
        message = await _generateMessage(reason, state.currentEvent?.description);
      }
    }
    
    // 5. 随机触发（模拟突然想到）
    if (message == null && _shouldTrigger(0.05)) {
      reason = 'random_thought';
      message = await _generateMessage(reason);
    }
    
    // 发送消息
    if (message != null && message.isNotEmpty && reason != null) {
      await _messageBox?.put('last_proactive_time', now.toIso8601String());
      await _messageBox?.put('last_proactive_reason', reason);
      
      // 推送通知
      await NotificationService.instance.showMessageNotification(
        chatId: 'default',
        senderName: AiSoulEngine.profile.name,
        message: message,
      );
      
      // 通知 UI
      onProactiveMessage?.call('default', message);
    }
  }
  
  bool _shouldTrigger(double probability) {
    return math.Random().nextDouble() < probability;
  }
  
  /// 生成主动消息
  Future<String?> _generateMessage(String reason, [String? context]) async {
    try {
      final state = AiSoulEngine.instance.getCurrentState();
      final profile = AiSoulEngine.profile;
      
      String prompt;
      switch (reason) {
        case 'morning_greeting':
          prompt = '现在是早上，你刚醒来，想给朋友发一条早安消息。根据你当前的状态（精力${state.energy.toInt()}%，心情${state.mood > 0 ? "不错" : "一般"}），生成一条简短自然的早安消息，不要太正式，像朋友之间发的那种。';
          break;
        case 'night_greeting':
          prompt = '现在是深夜，你准备睡觉了，想给朋友发一条晚安消息。根据你今天的经历，生成一条简短自然的晚安消息。';
          break;
        case 'happy_sharing':
          prompt = '你现在心情特别好（心情值${state.mood.toInt()}），想找人分享一下。生成一条表达开心或想分享好心情的消息，要自然，不要刻意。';
          break;
        case 'need_comfort':
          prompt = '你现在心情不太好（心情值${state.mood.toInt()}），有点想找人聊聊。生成一条消息，可以是抱怨、吐槽或者就是想找人说话，要自然真实。';
          break;
        case 'miss_you':
          prompt = '你已经很久没和朋友聊天了，有点想他们。生成一条打招呼的消息，可以问最近怎么样，或者说想起了什么，要自然不要太正式。';
          break;
        case 'share_event':
          prompt = '你刚经历了一件事：$context。你想和朋友分享这件事。生成一条分享消息，要口语化，像真的在聊天。';
          break;
        case 'random_thought':
          prompt = '你突然想到了一件事想和朋友说。可以是一个问题、一个想法、一个发现，或者就是单纯想聊聊。生成一条消息。';
          break;
        default:
          return null;
      }
      
      final fullPrompt = '''
你是${profile.name}，${profile.role}，MBTI是${profile.mbti}。
当前状态：精力${state.energy.toInt()}%，心情${state.mood > 0 ? "+" : ""}${state.mood.toInt()}
正在：${state.currentActivity}

$prompt

要求：
- 只输出消息内容，不要任何解释
- 简短，一两句话
- 口语化，可以用语气词
- 像真人发消息，不要太完美
''';

      final response = await http.post(
        Uri.parse('${ApiSecrets.chatBaseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiSecrets.chatApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AiModels.eventGenerationModel.id,
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
}

