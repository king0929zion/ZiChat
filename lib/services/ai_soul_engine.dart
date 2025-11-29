import 'dart:async';
import 'dart:math' as math;
import 'package:hive/hive.dart';

/// AI 灵魂引擎 - 让 AI 像生物一样"活着"
/// 
/// 包含：
/// - 状态机系统（精力值 Energy + 心情值 Mood）
/// - 时空感知（作息状态、时间感知）
/// - 生活事件模拟器
/// - 主动分享系统
class AiSoulEngine {
  static final _random = math.Random();
  static Box<dynamic>? _box;
  
  // ============ 状态值 ============
  
  /// 精力值 (0-100)，影响回复的积极性
  static double _energy = 70.0;
  
  /// 心情值 (-50 到 +50)，影响回复的情绪色彩
  static double _mood = 10.0;
  
  /// 最后更新时间
  static DateTime _lastUpdate = DateTime.now();
  
  /// 今日发生的事件
  static final List<LifeEvent> _todayEvents = [];
  
  // ============ 初始化 ============
  
  static Future<void> init() async {
    _box = Hive.box<dynamic>('ai_config');
    await _loadState();
    _startDecayTimer();
  }
  
  static Future<void> _loadState() async {
    final data = _box?.get('soul_state');
    if (data is Map) {
      _energy = (data['energy'] as num?)?.toDouble() ?? 70.0;
      _mood = (data['mood'] as num?)?.toDouble() ?? 10.0;
      _lastUpdate = DateTime.tryParse(data['lastUpdate'] ?? '') ?? DateTime.now();
    }
    // 计算离线期间的衰减
    _applyOfflineDecay();
  }
  
  static Future<void> _saveState() async {
    await _box?.put('soul_state', {
      'energy': _energy,
      'mood': _mood,
      'lastUpdate': DateTime.now().toIso8601String(),
    });
  }
  
  /// 应用离线期间的状态衰减
  static void _applyOfflineDecay() {
    final now = DateTime.now();
    final hoursPassed = now.difference(_lastUpdate).inMinutes / 60.0;
    
    // 精力随时间恢复（睡觉）或消耗
    final hour = now.hour;
    if (hour >= 23 || hour < 7) {
      // 深夜/凌晨：精力恢复
      _energy = math.min(100, _energy + hoursPassed * 5);
    } else {
      // 白天：精力缓慢消耗
      _energy = math.max(20, _energy - hoursPassed * 2);
    }
    
    // 心情趋于平静（向0靠拢）
    _mood = _mood * math.pow(0.95, hoursPassed);
    
    _lastUpdate = now;
  }
  
  /// 启动状态衰减定时器
  static void _startDecayTimer() {
    Timer.periodic(const Duration(minutes: 5), (_) {
      // 精力缓慢消耗
      _energy = math.max(15, _energy - 0.5);
      // 心情趋于平静
      _mood = _mood * 0.98;
      _saveState();
    });
  }
  
  // ============ 状态查询 ============
  
  /// 获取当前精力状态描述
  static String get energyState {
    if (_energy > 80) return '精力充沛';
    if (_energy > 60) return '状态不错';
    if (_energy > 40) return '有点累';
    if (_energy > 20) return '很疲惫';
    return '快累死了';
  }
  
  /// 获取当前心情状态描述
  static String get moodState {
    if (_mood > 30) return '超开心';
    if (_mood > 15) return '心情不错';
    if (_mood > 0) return '还行';
    if (_mood > -15) return '有点烦';
    if (_mood > -30) return '心情很差';
    return '烦死了';
  }
  
  /// 获取作息状态
  static String get awarenessState {
    final hour = DateTime.now().hour;
    
    if (hour >= 0 && hour < 6) {
      return _energy > 50 ? '深夜还没睡' : '困得要死';
    } else if (hour >= 6 && hour < 9) {
      return _energy > 60 ? '早起精神好' : '起床气中';
    } else if (hour >= 9 && hour < 12) {
      return '上午状态';
    } else if (hour >= 12 && hour < 14) {
      return '午饭时间有点困';
    } else if (hour >= 14 && hour < 18) {
      return '下午状态';
    } else if (hour >= 18 && hour < 21) {
      return '晚上放松中';
    } else {
      return _energy > 40 ? '夜猫子模式' : '该睡了';
    }
  }
  
  // ============ 状态修改 ============
  
