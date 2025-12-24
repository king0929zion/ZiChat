import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:zichat/models/api_config.dart';
import 'package:zichat/services/ai_tools_service.dart';
import 'package:zichat/storage/api_config_storage.dart';

/// 统一的 AI 对话服务
/// 支持流式响应和智能上下文管理
class AiChatService {
  static String _basePromptCache = '';

  // 对话历史缓存 (内存中)
  static final Map<String, List<_HistoryItem>> _historyCache = {};

  // 最大历史条数
  static const int _maxHistoryItems = 20;

  // 最大 token 估算 (用于控制上下文长度)
  static const int _maxContextTokens = 3000;

  // 随机数生成器
  static final _random = math.Random();

  static Future<String> _getBasePrompt() async {
    if (_basePromptCache.isNotEmpty) return _basePromptCache;
    try {
      _basePromptCache = await rootBundle.loadString('sprompt.md');
    } catch (_) {
      _basePromptCache = '';
    }
    return _basePromptCache;
  }

  /// 获取当前活动的 API 配置
  static Future<ApiConfig> _getActiveConfig() async {
    final config = ApiConfigStorage.getActiveConfig();
    if (config == null || config.models.isEmpty) {
      throw Exception(
        '请先在"我-设置-通用-API 管理"中添加并配置 API',
      );
    }
    return config;
  }

  /// 流式发送消息 - 实现打字机效果
  /// 返回 Stream，每次 yield 一个字符或词
  static Stream<String> sendChatStream({
    required String chatId,
    required String userInput,
    String? friendPrompt,
  }) async* {
    // 获取活动配置
    final config = await _getActiveConfig();

    // 使用配置的第一个模型（或随机选择）
    final model = config.models.first;

    // 模拟真人回复延迟 (800ms - 2000ms)
    final initialDelay = 800 + _random.nextInt(1200);
    await Future.delayed(Duration(milliseconds: initialDelay));

    // 构建系统提示词
    final systemPrompt = await _buildSystemPrompt(chatId, friendPrompt);

    // 获取智能上下文历史
    final history = _getSmartHistory(chatId, userInput);

    // 记录用户消息到历史
    _addToHistory(chatId, 'user', userInput);

    final buffer = StringBuffer();
    final rawBuffer = StringBuffer();

    await for (final chunk in _callOpenAiStream(
      baseUrl: config.baseUrl,
      apiKey: config.apiKey,
      model: model,
      systemPrompt: systemPrompt,
      userInput: userInput,
      history: history,
    )) {
      rawBuffer.write(chunk);
      buffer.write(chunk);
      yield chunk;
    }

    // 流结束后，过滤 thinking 标签内容
    String finalContent = rawBuffer.toString();
    finalContent = _removeThinkingContent(finalContent);

    // 记录 AI 回复到历史（过滤后的内容）
    _addToHistory(chatId, 'assistant', finalContent);
  }

  /// 移除 thinking 标签及其内容
  static String _removeThinkingContent(String text) {
    String result = text;

    // 移除
    result = result.replaceAll(RegExp(r'[\s\S]*?</think>', caseSensitive: false), '');

    // 移除 <thinking>...</thinking>
    result = result.replaceAll(RegExp(r'<thinking>[\s\S]*?</thinking>', caseSensitive: false), '');

    // 移除中文格式的思考标签
    result = result.replaceAll(RegExp(r'【思考】[\s\S]*?【/思考】'), '');

    // 清理多余的空行
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return result.trim();
  }

  /// 普通发送 (兼容旧接口)
  static Future<List<String>> sendChat({
    required String chatId,
    required String userInput,
    List<Map<String, String>>? history,
  }) async {
    final buffer = StringBuffer();

    await for (final chunk in sendChatStream(
      chatId: chatId,
      userInput: userInput,
    )) {
      buffer.write(chunk);
    }

    final raw = buffer.toString();

    // 按 || 分隔成多条消息
    final List<String> parts = raw
        .split('||')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty && raw.trim().isNotEmpty) {
      parts.add(raw.trim());
    }

