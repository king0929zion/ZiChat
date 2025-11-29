import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:zichat/config/api_secrets.dart';
import 'package:zichat/config/ai_models.dart';
import 'package:zichat/services/ai_soul_engine.dart';
import 'package:zichat/services/ai_tools_service.dart';
import 'package:zichat/storage/ai_config_storage.dart';
import 'package:zichat/storage/model_selection_storage.dart';

/// 统一的 AI 对话服务
/// 支持 OpenAI / Gemini 两种 provider
/// 支持内置 API 和自定义 API
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

  /// 流式发送消息 - 实现打字机效果
  /// 返回 Stream，每次 yield 一个字符或词
  static Stream<String> sendChatStream({
    required String chatId,
    required String userInput,
  }) async* {
    // 检查是否使用内置 API
    final useBuiltIn = await ModelSelectionStorage.getUseBuiltInApi();
    
    String apiBaseUrl;
    String apiKey;
    String model;
    String persona = '';
    
    if (useBuiltIn && ApiSecrets.hasBuiltInChatApi) {
      // 使用内置 API
      apiBaseUrl = ApiSecrets.chatBaseUrl;
      apiKey = ApiSecrets.chatApiKey;
      final selectedModel = await ModelSelectionStorage.getChatModel();
      model = selectedModel.id;
    } else {
      // 使用用户自定义 API
      final config = await AiConfigStorage.loadGlobalConfig();
      if (config == null ||
          config.apiBaseUrl.trim().isEmpty ||
          config.apiKey.trim().isEmpty ||
          config.model.trim().isEmpty) {
        throw Exception('AI 配置不完整，请先在"我-设置-通用-AI 配置"中填写。');
      }
      apiBaseUrl = config.apiBaseUrl.trim();
      apiKey = config.apiKey.trim();
      model = config.model.trim();
      persona = config.persona;
    }

    // 模拟真人回复延迟 (800ms - 2000ms)
    final initialDelay = 800 + _random.nextInt(1200);
    await Future.delayed(Duration(milliseconds: initialDelay));

    // 构建系统提示词
    final systemPrompt = await _buildSystemPrompt(chatId, persona);
    
    // 获取智能上下文历史
    final history = _getSmartHistory(chatId, userInput);

    // 记录用户消息到历史
    _addToHistory(chatId, 'user', userInput);
    
    // 触发灵魂引擎状态更新
    AiSoulEngine.instance.onUserMessage(userInput);
    
    // 随机触发生活事件
    AiSoulEngine.instance.triggerRandomEvent();
    
    // 增加亲密度
    AiSoulEngine.instance.updateIntimacy(chatId, 0.5);

    // 内置 API 都是 OpenAI 兼容格式，使用流式输出
    final buffer = StringBuffer();
    
    await for (final chunk in _callOpenAiStream(
      baseUrl: apiBaseUrl,
      apiKey: apiKey,
      model: model,
      systemPrompt: systemPrompt,
      userInput: userInput,
      history: history,
    )) {
      buffer.write(chunk);
      yield chunk;
    }
    
    // 记录 AI 回复到历史
    _addToHistory(chatId, 'assistant', buffer.toString());
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
    
    // 按反斜线分句
    final List<String> parts = raw
        .split('\\')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty && raw.trim().isNotEmpty) {
      parts.add(raw.trim());
    }

    return parts;
  }

  /// 构建系统提示词 (增强拟人化 + 状态感知)
  static Future<String> _buildSystemPrompt(String chatId, String persona) async {
    final basePrompt = await _getBasePrompt();
    final contactPrompt = (await AiConfigStorage.loadContactPrompt(chatId)) ?? '';
    
    final buffer = StringBuffer();
    
    // 基础提示词
    if (basePrompt.trim().isNotEmpty) {
      buffer.writeln(basePrompt.trim());
    }
    
    // 加入完整的灵魂引擎状态提示
    buffer.writeln();
    buffer.writeln(AiSoulEngine.instance.generateStatePrompt());
    
    // 加入亲密度相关提示
    buffer.writeln();
    buffer.writeln(AiSoulEngine.instance.getIntimacyPrompt(chatId));
    
    // 用户自定义人设
    if (persona.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('【额外人设补充】');
      buffer.writeln(persona.trim());
    }
    
    // 联系人专属提示词
    if (contactPrompt.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln('【针对这个朋友的特别说明】');
      buffer.writeln(contactPrompt.trim());
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
    // 中文约 1.5 字/token，英文约 4 字/token
    // 这里用一个折中值
    return (text.length / 2).ceil();
  }

  /// 模拟流式输出 (用于不支持流式的 API)
  /// 包含自然的打字节奏：快速连打 + 偶尔停顿
  static Stream<String> _simulateStream(String text) async* {
    int consecutiveChars = 0;
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      yield char;
      consecutiveChars++;
      
      // 标点符号后稍微停顿
      if ('，。！？、；：'.contains(char)) {
        await Future.delayed(Duration(milliseconds: 150 + _random.nextInt(200)));
        consecutiveChars = 0;
      }
      // 反斜线（分句符）后停顿更长
      else if (char == '\\') {
        await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(300)));
        consecutiveChars = 0;
      }
      // 每打几个字后偶尔停顿一下，模拟思考
      else if (consecutiveChars > 5 && _random.nextDouble() < 0.15) {
        await Future.delayed(Duration(milliseconds: 100 + _random.nextInt(150)));
        consecutiveChars = 0;
      }
      // 正常打字速度
      else {
        await Future.delayed(Duration(milliseconds: 25 + _random.nextInt(35)));
      }
    }
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
    final uri = _joinUri(baseUrl, 'v1/chat/completions');

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
      'temperature': 0.8,
      'stream': true,
    });

    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.body = body;

    final client = http.Client();
    
    try {
      final response = await client.send(request).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw TimeoutException('请求超时'),
      );

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception('API 错误 (${response.statusCode}): $body');
      }

      String buffer = '';
      
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        
        // 处理 SSE 格式
        while (buffer.contains('\n')) {
          final index = buffer.indexOf('\n');
          final line = buffer.substring(0, index).trim();
          buffer = buffer.substring(index + 1);
          
          if (line.isEmpty) continue;
          if (line == 'data: [DONE]') return;
          if (!line.startsWith('data: ')) continue;
          
          try {
            final jsonStr = line.substring(6);
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            final choices = data['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            }
          } catch (_) {
            // 忽略解析错误，继续处理
          }
        }
      }
    } finally {
      client.close();
    }
  }

  static Uri _joinUri(String base, String path) {
    if (base.endsWith('/')) {
      return Uri.parse('$base$path');
    }
    return Uri.parse('$base/$path');
  }

  /// Gemini 请求 (非流式)
  static Future<String> _callGemini({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userInput,
    required List<Map<String, String>> history,
  }) async {
    final String cleanedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final uri = Uri.parse(
      '$cleanedBase/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final buffer = StringBuffer();
    if (systemPrompt.isNotEmpty) {
      buffer.writeln(systemPrompt.trim());
      buffer.writeln();
    }

    // 加入历史对话
    for (final item in history) {
      final content = item['content'] ?? '';
      if (content.isEmpty) continue;
      final role = item['role'] ?? 'user';
      final prefix = role == 'assistant' ? '朋友：' : '我：';
      buffer.writeln('$prefix$content');
    }

    buffer.writeln('我：$userInput');
    final promptText = buffer.toString().trim();

    final body = jsonEncode({
      'contents': [
        {
          'parts': [{'text': promptText}],
        },
      ],
      'generationConfig': {
        'temperature': 0.8,
      },
    });

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw TimeoutException('请求超时'),
    );

    if (resp.statusCode != 200) {
      throw Exception('Gemini 接口错误(${resp.statusCode}): ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini 返回内容为空');
    }

    final content = candidates.first['content'];
    if (content is Map<String, dynamic>) {
      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Gemini 返回内容为空');
      }
      final resultBuffer = StringBuffer();
      for (final p in parts) {
        if (p is Map<String, dynamic>) {
          final text = p['text'];
          if (text != null) {
            resultBuffer.write(text.toString());
          }
        }
      }
      final result = resultBuffer.toString();
      if (result.isEmpty) {
        throw Exception('Gemini 返回内容为空');
      }
      return result;
    }

    return content.toString();
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
