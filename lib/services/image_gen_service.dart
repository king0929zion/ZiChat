import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:zichat/models/api_config.dart';
import 'package:zichat/storage/ai_config_storage.dart';
import 'package:zichat/storage/api_config_storage.dart';

/// 图像生成服务
/// 支持 OpenAI 兼容格式的图像生成 API（如 DALL-E）
class ImageGenService {
  static AiBaseModelsConfig _loadBaseModels() {
    try {
      final raw = Hive.box(AiConfigStorage.boxName).get('base_models');
      if (raw is Map) {
        return AiBaseModelsConfig.fromMap(raw) ?? const AiBaseModelsConfig();
      }
    } catch (_) {}
    return const AiBaseModelsConfig();
  }

  static ({ApiConfig config, String model})? _resolve() {
    final base = _loadBaseModels();
    if (!base.hasChatModel) return null;
    if (!base.hasImageGenModel) return null;

    final configId = (base.imageGenConfigId ?? '').trim();
    final model = (base.imageGenModel ?? '').trim();
    final config = ApiConfigStorage.getConfig(configId);
    if (config == null) return null;
    if (!config.isActive) return null;
    if (config.baseUrl.trim().isEmpty || config.apiKey.trim().isEmpty) return null;
    if (model.isEmpty) return null;
    return (config: config, model: model);
  }

  /// 检查是否可用
  static bool get isAvailable {
    return _resolve() != null;
  }

  /// 生成图片
  /// 返回 base64 编码的图片数据，出错返回 null
  static Future<String?> generateImage({
    required String prompt,
    String? negativePrompt,
    int? width,
    int? height,
  }) async {
    final resolved = _resolve();
    if (resolved == null) {
      debugPrint('Image generation API not available');
      return null;
    }

    try {
      final config = resolved.config;
      final model = resolved.model;

      final uri = _joinUri(config.baseUrl, 'images/generations');

      final body = jsonEncode({
        'model': model,
        'prompt': prompt,
        'n': 1,
        'size': '${width ?? 1024}x${height ?? 1024}',
        'response_format': 'b64_json',
      });

      debugPrint('Image generation request: $uri');
      debugPrint('Model: $model, Prompt: $prompt');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw Exception('图片生成超时'),
      );

      debugPrint('Image generation response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('Image generation error: ${response.body}');
        return null;
      }

      // 在后台线程解析巨大的 JSON 响应
      final result = await compute(_parseGenerateResponse, response.body);

      if (result['b64'] != null) {
        return result['b64'];
      }
      
      if (result['url'] != null) {
        return await _downloadAndConvertToBase64(result['url']!);
      }

      debugPrint('No image data in response');
      return null;
    } catch (e) {
      debugPrint('Image generation error: $e');
      return null;
    }
  }

  /// 解析响应 (在 Isolate 中运行)
  static Map<String, String?> _parseGenerateResponse(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final dataList = data['data'] as List<dynamic>?;
      
      if (dataList != null && dataList.isNotEmpty) {
        final first = dataList[0] as Map<String, dynamic>;
        return {
          'b64': first['b64_json'] as String?,
          'url': first['url'] as String?,
        };
      }
    } catch (e) {
      debugPrint('Parse error: $e');
    }
    return {};
  }

  /// 从 URL 下载图片并转换为 base64
  static Future<String?> _downloadAndConvertToBase64(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 60),
      );
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      }
    } catch (e) {
      debugPrint('Failed to download image: $e');
    }
    return null;
  }

  static Uri _joinUri(String base, String path) {
    if (base.endsWith('/')) {
      return Uri.parse('$base$path');
    }
    return Uri.parse('$base/$path');
  }
}
