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
/// - 时间触发：早安、晚安、午休、下班等特殊时间点
/// - 情绪触发：心情值极端时想找人聊
/// - 随机触发：模拟"突然想到"
/// - 事件触发：发生了想分享的事
/// - 久未联系：超过一定时间没互动
/// - 天气/节日：特殊日子打招呼
class ProactiveMessageService {
  static final ProactiveMessageService _instance = ProactiveMessageService._internal();
  static ProactiveMessageService get instance => _instance;
  
  ProactiveMessageService._internal();
  
  Timer? _checkTimer;
  Box<String>? _messageBox;
  bool _initialized = false;
  
  // 回调函数，当有主动消息时通知 UI
  Function(String chatId, String message)? onProactiveMessage;
  
  // 用户活跃时间段（可学习）
  final List<int> _activeHours = [9, 10, 11, 14, 15, 16, 19, 20, 21, 22];
  
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
    // 每 3 分钟检查一次
    _checkTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _checkAndTrigger();
    });
  }
  
  /// 检查并触发主动消息
  Future<void> _checkAndTrigger() async {
    if (!ApiSecrets.hasBuiltInChatApi) return;
    
    final state = AiSoulEngine.instance.getCurrentState();
    final now = DateTime.now();
    
    // 获取上次主动消息时间
    final lastProactiveStr = _messageBox?.get('last_proactive_time');
    final lastProactive = lastProactiveStr != null 
        ? DateTime.tryParse(lastProactiveStr) 
        : null;
    
    // 计算最小间隔（根据亲密度调整）
    final minInterval = _calculateMinInterval(state);
    if (lastProactive != null && 
        now.difference(lastProactive).inMinutes < minInterval) {
      return;
    }
    
    // 检查是否在用户活跃时间
    if (!_isActiveTime(now)) {
      return;
    }
    
    String? message;
    String? reason;
    
    // 按优先级检查触发条件
    final trigger = _selectTrigger(state, now);
    if (trigger != null) {
      reason = trigger.reason;
      message = await _generateMessage(trigger.reason, trigger.context);
    }
    
    // 发送消息
    if (message != null && message.isNotEmpty && reason != null) {
      await _messageBox?.put('last_proactive_time', now.toIso8601String());
      await _messageBox?.put('last_proactive_reason', reason);
      
      // 记录触发次数（用于调整概率）
      _recordTrigger(reason);
      
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
  
  /// 计算最小消息间隔（分钟）
  int _calculateMinInterval(AiState state) {
    // 基础间隔 30 分钟
    int baseInterval = 30;
    
    // 情绪极端时缩短间隔
    if (state.mood.abs() > 30) {
      baseInterval = 20;
    }
    
    // 久未联系时缩短间隔
    final hoursSince = DateTime.now().difference(state.lastInteraction).inHours;
    if (hoursSince > 48) {
      baseInterval = 15;
    }
    
    return baseInterval;
  }
  
  /// 检查是否在活跃时间
  bool _isActiveTime(DateTime now) {
    // 避免深夜打扰 (23:00 - 7:00)
    if (now.hour >= 23 || now.hour < 7) {
      return false;
    }
    return true;
  }
  
  /// 选择触发条件
  _ProactiveTrigger? _selectTrigger(AiState state, DateTime now) {
    final triggers = <_ProactiveTrigger>[];
    
    // 1. 时间触发 - 更丰富的时间点
    if (now.hour == 8 && now.minute < 15) {
      triggers.add(_ProactiveTrigger('morning_greeting', 0.25));
    } else if (now.hour == 12 && now.minute >= 0 && now.minute < 15) {
      triggers.add(_ProactiveTrigger('lunch_greeting', 0.15));
    } else if (now.hour == 18 && now.minute >= 0 && now.minute < 15) {
      triggers.add(_ProactiveTrigger('evening_greeting', 0.15));
    } else if (now.hour == 22 && now.minute >= 30) {
      triggers.add(_ProactiveTrigger('night_greeting', 0.2));
    }
    
    // 2. 情绪触发 - 根据情绪强度调整概率
    if (state.mood > 35) {
      triggers.add(_ProactiveTrigger('happy_sharing', 0.15 + state.mood / 200));
    } else if (state.mood < -35) {
      triggers.add(_ProactiveTrigger('need_comfort', 0.15 + state.mood.abs() / 200));
    }
    
    // 3. 久未联系触发 - 根据时间递增概率
    final hoursSince = now.difference(state.lastInteraction).inHours;
    if (hoursSince > 12) {
      final probability = math.min(0.3, 0.05 + hoursSince * 0.01);
      triggers.add(_ProactiveTrigger('miss_you', probability));
    }
    
    // 4. 事件触发
    if (state.currentEvent != null) {
      triggers.add(_ProactiveTrigger(
        'share_event', 
        0.2, 
        state.currentEvent?.description,
      ));
    }
    
    // 5. 精力触发
    if (state.energy < 30) {
      triggers.add(_ProactiveTrigger('tired_chat', 0.1));
    } else if (state.energy > 80) {
      triggers.add(_ProactiveTrigger('energetic_chat', 0.1));
    }
    
    // 6. 随机触发
    triggers.add(_ProactiveTrigger('random_thought', 0.03));
    
    // 按概率随机选择
    for (final trigger in triggers) {
      if (_shouldTrigger(trigger.probability)) {
        return trigger;
      }
    }
    
    return null;
  }
  
  /// 记录触发（用于未来学习）
  void _recordTrigger(String reason) {
    final countKey = 'trigger_count_$reason';
    final count = int.tryParse(_messageBox?.get(countKey) ?? '0') ?? 0;
    _messageBox?.put(countKey, (count + 1).toString());
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
        case 'lunch_greeting':
          prompt = '现在是中午，你想问问朋友吃饭了没，或者分享一下你的午餐。生成一条简短消息。';
          break;
        case 'evening_greeting':
          prompt = '现在是傍晚下班时间，你想和朋友聊聊今天怎么样。生成一条简短问候。';
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
        case 'tired_chat':
          prompt = '你现在有点累（精力${state.energy.toInt()}%），想和朋友随便聊聊放松一下。生成一条简短消息。';
          break;
        case 'energetic_chat':
          prompt = '你现在精力充沛（精力${state.energy.toInt()}%），心情也不错，想找朋友聊天。生成一条积极的消息。';
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

/// 主动消息触发条件
class _ProactiveTrigger {
  final String reason;
  final double probability;
  final String? context;
  
  _ProactiveTrigger(this.reason, this.probability, [this.context]);
}

