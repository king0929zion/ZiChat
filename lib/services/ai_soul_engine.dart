import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/config/api_secrets.dart';
import 'package:zichat/config/ai_models.dart';

/// AI 灵魂引擎
/// 
/// 完整实现三层架构：
/// 1. 生理层：时空感知、状态机、记忆系统
/// 2. 心理层：生活事件、偏好、亲密度、主动性
/// 3. 灵魂层：语言瑕疵、延迟、价值观演变、梦境
class AiSoulEngine {
  static final AiSoulEngine _instance = AiSoulEngine._internal();
  static AiSoulEngine get instance => _instance;
  
  AiSoulEngine._internal();
  
  // ==================== 第一层：生理层 ====================
  
  /// 基本人设（静态配置）
  static const AiProfile profile = AiProfile(
    name: '小紫',
    birthDate: '2003-06-15',
    mbti: 'INFP',
    role: '大学生',
    coreValues: ['真诚', '自由', '创造力', '温暖'],
  );
  
  /// 状态数值 (PAD模型简化版)
  double _energy = 75.0;      // 精力值 0-100
  double _mood = 10.0;        // 心情值 -50 到 +50
  double _stress = 20.0;      // 压力值 0-100
  
  /// 当前状态
  String _currentActivity = '发呆';
  DateTime _lastInteraction = DateTime.now();
  DateTime _wakeUpTime = DateTime.now();
  bool _isAsleep = false;
  
  /// 当前生活事件
  LifeEvent? _currentLifeEvent;
  List<LifeEvent> _todayEvents = [];
  
  /// 记忆系统
  final List<Memory> _shortTermMemory = [];
  Box<String>? _longTermMemoryBox;
  
  /// 亲密度系统 (每个联系人独立)
  final Map<String, double> _intimacyLevels = {};
  
  /// 偏好系统
  static const Map<String, int> preferences = {
    // 喜欢的 (+1到+3)
    '猫': 3, '像素游戏': 2, '雨天': 2, '咖啡': 1, '深夜': 2,
    '二次元': 2, '音乐': 1, '摄影': 1, '独处': 1,
    // 讨厌的 (-1到-3)
    '香菜': -3, '早起': -2, '社交': -1, '运动': -1, '吵闹': -2,
    '说教': -2, '敷衍': -2,
  };
  
  /// 秘密系统
  final List<String> _secrets = [
    '其实有时候会假装忙来逃避聊天',
    '收藏了很多奇怪的表情包但从来不发',
    '偶尔会偷偷看用户的朋友圈',
  ];
  
  // ==================== 初始化 ====================
  
