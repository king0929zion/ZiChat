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

  /// 检查是否可用
  static bool get isAvailable {
    final base = _loadBaseModels();
    if (base.hasImageGenModel) {
      final config = ApiConfigStorage.getConfig((base.imageGenConfigId ?? '').trim());
      final model = (base.imageGenModel ?? '').trim();
      return config != null &&
          config.baseUrl.trim().isNotEmpty &&
          config.apiKey.trim().isNotEmpty &&
          model.isNotEmpty;
    }
    final enabled = ApiConfigStorage.getEnabledConfigs();
    final fallback = enabled.isNotEmpty ? enabled : ApiConfigStorage.getAllConfigs();
    return fallback.any((c) => c.models.isNotEmpty);
  }

  /// 获取用于图像生成的 API 配置
  static ApiConfig? _getImageConfig() {
    final enabled = ApiConfigStorage.getEnabledConfigs();
    final allConfigs = enabled.isNotEmpty ? enabled : ApiConfigStorage.getAllConfigs();

    // 优先选择看起来支持图像生成的配置
    for (final config in allConfigs) {
      if (config.models.any((m) =>
          m.toLowerCase().contains('dall') ||
          m.toLowerCase().contains('image') ||
          m.toLowerCase().contains('stable-diffusion'))) {
        return config;
      }
    }

    // 否则返回第一条可用配置
    try {
      return allConfigs.first;
    } catch (_) {
      return null;
    }
  }

  /// 生成图片
  /// 返回 base64 编码的图片数据，出错返回 null
  static Future<String?> generateImage({
    required String prompt,
    String? negativePrompt,
    int? width,
    int? height,
  }) async {
    final base = _loadBaseModels();
    final selectedConfig = base.hasImageGenModel
        ? ApiConfigStorage.getConfig((base.imageGenConfigId ?? '').trim())
        : null;

    final config = selectedConfig ?? _getImageConfig();
    if (config == null) {
      debugPrint('Image generation API not available');
      return null;
    }

    try {
      final configuredModel = (base.imageGenModel ?? '').trim();
      final model = configuredModel.isNotEmpty
          ? configuredModel
          : config.models.firstWhere(
              (m) =>
                  m.toLowerCase().contains('dall') ||
                  m.toLowerCase().contains('image'),
              orElse: () => config.models.isNotEmpty ? config.models.first : '',
            );

      if (model.trim().isEmpty) {
        debugPrint('No image generation model configured');
        return null;
      }

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