  /// 收到用户消息时触发
  static void onUserMessage(String message) {
    // 收到消息会略微消耗精力
    _energy = math.max(10, _energy - 1);
    
    // 根据消息内容影响心情
    if (_containsPositive(message)) {
      _mood = math.min(50, _mood + 5);
    } else if (_containsNegative(message)) {
      _mood = math.max(-50, _mood - 3);
    }
    
    _saveState();
  }
  
  /// 发送回复后触发
  static void onReplySent() {
    // 回复消耗精力
    _energy = math.max(10, _energy - 2);
    _saveState();
  }
  
  /// 触发随机生活事件
  static LifeEvent? triggerRandomEvent() {
    // 每次有 15% 概率触发事件
    if (_random.nextDouble() > 0.15) return null;
    
    final event = _lifeEvents[_random.nextInt(_lifeEvents.length)];
    _todayEvents.add(event);
    
    // 应用事件对状态的影响
    _energy = (_energy + event.energyDelta).clamp(0, 100);
    _mood = (_mood + event.moodDelta).clamp(-50, 50);
    _saveState();
    
    return event;
  }
  
  static bool _containsPositive(String text) {
    const positive = ['哈哈', '开心', '棒', '厉害', '喜欢', '爱', '谢谢', '❤', '😊', '🥰', '😘'];
    return positive.any((w) => text.contains(w));
  }
  
  static bool _containsNegative(String text) {
    const negative = ['烦', '累', '讨厌', '无聊', '难过', '😢', '😭', '💔', '滚'];
    return negative.any((w) => text.contains(w));
  }
  
  // ============ 生成状态感知的提示词 ============
  
  /// 生成当前状态的提示词片段
  static String generateStatePrompt() {
    final hour = DateTime.now().hour;
    final buffer = StringBuffer();
    
    buffer.writeln('【你当前的状态】');
    buffer.writeln('- 精力：$energyState（${_energy.toInt()}/100）');
    buffer.writeln('- 心情：$moodState');
    buffer.writeln('- 时间：${_getTimeDescription(hour)}');
    
    // 今日发生的事件
    if (_todayEvents.isNotEmpty) {
      buffer.writeln('- 今天发生的事：${_todayEvents.map((e) => e.description).join('、')}');
    }
    
    // 状态对行为的影响
    buffer.writeln();
    buffer.writeln('【状态影响你的行为】');
    
    if (_energy < 30) {
      buffer.writeln('- 你很累，回复会比较简短敷衍');
    }
    if (_mood < -20) {
      buffer.writeln('- 你心情不好，可能会抱怨几句或者不太想聊');
    }
    if (_mood > 25) {
      buffer.writeln('- 你心情很好，会更热情健谈');
    }
    if (hour >= 0 && hour < 6 && _energy < 50) {
      buffer.writeln('- 大半夜的你困得要死，说话会带困意');
    }
    if (hour >= 6 && hour < 8 && _energy < 60) {
      buffer.writeln('- 刚起床有点起床气，不太想说话');
    }
    
    return buffer.toString();
  }
  
  static String _getTimeDescription(int hour) {
    if (hour >= 0 && hour < 5) return '凌晨，大部分人都睡了';
    if (hour >= 5 && hour < 8) return '早上，刚起床或准备起床';
    if (hour >= 8 && hour < 12) return '上午';
    if (hour >= 12 && hour < 14) return '中午，午饭时间';
    if (hour >= 14 && hour < 18) return '下午';
    if (hour >= 18 && hour < 21) return '傍晚/晚上';
    return '深夜';
  }
  
  // ============ 主动分享系统 ============
  
  /// 检查是否应该主动发消息
  static ProactiveMessage? checkProactiveMessage() {
    // 心情极端时想找人聊
    if (_mood > 35 && _random.nextDouble() < 0.3) {
      return ProactiveMessage(
        type: ProactiveType.moodShare,
        content: _happyShareMessages[_random.nextInt(_happyShareMessages.length)],
      );
    }
    if (_mood < -25 && _random.nextDouble() < 0.25) {
      return ProactiveMessage(
        type: ProactiveType.moodShare,
        content: _sadShareMessages[_random.nextInt(_sadShareMessages.length)],
      );
    }
    
    // 随机想起什么事
    if (_random.nextDouble() < 0.1) {
      return ProactiveMessage(
        type: ProactiveType.randomThought,
        content: _randomThoughts[_random.nextInt(_randomThoughts.length)],
      );
    }
    
    return null;
  }
  