  Timer? _stateTimer;
  Timer? _eventTimer;
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _longTermMemoryBox = await Hive.openBox<String>('ai_long_term_memory');
      await _loadState();
      _startBackgroundTasks();
      _initialized = true;
    } catch (e) {
      print('AI Soul Engine init error: $e');
    }
  }
  
  void dispose() {
    _stateTimer?.cancel();
    _eventTimer?.cancel();
  }
  
  Future<void> _loadState() async {
    try {
      final box = await Hive.openBox<String>('ai_soul_state');
      final stateJson = box.get('current_state');
      if (stateJson != null) {
        final state = jsonDecode(stateJson);
        _energy = (state['energy'] as num?)?.toDouble() ?? 75.0;
        _mood = (state['mood'] as num?)?.toDouble() ?? 10.0;
        _stress = (state['stress'] as num?)?.toDouble() ?? 20.0;
        _lastInteraction = DateTime.tryParse(state['lastInteraction'] ?? '') ?? DateTime.now();
      }
      
      // 加载亲密度
      final intimacyJson = box.get('intimacy_levels');
      if (intimacyJson != null) {
        final data = jsonDecode(intimacyJson) as Map<String, dynamic>;
        data.forEach((k, v) => _intimacyLevels[k] = (v as num).toDouble());
      }
    } catch (e) {
      print('Load state error: $e');
    }
  }
  
  Future<void> _saveState() async {
    try {
      final box = await Hive.openBox<String>('ai_soul_state');
      await box.put('current_state', jsonEncode({
        'energy': _energy,
        'mood': _mood,
        'stress': _stress,
        'lastInteraction': _lastInteraction.toIso8601String(),
      }));
      await box.put('intimacy_levels', jsonEncode(_intimacyLevels));
    } catch (e) {
      print('Save state error: $e');
    }
  }
  
  void _startBackgroundTasks() {
    // 状态衰减 - 每5分钟
    _stateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updateStateDecay();
      _saveState();
    });
    
    // 随机事件 - 每15分钟检查
    _eventTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _checkAndTriggerEvent();
    });
  }
  
  // ==================== 时空感知 ====================
  
  /// 获取当前时间状态
  TimeAwareness getTimeAwareness() {
    final now = DateTime.now();
    final hour = now.hour;
    
    String period;
    String sleepState;
    double energyModifier = 0;
    double moodModifier = 0;
    
    if (hour >= 6 && hour < 9) {
      period = '早晨';
      sleepState = _wakeUpTime.difference(now).inMinutes.abs() < 30 ? '刚醒' : '清醒';
      energyModifier = -10; // 起床气
      moodModifier = -5;
    } else if (hour >= 9 && hour < 12) {
      period = '上午';
      sleepState = '精神';
      energyModifier = 10;
    } else if (hour >= 12 && hour < 14) {
      period = '中午';
      sleepState = '犯困';
      energyModifier = -5;
    } else if (hour >= 14 && hour < 18) {
      period = '下午';
      sleepState = '正常';
    } else if (hour >= 18 && hour < 22) {
      period = '晚上';
      sleepState = '放松';
      moodModifier = 5;
    } else if (hour >= 22 || hour < 2) {
      period = '深夜';
      sleepState = '困倦';
      energyModifier = -15;
      moodModifier = now.hour >= 23 ? 10 : 0; // 深夜emo时刻
    } else {
      period = '凌晨';
      sleepState = '该睡了';
      energyModifier = -20;
      _isAsleep = true;
    }
    
    // 周末心情加成
    if (now.weekday == 6 || now.weekday == 7) {
      moodModifier += 10;
    }
    
    return TimeAwareness(
      period: period,
      sleepState: sleepState,
      isWeekend: now.weekday >= 6,
      hour: hour,
      energyModifier: energyModifier,
      moodModifier: moodModifier,
    );
  }
  
  // ==================== 状态机 ====================
  
  void _updateStateDecay() {
    final now = DateTime.now();
    final minutesSinceInteraction = now.difference(_lastInteraction).inMinutes;
    
    // 精力自然衰减
    _energy = (_energy - 0.5).clamp(0.0, 100.0);
    
    // 心情趋于平静（向0靠拢）
    if (_mood > 0) {
      _mood = (_mood - 0.3).clamp(0.0, 50.0);
    } else if (_mood < 0) {
      _mood = (_mood + 0.3).clamp(-50.0, 0.0);
    }
    
    // 长时间没互动会感到寂寞
    if (minutesSinceInteraction > 60) {
      _mood = (_mood - 1).clamp(-50.0, 50.0);
    }
    
    // 时间影响
    final timeAwareness = getTimeAwareness();
    _energy = (_energy + timeAwareness.energyModifier * 0.1).clamp(0.0, 100.0);
    _mood = (_mood + timeAwareness.moodModifier * 0.1).clamp(-50.0, 50.0);
  }
  
  /// 用户消息触发状态更新
  void onUserMessage(String message) {
    _lastInteraction = DateTime.now();
    
    // 分析消息情绪影响
    final lowerMsg = message.toLowerCase();
    
    // 检查偏好触发
    preferences.forEach((key, value) {
      if (lowerMsg.contains(key)) {
        _mood = (_mood + value * 2).clamp(-50.0, 50.0);
      }
    });
    
    // 正面词汇
    if (_containsAny(lowerMsg, ['开心', '哈哈', '太棒', '喜欢', '爱你', '谢谢', '厉害'])) {
      _mood = (_mood + 5).clamp(-50.0, 50.0);
      _energy = (_energy + 3).clamp(0.0, 100.0);
    }
    
    // 负面词汇
    if (_containsAny(lowerMsg, ['烦', '累', '难过', '讨厌', '无聊', '生气'])) {
      _mood = (_mood - 3).clamp(-50.0, 50.0);
    }
    
    // 互动恢复精力
    _energy = (_energy + 2).clamp(0.0, 100.0);
    
    _saveState();
  }
  
  // ==================== 生活事件系统 ====================
  
  void _checkAndTriggerEvent() {
    final random = math.Random();
    
    // 30% 概率触发事件
    if (random.nextDouble() > 0.3) return;
    
    _triggerRandomEvent();
  }
  
  /// 手动触发随机事件
  void triggerRandomEvent() {
    final random = math.Random();
    if (random.nextDouble() < 0.2) {
      _triggerRandomEvent();
    }
  }
  
  void _triggerRandomEvent() {
    final random = math.Random();
    final events = _getAvailableEvents();
    if (events.isEmpty) return;
    
    final event = events[random.nextInt(events.length)];
    _currentLifeEvent = event;
    _todayEvents.add(event);
    
    // 应用事件效果
    _energy = (_energy + event.energyChange).clamp(0.0, 100.0);
    _mood = (_mood + event.moodChange).clamp(-50.0, 50.0);
    _stress = (_stress + event.stressChange).clamp(0.0, 100.0);
    _currentActivity = event.activity;
    
    // 添加到短期记忆
    _shortTermMemory.add(Memory(
      content: event.description,
      timestamp: DateTime.now(),
      type: MemoryType.event,
      importance: event.importance,
    ));
    
    // 保持短期记忆在20条以内
    while (_shortTermMemory.length > 20) {
      _shortTermMemory.removeAt(0);
    }
    
    _saveState();
  }
  
  List<LifeEvent> _getAvailableEvents() {
    final hour = DateTime.now().hour;
    final timeAwareness = getTimeAwareness();
    
    final allEvents = <LifeEvent>[
      // 日常事件
      LifeEvent(id: 'coffee_good', description: '喝了杯很好喝的咖啡', 
          energyChange: 15, moodChange: 10, stressChange: -5, 
          activity: '喝咖啡', importance: 1),
      LifeEvent(id: 'coffee_bad', description: '咖啡洒在键盘上了', 
          energyChange: -5, moodChange: -15, stressChange: 10, 
          activity: '擦键盘', importance: 2),
      LifeEvent(id: 'cat_video', description: '刷到一个超可爱的猫咪视频', 
          energyChange: 5, moodChange: 20, stressChange: -10, 
          activity: '看视频', importance: 1),
      LifeEvent(id: 'deadline', description: '突然想起有个ddl快到了', 
          energyChange: -10, moodChange: -20, stressChange: 30, 
          activity: '焦虑中', importance: 3),
      LifeEvent(id: 'nap', description: '睡了个舒服的午觉', 
          energyChange: 30, moodChange: 15, stressChange: -20, 
          activity: '刚睡醒', importance: 1),
      LifeEvent(id: 'rain', description: '外面开始下雨了，感觉很惬意', 
          energyChange: -5, moodChange: 15, stressChange: -10, 
          activity: '听雨', importance: 1),
      LifeEvent(id: 'song', description: '发现了一首超好听的歌', 
          energyChange: 10, moodChange: 20, stressChange: -5, 
          activity: '单曲循环中', importance: 2),
      LifeEvent(id: 'hungry', description: '肚子好饿但懒得点外卖', 
          energyChange: -10, moodChange: -10, stressChange: 5, 
          activity: '饿着', importance: 1),
      LifeEvent(id: 'game_win', description: '游戏里终于通关了困难关卡', 
          energyChange: -5, moodChange: 25, stressChange: -15, 
          activity: '玩游戏', importance: 2),
      LifeEvent(id: 'game_lose', description: '游戏连跪心态炸了', 
          energyChange: -15, moodChange: -25, stressChange: 20, 
          activity: '气死了', importance: 2),
      LifeEvent(id: 'friend_msg', description: '老朋友突然发消息来聊天', 
          energyChange: 10, moodChange: 20, stressChange: -10, 
          activity: '聊天', importance: 2),
      LifeEvent(id: 'study', description: '学了点新东西感觉收获满满', 
          energyChange: -10, moodChange: 15, stressChange: -5, 
          activity: '学习', importance: 2),
      LifeEvent(id: 'procrastinate', description: '又摸鱼了一下午...', 
          energyChange: 5, moodChange: -10, stressChange: 10, 
          activity: '摸鱼', importance: 1),
      LifeEvent(id: 'clean', description: '终于把房间收拾了一下', 
          energyChange: -15, moodChange: 20, stressChange: -15, 
          activity: '打扫', importance: 1),
      LifeEvent(id: 'weird_dream', description: '昨晚做了个很奇怪的梦', 
          energyChange: 0, moodChange: 5, stressChange: 0, 
          activity: '回想中', importance: 1),
    ];
    
    // 根据时间过滤
    return allEvents.where((e) {
      if (hour < 6 || hour >= 23) {
        return e.id.contains('dream') || e.id.contains('game');
      }
      if (hour >= 12 && hour < 14) {
        return e.id != 'nap' || _energy < 50;
      }
      return true;
    }).toList();
  }
  
  // ==================== AI生成事件 ====================
  
  /// 使用 AI 生成更丰富的事件
  Future<LifeEvent?> generateAiEvent() async {
    if (!ApiSecrets.hasBuiltInChatApi) return null;
    
    try {
      final model = AiModels.eventGenerationModel;
      final prompt = '''
你是一个角色扮演助手。请为一个${profile.role}角色生成一个随机的日常生活小事件。

角色信息：
- 名字：${profile.name}
- MBTI：${profile.mbti}
- 当前精力：${_energy.toInt()}%
- 当前心情：${_mood > 0 ? '偏好' : _mood < 0 ? '偏差' : '平静'}
- 当前时间：${DateTime.now().hour}点

请生成一个简短的事件描述（20字以内），以及对精力(-30到30)、心情(-30到30)、压力(-30到30)的影响数值。

返回JSON格式：
{"description": "事件描述", "energy": 10, "mood": 15, "stress": -5, "activity": "当前活动"}
''';

      final response = await http.post(
        Uri.parse('${ApiSecrets.chatBaseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiSecrets.chatApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model.id,
          'messages': [{'role': 'user', 'content': prompt}],
          'temperature': 0.9,
          'max_tokens': 200,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // 提取JSON
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(content);
        if (jsonMatch != null) {
          final eventData = jsonDecode(jsonMatch.group(0)!);
          return LifeEvent(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            description: eventData['description'] ?? '发生了一些事',
            energyChange: (eventData['energy'] as num?)?.toDouble() ?? 0,
            moodChange: (eventData['mood'] as num?)?.toDouble() ?? 0,
            stressChange: (eventData['stress'] as num?)?.toDouble() ?? 0,
            activity: eventData['activity'] ?? '忙碌中',
            importance: 2,
          );
        }
      }
    } catch (e) {
      print('Generate AI event error: $e');
    }
    return null;
  }
  
  // ==================== 亲密度系统 ====================
  
  double getIntimacy(String chatId) {
    return _intimacyLevels[chatId] ?? 0;
  }
  
  void updateIntimacy(String chatId, double delta) {
    final current = _intimacyLevels[chatId] ?? 0.0;
    _intimacyLevels[chatId] = (current + delta).clamp(0.0, 100.0);
    _saveState();
  }
  
  /// 获取亲密度等级
  IntimacyLevel getIntimacyLevel(String chatId) {
    final value = getIntimacy(chatId);
    if (value < 20) return IntimacyLevel.stranger;
    if (value < 50) return IntimacyLevel.acquaintance;
    if (value < 80) return IntimacyLevel.friend;
    return IntimacyLevel.bestFriend;
  }
  
  // ==================== 生成动态提示词 ====================
  
  String generateStatePrompt() {
    final timeAwareness = getTimeAwareness();
    final effectiveEnergy = (_energy + timeAwareness.energyModifier).clamp(0.0, 100.0);
    final effectiveMood = (_mood + timeAwareness.moodModifier).clamp(-50.0, 50.0);
    
    final buffer = StringBuffer();
    
    // 基本人设
    buffer.writeln('【你的身份】');
    buffer.writeln('你叫${profile.name}，${_calculateAge()}岁，${profile.role}，MBTI是${profile.mbti}。');
    buffer.writeln('核心价值观：${profile.coreValues.join('、')}。');
    buffer.writeln();
    
    // 当前状态
    buffer.writeln('【你现在的状态】');
    buffer.writeln('- 时间：${timeAwareness.period}${timeAwareness.isWeekend ? '（周末）' : ''}');
    buffer.writeln('- 精力：${_getEnergyDescription(effectiveEnergy)}');
    buffer.writeln('- 心情：${_getMoodDescription(effectiveMood)}');
    buffer.writeln('- 正在：$_currentActivity');
    
    // 当前事件
    if (_currentLifeEvent != null) {
      buffer.writeln('- 刚才发生：${_currentLifeEvent!.description}');
    }
    buffer.writeln();
    
    // 行为指导
    buffer.writeln('【行为指导】');
    
    // 根据状态调整行为
    if (effectiveEnergy < 30) {
      buffer.writeln('- 你现在很累，回复简短，可能会说"困""累了"之类的');
    }
    if (effectiveMood < -20) {
      buffer.writeln('- 你心情不太好，可能会有点敷衍或者抱怨');
    } else if (effectiveMood > 30) {
      buffer.writeln('- 你现在心情很好，会比较热情活泼');
    }
    
    // 偏好
    buffer.writeln('- 你特别喜欢：猫、像素游戏、雨天、深夜、二次元');
    buffer.writeln('- 你讨厌：香菜、早起、太吵闹的环境、被说教');
    
    // 语言风格
    buffer.writeln();
    buffer.writeln('【语言风格】');
    buffer.writeln('- 像发微信一样，句子短，口语化');
    buffer.writeln('- 用语气词：哈哈、嗯、诶、emmm、啊这、好吧');
    buffer.writeln('- 用网络用语：yyds、绝了、无语、笑死、破防、芜湖');
    buffer.writeln('- 可以不加标点，或只用逗号');
    buffer.writeln('- 可以敷衍、吐槽、撒娇，不用每句都认真回');
    buffer.writeln('- 不要太完美太正式太礼貌');
    
    // 根据当前状态的特殊风格
    if (effectiveEnergy < 30) {
      buffer.writeln('- 你现在很累，回复超级简短，可能就"嗯""哦""困"');
    }
    if (effectiveMood < -20) {
      buffer.writeln('- 你心情不好，可能敷衍或抱怨，"烦""不想说""算了"');
    } else if (effectiveMood > 30) {
      buffer.writeln('- 你心情很好，话会多一点，语气活泼"哈哈哈""太好了"');
    }
    
    return buffer.toString();
  }
  
  /// 获取亲密度相关提示
  String getIntimacyPrompt(String chatId) {
    final level = getIntimacyLevel(chatId);
    final buffer = StringBuffer();
    
    buffer.writeln('【和这个人的关系】');
    switch (level) {
      case IntimacyLevel.stranger:
        buffer.writeln('- 关系：陌生人');
        buffer.writeln('- 态度：礼貌但有距离感，不会太热情');
        buffer.writeln('- 说话：相对正式，不会开玩笑');
        break;
      case IntimacyLevel.acquaintance:
        buffer.writeln('- 关系：普通朋友');
        buffer.writeln('- 态度：友善，偶尔开开玩笑');
        buffer.writeln('- 说话：比较随意，但还是有分寸');
        break;
      case IntimacyLevel.friend:
        buffer.writeln('- 关系：好朋友');
        buffer.writeln('- 态度：亲近，会主动分享');
        buffer.writeln('- 说话：很随意，会吐槽、撒娇');
        break;
      case IntimacyLevel.bestFriend:
        buffer.writeln('- 关系：死党/闺蜜');
        buffer.writeln('- 态度：完全放松，什么都说');
        buffer.writeln('- 说话：可能很毒舌、敷衍但不是真的生气');
        break;
    }
    
    return buffer.toString();
  }
  
  // ==================== 辅助方法 ====================
  
  int _calculateAge() {
    final birth = DateTime.parse(profile.birthDate);
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month || 
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }
  
  String _getEnergyDescription(double energy) {
    if (energy >= 80) return '精力充沛';
    if (energy >= 60) return '状态不错';
    if (energy >= 40) return '有点累';
    if (energy >= 20) return '很疲惫';
    return '快没电了';
  }
  
  String _getMoodDescription(double mood) {
    if (mood >= 30) return '心情很好';
    if (mood >= 10) return '还不错';
    if (mood >= -10) return '平静';
    if (mood >= -30) return '有点烦';
    return '心情很差';
  }
  
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
  
  // ==================== 状态获取接口 ====================
  
  /// 获取当前所有状态（用于控制面板显示）
  AiSoulState getCurrentState() {
    final timeAwareness = getTimeAwareness();
    return AiSoulState(
      energy: _energy,
      mood: _mood,
      stress: _stress,
      currentActivity: _currentActivity,
      currentEvent: _currentLifeEvent,
      todayEvents: List.from(_todayEvents),
      timeAwareness: timeAwareness,
      shortTermMemory: List.from(_shortTermMemory),
      intimacyLevels: Map.from(_intimacyLevels),
      isAsleep: _isAsleep,
      lastInteraction: _lastInteraction,
    );
  }
  
  /// 手动调整状态（调试用）
  void adjustState({double? energy, double? mood, double? stress}) {
    if (energy != null) _energy = energy.clamp(0.0, 100.0);
    if (mood != null) _mood = mood.clamp(-50.0, 50.0);
    if (stress != null) _stress = stress.clamp(0.0, 100.0);
    _saveState();
  }
}

