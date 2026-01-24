import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import 'package:zichat/models/api_config.dart';
import 'package:zichat/models/chat_message.dart';
import 'package:zichat/services/ai_tools_service.dart';
import 'package:zichat/storage/ai_config_storage.dart';
import 'package:zichat/storage/api_config_storage.dart';

class _ResolvedAiModels {
  const _ResolvedAiModels({
    required this.chatConfig,
    required this.chatModel,
    required this.chatModelSupportsImage,
    required this.visionConfig,
    required this.visionModel,
    required this.visionModelSupportsImage,
  });

  final ApiConfig chatConfig;
  final String chatModel;
  final bool chatModelSupportsImage;

  final ApiConfig? visionConfig;
  final String? visionModel;
  final bool visionModelSupportsImage;

  bool get canVision =>
      visionModelSupportsImage &&
      visionConfig != null &&
      (visionModel?.trim().isNotEmpty ?? false);
}

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

  // 多模态：上下文最多携带图片数量（避免 payload 过大）
  static const int _maxImagesInContext = 2;

  // 视觉解析结果缓存（同一图片路径 + 视觉模型）
  static final Map<String, String> _visionCache = {};

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

  static Future<_ResolvedAiModels> _resolveModels() async {
    final storedBase = await AiConfigStorage.loadBaseModelsConfig();
    if (storedBase == null || !storedBase.hasChatModel) {
      throw Exception('请先在“设置-默认助手配置”配置对话模型');
    }

    final base = storedBase;

    final chatConfig =
        ApiConfigStorage.getConfig((base.chatConfigId ?? '').trim());
    if (chatConfig == null) {
      throw Exception('对话模型的服务商不存在，请重新选择');
    }
    if (!chatConfig.isActive) {
      throw Exception('请先在“设置-供应商配置”中启用对话模型的服务商');
    }

    final chatModel = (base.chatModel ?? '').trim();
    final chatModelSupportsImage = base.chatModelSupportsImage;

    if (chatConfig.baseUrl.trim().isEmpty || chatConfig.apiKey.trim().isEmpty) {
      throw Exception('请先在“设置-供应商配置”中填写 API 地址与密钥');
    }
    if (chatModel.isEmpty) {
      throw Exception('请先在“默认助手配置”设置对话模型');
    }

    ApiConfig? visionConfig;
    String? visionModel;
    bool visionModelSupportsImage = true;

    if (!chatModelSupportsImage) {
      visionModelSupportsImage = base.visionModelSupportsImage;
      if (base.hasVisionModel && visionModelSupportsImage) {
        final cfgId = (base.visionConfigId ?? '').trim();
        final model = (base.visionModel ?? '').trim();
        final cfg = ApiConfigStorage.getConfig(cfgId);
        if (cfg != null &&
            cfg.isActive &&
            cfg.baseUrl.trim().isNotEmpty &&
            cfg.apiKey.trim().isNotEmpty &&
            model.isNotEmpty) {
          visionConfig = cfg;
          visionModel = model;
        }
      }
    }

    return _ResolvedAiModels(
      chatConfig: chatConfig,
      chatModel: chatModel,
      chatModelSupportsImage: chatModelSupportsImage,
      visionConfig: visionConfig,
      visionModel: visionModel,
      visionModelSupportsImage: visionModelSupportsImage,
    );
  }

  static bool _contextAlreadyHasUserInput(
    List<ChatMessage> contextMessages,
    String userInput,
  ) {
    if (userInput.trim().isEmpty) return true;
    for (final msg in contextMessages.reversed) {
      if (msg.direction != 'out') continue;
      if (msg.type != 'text') continue;
      final text = (msg.text ?? '').trim();
      if (text.isEmpty) continue;
      return text == userInput.trim();
    }
    return false;
  }

  static int _estimateContentTokens(dynamic content) {
    if (content is String) return _estimateTokens(content);
    if (content is List) {
      int tokens = 0;
      for (final part in content) {
        if (part is Map) {
          final type = (part['type'] ?? '').toString();
          if (type == 'text') {
            tokens += _estimateTokens((part['text'] ?? '').toString());
          }
          if (type == 'image_url') {
            tokens += 200;
          }
        }
      }
      return tokens;
    }
    return 0;
  }

  static Future<String> _describeImage({
    required ApiConfig config,
    required String model,
    required String imagePath,
  }) async {
    if (model.trim().isEmpty) return '';

    final cacheKey = '${config.id}|$model|$imagePath';
    final cached = _visionCache[cacheKey];
    if (cached != null) return cached;

    final dataUrl = await _imagePathToDataUrl(imagePath);
    if (dataUrl == null) return '';

    final visionMessages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content':
            '你是图片理解助手，把图片内容转成文字给另一个模型使用：\n'
            '1) 图片简要描述（包含主体/场景/动作）\n'
            '2) 图片中的文字（如有，按原样）\n'
            '3) 关键细节（如颜色/位置/数量/时间等）\n'
            '要求：用简短要点输出；不要解释，不要寒暄；控制在 200 字以内。',
      },
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': '请解析这张图片。'},
          {
            'type': 'image_url',
            'image_url': {'url': dataUrl},
          },
        ],
      },
    ];

    final buffer = StringBuffer();
    await for (final chunk in _callOpenAiStream(
      baseUrl: config.baseUrl,
      apiKey: config.apiKey,
      chatCompletionsPath: config.chatCompletionsPath,
      model: model,
      messages: visionMessages,
      temperature: 0,
      topP: 1,
      maxTokens: 1024,
    )) {
      buffer.write(chunk);
    }

    final raw = buffer.toString();
    final text = AiToolsService.removeToolMarkers(_removeThinkingContent(raw))
        .trim();

    _visionCache[cacheKey] = text;
    return text;
  }

  static Future<Map<String, dynamic>?> _chatMessageToApiMessage(
    ChatMessage message,
    _ResolvedAiModels models, {
    required int imageCount,
  }) async {
    final direction = message.direction;
    if (direction != 'out' && direction != 'in') return null;
    if (message.isSystemMessage) return null;

    final role = direction == 'out' ? 'user' : 'assistant';

    switch (message.type) {
      case 'text':
        final text = (message.text ?? '').trim();
        if (text.isEmpty) return null;
        final clean =
            AiToolsService.removeToolMarkers(_removeThinkingContent(text)).trim();
        if (clean.isEmpty) return null;
        return {'role': role, 'content': clean};
      case 'image':
        final path = (message.image ?? '').trim();
        if (path.isEmpty) return {'role': role, 'content': '[图片]'};

        if (role != 'user') {
          return {'role': role, 'content': '[图片]'};
        }

        final allowImage = imageCount < _maxImagesInContext;

        if (models.chatModelSupportsImage && allowImage) {
          final dataUrl = await _imagePathToDataUrl(path);
          if (dataUrl == null) {
            return {'role': role, 'content': '[图片]'};
          }
          return {
            'role': role,
            'content': [
              {'type': 'text', 'text': '看下这张图'},
              {
                'type': 'image_url',
                'image_url': {'url': dataUrl},
              },
            ],
            '__imageUsed': true,
          };
        }

        if (allowImage && models.canVision) {
          final visionText = await _describeImage(
            config: models.visionConfig!,
            model: models.visionModel!,
            imagePath: path,
          );
          return {
            'role': role,
            'content':
                visionText.trim().isEmpty ? '[图片]' : '【图片解析】\n$visionText',
            '__imageUsed': true,
          };
        }

        return {'role': role, 'content': '[图片]'};
      case 'voice':
        return {'role': role, 'content': '[语音]'};
      case 'transfer':
        final amount = (message.amount ?? '').trim();
        return {
          'role': role,
          'content': amount.isEmpty ? '[转账]' : '[转账 ¥$amount]',
        };
      case 'red-packet':
        return {'role': role, 'content': '[红包]'};
      default:
        return null;
    }
  }

  static Future<List<Map<String, dynamic>>> _buildMessagesFromContext(
    List<ChatMessage> contextMessages,
    _ResolvedAiModels models,
  ) async {
    final result = <Map<String, dynamic>>[];
    int tokenCount = 0;
    int imageCount = 0;

    for (int i = contextMessages.length - 1; i >= 0; i--) {
      final msg = contextMessages[i];
      final built = await _chatMessageToApiMessage(
        msg,
        models,
        imageCount: imageCount,
      );
      if (built == null) continue;

      if (built['__imageUsed'] == true) {
        imageCount += 1;
        built.remove('__imageUsed');
      }

      final content = built['content'];
      final tokens = _estimateContentTokens(content);
      if (tokenCount + tokens > _maxContextTokens) break;

      tokenCount += tokens;
      result.insert(0, built);
    }

    return result;
  }

  /// 流式发送消息 - 实现打字机效果
  /// 返回 Stream，每次 yield 一个字符或词
  static Stream<String> sendChatStream({
    required String chatId,
    String? userInput,
    String? friendPrompt,
    List<ChatMessage>? contextMessages,
  }) async* {
    final normalizedInput = (userInput ?? '').trim();
    final hasContext = contextMessages != null && contextMessages.isNotEmpty;
    if (normalizedInput.isEmpty && !hasContext) return;

    // 获取当前使用的模型（基础模型配置优先）
    final models = await _resolveModels();
    final config = models.chatConfig;
    final model = models.chatModel;

    // 模拟真人回复延迟 (800ms - 2000ms)
    final initialDelay = 800 + _random.nextInt(1200);
    await Future.delayed(Duration(milliseconds: initialDelay));

    // 构建系统提示词
    final systemPrompt = await _buildSystemPrompt(chatId, friendPrompt);

    final messages = <Map<String, dynamic>>[];
    if (systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    if (hasContext) {
      final context = await _buildMessagesFromContext(contextMessages!, models);
      messages.addAll(context);

      if (normalizedInput.isNotEmpty &&
          !_contextAlreadyHasUserInput(contextMessages!, normalizedInput)) {
        messages.add({'role': 'user', 'content': normalizedInput});
      }
    } else {
      if (normalizedInput.isEmpty) return;

      // 获取智能上下文历史
      final history = _getSmartHistory(chatId, normalizedInput);

      // 避免历史中已包含当前输入，导致重复
      if (history.isNotEmpty) {
        final last = history.last;
        final lastRole = last['role'] ?? '';
        final lastContent = (last['content'] ?? '').trim();
        if (lastRole == 'user' && lastContent == normalizedInput) {
          history.removeLast();
        }
      }

      // 记录用户消息到历史
      _addToHistory(chatId, 'user', normalizedInput);

      for (final item in history) {
        messages.add({'role': item['role'], 'content': item['content']});
      }
      messages.add({'role': 'user', 'content': normalizedInput});
    }

    final buffer = StringBuffer();
    final rawBuffer = StringBuffer();

    await for (final chunk in _callOpenAiStream(
      baseUrl: config.baseUrl,
      apiKey: config.apiKey,
      chatCompletionsPath: config.chatCompletionsPath,
      model: model,
      messages: messages,
      temperature: config.temperature.clamp(0.0, 2.0),
      topP: config.topP.clamp(0.0, 1.0),
      maxTokens: config.maxTokens.clamp(1, 4096),
    )) {
      rawBuffer.write(chunk);
      buffer.write(chunk);
      yield chunk;
    }

    // 流结束后，过滤 thinking 标签内容
    String finalContent = rawBuffer.toString();
    finalContent = _removeThinkingContent(finalContent);
    finalContent = finalContent.trim();

    if (!hasContext) {
      // 记录 AI 回复到历史（过滤 thinking + 移除 tool marker）
      final historyText = AiToolsService.removeToolMarkers(finalContent).trim();
      for (final part in splitReplyParts(historyText)) {
        _addToHistory(chatId, 'assistant', part);
      }
    }
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

  static List<String> splitReplyParts(String text) {
    var normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    normalized = normalized.replaceAll('｜', '|').trim();
    if (normalized.isEmpty) return const [];

    final pipeParts = normalized
        .split('||')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (pipeParts.length > 1) return pipeParts;

    if (!normalized.contains('||') && normalized.contains('\n')) {
      final lineParts = normalized
          .split(RegExp(r'\n+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (_looksLikeMultiMessage(lineParts)) return lineParts;
    }

    return pipeParts.isNotEmpty ? pipeParts : [normalized];
  }

  static bool _looksLikeMultiMessage(List<String> parts) {
    if (parts.length <= 1) return false;
    if (parts.length > 10) return false;
    int maxLen = 0;
    int totalLen = 0;
    for (final part in parts) {
      final len = part.length;
      totalLen += len;
      if (len > maxLen) maxLen = len;
    }
    final avgLen = totalLen / parts.length;
    return maxLen <= 80 || avgLen <= 36;
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

    return splitReplyParts(raw);
  }

  /// 构建系统提示词（简化版）
  static Future<String> _buildSystemPrompt(String chatId, String? friendPrompt) async {
    final basePrompt = await _getBasePrompt();
    const globalPersona = '';

    final buffer = StringBuffer();

    // 基础提示词
    if (basePrompt.trim().isNotEmpty) {
      buffer.writeln(basePrompt.trim());
    }

    // 全局人设（来自 AI 配置页）
    if (globalPersona.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('【全局人设】');
      buffer.writeln(globalPersona);
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
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    _historyCache.putIfAbsent(chatId, () => []);
    final items = _historyCache[chatId]!;
    if (items.isNotEmpty &&
        items.last.role == role &&
        items.last.content == trimmed) {
      return;
    }

    items.add(_HistoryItem(role: role, content: trimmed));

    // 限制历史长度
    if (items.length > _maxHistoryItems) {
      items.removeAt(0);
    }
  }

  /// 清除某个聊天的历史
  static void clearHistory(String chatId) {
    _historyCache.remove(chatId);
  }

  /// 从本地消息同步历史（用于上下文）
  static void syncHistoryFromChatMessages(
    String chatId,
    List<ChatMessage> messages,
  ) {
    if (messages.isEmpty) {
      _historyCache.remove(chatId);
      return;
    }

    final items = <_HistoryItem>[];
    for (final message in messages) {
      final direction = message.direction;
      if (direction != 'out' && direction != 'in') continue;

      final role = direction == 'out' ? 'user' : 'assistant';
      final content = _formatMessageForHistory(message);
      if (content.isEmpty) continue;

      items.add(_HistoryItem(role: role, content: content));
    }

    if (items.length > _maxHistoryItems) {
      items.removeRange(0, items.length - _maxHistoryItems);
    }

    _historyCache[chatId] = items;
  }

  static String _formatMessageForHistory(ChatMessage message) {
    switch (message.type) {
      case 'text':
        final text = (message.text ?? '').trim();
        if (text.isEmpty) return '';
        return AiToolsService.removeToolMarkers(_removeThinkingContent(text))
            .trim();
      case 'image':
        return '[图片]';
      case 'voice':
        return '[语音]';
      case 'transfer':
        final amount = (message.amount ?? '').trim();
        return amount.isEmpty ? '[转账]' : '[转账 ¥$amount]';
      case 'red-packet':
        return '[红包]';
      default:
        return '';
    }
  }

  /// 估算 token 数量 (粗略)
  static int _estimateTokens(String text) {
    return (text.length / 2).ceil();
  }

  static String _guessImageMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    return 'image/jpeg';
  }

  static Future<String?> _imagePathToDataUrl(String path) async {
    try {
      final bytes = await XFile(path).readAsBytes();
      if (bytes.isEmpty) return null;
      final mime = _guessImageMimeType(path);
      return 'data:$mime;base64,${base64Encode(bytes)}';
    } catch (_) {
      return null;
    }
  }

  /// OpenAI 流式请求
  static Stream<String> _callOpenAiStream({
    required String baseUrl,
    required String apiKey,
    required String chatCompletionsPath,
    required String model,
    required List<Map<String, dynamic>> messages,
    required double temperature,
    required double topP,
    required int maxTokens,
  }) async* {
    final cleanPath = chatCompletionsPath.trim();
    final normalizedPath =
        cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath;
    final uri = _joinUri(
      baseUrl,
      normalizedPath.isEmpty ? 'chat/completions' : normalizedPath,
    );

    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'top_p': topP,
      'max_tokens': maxTokens,
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
        
        String errorMessage = 'API 错误 (${response.statusCode})';
        try {
          // 尝试解析错误详情
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData['error'] != null) {
            final error = errorData['error'];
            final msg = error['message']?.toString() ?? '';
            final code = error['code']?.toString() ?? '';
            
            if (response.statusCode == 404) {
              if (code == 'model_not_found' || msg.contains('model') || msg.contains('does not exist')) {
                throw Exception('模型不存在: $model，请在设置中检查模型名称');
              }
              throw Exception('接口地址 404: 请检查 API URL 是否正确\n实际请求地址: $uri\n(提示: 请在设置中检查是否缺少或多余了版本号，如 /v1)');
            }
            
            if (response.statusCode == 401) {
              throw Exception('鉴权失败 401: 请检查 API Key 是否正确');
            }
            
            errorMessage = '$msg ($code)';
          }
        } catch (e) {
          if (e is Exception && e.toString().contains('模型不存在')) rethrow;
          if (e is Exception && e.toString().contains('接口地址')) rethrow;
          if (e is Exception && e.toString().contains('鉴权失败')) rethrow;
          // 解析失败，使用原始 body
          if (response.statusCode == 404) {
             throw Exception('接口地址 404: 请检查 API URL 是否正确\n实际请求地址: $uri\n(提示: 请在设置中检查是否缺少或多余了版本号，如 /v1)');
          }
        }
        
        throw Exception(errorMessage);
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
    String cleanBase = base.trim();
    if (cleanBase.endsWith('/')) {
      cleanBase = cleanBase.substring(0, cleanBase.length - 1);
    }

    // 1. 如果用户填写的 URL 已经包含了具体的 endpoint 路径
    if (cleanBase.endsWith(path)) {
      return Uri.parse(cleanBase);
    }

    // 2. 直接拼接，不再自动补全 /v1，以支持 v2、v1beta 或无版本号的 API
    // 用户需要在设置中填写完整的 Base URL (例如 https://api.openai.com/v1)
    return Uri.parse('$cleanBase/$path');
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
