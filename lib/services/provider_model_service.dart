import 'dart:async';
import 'dart:convert';

import 'package:zichat/models/api_config.dart';
import 'package:zichat/services/provider_http_client.dart';

class ProviderModelService {
  static Future<List<ApiModel>> detectModels(ApiConfig config) async {
    return _detectOpenAiCompatibleModels(config);
  }

  static Future<List<ApiModel>> _detectOpenAiCompatibleModels(ApiConfig config) async {
    final client = ProviderHttpClient.create(config);
    try {
      final uri = _joinUri(config.baseUrl, 'models');
      final response = await client
          .get(
            uri,
            headers: <String, String>{
              'Authorization': 'Bearer ${_firstKey(config.apiKey)}',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('API 返回错误: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final ids = <String>[];

      if (decoded is Map && decoded['data'] is List) {
        for (final item in (decoded['data'] as List)) {
          if (item is Map && item['id'] is String) {
            ids.add(item['id'] as String);
          }
        }
      } else if (decoded is List) {
        for (final item in decoded) {
          if (item is String) {
            ids.add(item);
          } else if (item is Map && item['id'] is String) {
            ids.add(item['id'] as String);
          }
        }
      }

      ids.removeWhere(
        (m) =>
            m.contains('whisper') ||
            m.contains('tts') ||
            m.contains('embedding') ||
            m.contains('moderation'),
      );

      final unique = <String>{};
      final result = <ApiModel>[];
      for (final id in ids) {
        final trimmed = id.trim();
        if (trimmed.isEmpty) continue;
        if (!unique.add(trimmed)) continue;
        result.add(ApiModel.fromLegacy(trimmed));
      }
      return result;
    } finally {
      client.close();
    }
  }

  static Uri _joinUri(String base, String path) {
    String cleanBase = base.trim();
    if (cleanBase.endsWith('/')) {
      cleanBase = cleanBase.substring(0, cleanBase.length - 1);
    }
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    if (cleanBase.endsWith(cleanPath)) return Uri.parse(cleanBase);
    return Uri.parse('$cleanBase/$cleanPath');
  }

  static String _firstKey(String raw) {
    final key = raw.split(',').first.trim();
    return key;
  }
}