    return parts;
  }

  /// 构建系统提示词（简化版）
  static Future<String> _buildSystemPrompt(String chatId, String? friendPrompt) async {
    final basePrompt = await _getBasePrompt();

    final buffer = StringBuffer();

    // 基础提示词
    if (basePrompt.trim().isNotEmpty) {
      buffer.writeln(basePrompt.trim());
    }

    // 好友专属人设（来自添加好友时设置）
    if (friendPrompt != null && friendPrompt.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('【你的个性化人设】');
      buffer.writeln(friendPrompt.trim());
    }

    // 工具使用提示
    buffer.writeln();
    buffer.writeln(AiToolsService.generateToolPrompt());

    return buffer.toString().trim();
  }

  /// 智能历史窗口 - 考虑上下文连贯性
  static List<Map<String, String>> _getSmartHistory(String chatId, String currentInput) {
    final history = _historyCache[chatId] ?? [];
    if (history.isEmpty) return [];

    final result = <Map<String, String>>[];
    int tokenCount = _estimateTokens(currentInput);

    // 从最近的消息开始，往前取
    for (int i = history.length - 1; i >= 0; i--) {
      final item = history[i];
      final tokens = _estimateTokens(item.content);

      if (tokenCount + tokens > _maxContextTokens) break;

      tokenCount += tokens;
      result.insert(0, {
        'role': item.role,
        'content': item.content,
      });
    }

    return result;
  }

  /// 添加消息到历史
  static void _addToHistory(String chatId, String role, String content) {
    _historyCache.putIfAbsent(chatId, () => []);
    _historyCache[chatId]!.add(_HistoryItem(role: role, content: content));

    // 限制历史长度
    if (_historyCache[chatId]!.length > _maxHistoryItems) {
      _historyCache[chatId]!.removeAt(0);
    }
  }

  /// 清除某个聊天的历史
  static void clearHistory(String chatId) {
    _historyCache.remove(chatId);
  }

  /// 估算 token 数量 (粗略)
  static int _estimateTokens(String text) {
    return (text.length / 2).ceil();
  }

  /// OpenAI 流式请求
  static Stream<String> _callOpenAiStream({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userInput,
    required List<Map<String, String>> history,
  }) async* {
    final uri = _joinUri(baseUrl, 'chat/completions');

    final List<Map<String, dynamic>> messages = [];

    if (systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    for (final item in history) {
      messages.add({'role': item['role'], 'content': item['content']});
    }

    messages.add({'role': 'user', 'content': userInput});

    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': 0.7,
      'top_p': 0.9,
      'max_tokens': 4096,
      'stream': false,
    });

    debugPrint('API Request URL: $uri');
    debugPrint('API Request Model: $model');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw TimeoutException('请求超时'),
      );

      debugPrint('API Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('API Error Response: ${response.body}');
        throw Exception('API 错误 (${response.statusCode}): ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = _extractContent(data);

      if (content.isNotEmpty) {
        yield content;
      }
    } catch (e) {
      debugPrint('API call error: $e');
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('failed to fetch') ||
          errorStr.contains('clientexception') ||
          errorStr.contains('xmlhttprequest')) {
        throw Exception('网络请求失败');
      }
      rethrow;
    }
  }

  /// 从响应中提取内容
  static String _extractContent(Map<String, dynamic> data) {
    final choices = data['choices'] as List<dynamic>?;
    if (choices != null && choices.isNotEmpty) {
      final choice = choices[0] as Map<String, dynamic>;
      final message = choice['message'] as Map<String, dynamic>?;
      if (message != null) {
        return message['content'] as String? ?? '';
      }
    }
    return '';
  }

  static Uri _joinUri(String base, String path) {
    if (base.endsWith('/')) {
      return Uri.parse('$base$path');
    }
    return Uri.parse('$base/$path');
  }
}

/// 历史消息项
class _HistoryItem {
  final String role;
  final String content;

  _HistoryItem({required this.role, required this.content});
}

/// 超时异常
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
