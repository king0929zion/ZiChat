import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 模型检测服务
/// 自动检测 API 支持的可用模型列表
class ModelDetectorService {
  /// 检测可用模型
  static Future<List<String>> detectModels({
    required String baseUrl,
    required String apiKey,
  }) async {
    // 移除末尾斜杠
    String url = baseUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    // 确保以 /v1 结尾
    if (!url.endsWith('/v1')) {
      if (url.endsWith('/v1/')) {
        url = url.substring(0, url.length - 1);
      } else if (!url.contains('/v1')) {
        url = '$url/v1';
      }
    }

    try {
      // 尝试调用 models 接口
      final response = await http.get(
        Uri.parse('$url/models'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = <String>[];

        // OpenAI 格式
        if (data is Map && data['data'] is List) {
          for (var item in data['data']) {
            if (item is Map && item['id'] is String) {
              models.add(item['id'] as String);
            }
          }
        }
        // 简单列表格式
        else if (data is List) {
          for (var item in data) {
            if (item is String) {
              models.add(item);
            } else if (item is Map && item['id'] is String) {
              models.add(item['id'] as String);
            }
          }
        }

        // 过滤掉一些不太常用的模型
        models.removeWhere((m) =>
            m.contains('whisper') ||
            m.contains('tts') ||
            m.contains('embedding') ||
            m.contains('moderation'));

        return models;
      } else {
        throw Exception('API 返回错误: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Model detection error: $e');
      // 如果检测失败，返回一些常见模型作为默认
      rethrow;
    }
  }

  /// 测试 API 连接
  static Future<bool> testConnection({
    required String baseUrl,
    required String apiKey,
    String model = 'gpt-3.5-turbo',
  }) async {
    try {
      String url = baseUrl.trim();
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      if (!url.endsWith('/v1')) {
        url = '$url/v1';
      }

      final response = await http.post(
        Uri.parse('$url/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': 'Hi'}
          ],
          'max_tokens': 10,
        }),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test error: $e');
      return false;
    }
  }
}