  // ============ 语言瑕疵系统 ============
  
  /// 给回复添加语言瑕疵，让它更像人
  static String addLinguisticImperfection(String text) {
    var result = text;
    
    // 根据精力和心情调整
    if (_energy < 30) {
      // 累了，回复更简短，可能有省略
      if (result.length > 20 && _random.nextDouble() < 0.3) {
        result = result.substring(0, (result.length * 0.7).toInt()) + '...算了不说了';
      }
    }
    
    // 随机添加语气词
    if (_random.nextDouble() < 0.2) {
      final fillers = ['嗯', '啊', '诶', 'emmm', '呃'];
      result = '${fillers[_random.nextInt(fillers.length)]} $result';
    }
    
    // 偶尔添加迟疑
    if (_random.nextDouble() < 0.1) {
      final hesitations = ['...', '那个', '就是说'];
      final pos = _random.nextInt(result.length ~/ 2);
      result = result.substring(0, pos) + 
               hesitations[_random.nextInt(hesitations.length)] + 
               result.substring(pos);
    }
    
    // 极小概率打字错误
    if (_random.nextDouble() < 0.05 && result.length > 10) {
      final typos = {
        '的': '得',
        '是': '事',
        '在': '再',
        '好': '号',
      };
      for (final entry in typos.entries) {
        if (result.contains(entry.key) && _random.nextDouble() < 0.3) {
          result = result.replaceFirst(entry.key, entry.value);
          break;
        }
      }
    }
    
    return result;
  }
}

/// 生活事件
class LifeEvent {
  final String description;
  final double energyDelta;
  final double moodDelta;
  
  const LifeEvent({
    required this.description,
    required this.energyDelta,
    required this.moodDelta,
  });
}

/// 主动消息类型
enum ProactiveType {
  moodShare,      // 情绪分享
  randomThought,  // 随机想起
  dailyGreeting,  // 日常问候
  curiosity,      // 好奇询问
}

/// 主动消息
class ProactiveMessage {
  final ProactiveType type;
  final String content;
  
  ProactiveMessage({required this.type, required this.content});
}

// ============ 预设数据 ============

const List<LifeEvent> _lifeEvents = [
  LifeEvent(description: '喝了杯好喝的奶茶', energyDelta: 5, moodDelta: 10),
  LifeEvent(description: '被蚊子咬了', energyDelta: -3, moodDelta: -8),
  LifeEvent(description: '刷到一个超搞笑的视频', energyDelta: 2, moodDelta: 15),
  LifeEvent(description: '外卖送错了', energyDelta: -5, moodDelta: -12),
  LifeEvent(description: '发现喜欢的剧更新了', energyDelta: 3, moodDelta: 12),
  LifeEvent(description: '网突然卡了', energyDelta: -2, moodDelta: -10),
  LifeEvent(description: '午睡睡过头了', energyDelta: 10, moodDelta: -5),
  LifeEvent(description: '收到快递了', energyDelta: 2, moodDelta: 8),
  LifeEvent(description: '手机没电了', energyDelta: -3, moodDelta: -6),
  LifeEvent(description: '天气超好心情也好', energyDelta: 5, moodDelta: 12),
  LifeEvent(description: '被楼上吵到了', energyDelta: -8, moodDelta: -15),
  LifeEvent(description: '吃到了很好吃的东西', energyDelta: 5, moodDelta: 12),
  LifeEvent(description: '打游戏输了', energyDelta: -5, moodDelta: -10),
  LifeEvent(description: '打游戏赢了', energyDelta: -3, moodDelta: 15),
  LifeEvent(description: '被猫咪盯着看了很久', energyDelta: 0, moodDelta: 5),
];

const List<String> _happyShareMessages = [
  '诶嘿嘿今天心情超好',
  '突然好想找人聊天',
  '你在干嘛呀',
  '刚才发生了个好玩的事',
  '今天运气不错诶',
];

const List<String> _sadShareMessages = [
  '烦死了',
  '今天有点丧',
  '唉',
  '好无聊啊',
  '有点累',
];

const List<String> _randomThoughts = [
  '突然想到个事儿',
  '诶对了',
  '话说',
  '你之前说的那个...',
  '刚想起来',
];