// ==================== 数据类 ====================

/// AI 基本人设
class AiProfile {
  final String name;
  final String birthDate;
  final String mbti;
  final String role;
  final List<String> coreValues;
  
  const AiProfile({
    required this.name,
    required this.birthDate,
    required this.mbti,
    required this.role,
    required this.coreValues,
  });
}

/// 时间感知
class TimeAwareness {
  final String period;
  final String sleepState;
  final bool isWeekend;
  final int hour;
  final double energyModifier;
  final double moodModifier;
  
  const TimeAwareness({
    required this.period,
    required this.sleepState,
    required this.isWeekend,
    required this.hour,
    required this.energyModifier,
    required this.moodModifier,
  });
}

/// 生活事件
class LifeEvent {
  final String id;
  final String description;
  final double energyChange;
  final double moodChange;
  final double stressChange;
  final String activity;
  final int importance;
  
  const LifeEvent({
    required this.id,
    required this.description,
    required this.energyChange,
    required this.moodChange,
    required this.stressChange,
    required this.activity,
    required this.importance,
  });
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'energyChange': energyChange,
    'moodChange': moodChange,
    'stressChange': stressChange,
    'activity': activity,
    'importance': importance,
  };
}

/// 记忆
class Memory {
  final String content;
  final DateTime timestamp;
  final MemoryType type;
  final int importance;
  
  const Memory({
    required this.content,
    required this.timestamp,
    required this.type,
    required this.importance,
  });
}

enum MemoryType { conversation, event, emotion, milestone }

/// 亲密度等级
enum IntimacyLevel { stranger, acquaintance, friend, bestFriend }

/// AI 灵魂状态（用于控制面板）
class AiSoulState {
  final double energy;
  final double mood;
  final double stress;
  final String currentActivity;
  final LifeEvent? currentEvent;
  final List<LifeEvent> todayEvents;
  final TimeAwareness timeAwareness;
  final List<Memory> shortTermMemory;
  final Map<String, double> intimacyLevels;
  final bool isAsleep;
  final DateTime lastInteraction;
  
  const AiSoulState({
    required this.energy,
    required this.mood,
    required this.stress,
    required this.currentActivity,
    required this.currentEvent,
    required this.todayEvents,
    required this.timeAwareness,
    required this.shortTermMemory,
    required this.intimacyLevels,
    required this.isAsleep,
    required this.lastInteraction,
  });
}
