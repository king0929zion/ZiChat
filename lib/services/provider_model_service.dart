import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zichat/models/api_config.dart';
import 'package:zichat/services/provider_http_client.dart';

class ProviderModelService {
  static Future<List<ApiModel>> detectModels(ApiConfig config) async {
    switch (config.type) {
      case ProviderType.google:
        return _detectGeminiModels(config);
      case ProviderType.claude:
        return _detectClaudeModels(config);
      case ProviderType.openai:
        return _detectOpenAIModels(config);
    }
  }

  static Future<List<ApiModel>> _detectOpenAIModels(ApiConfig config) async {
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

  static Future<List<ApiModel>> _detectGeminiModels(ApiConfig config) async {
    final client = ProviderHttpClient.create(config);
    try {
      final base = _joinUri(config.baseUrl, 'models');
      final uri = base.replace(
        queryParameters: <String, String>{
          ...base.queryParameters,
          'key': _firstKey(config.apiKey),
        },
      );

      final response = await client
          .get(uri, headers: const <String, String>{'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('API 返回错误: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final ids = <String>[];

      if (decoded is Map && decoded['models'] is List) {
        for (final item in (decoded['models'] as List)) {
          if (item is Map && item['name'] is String) {
            final name = (item['name'] as String).trim();
            if (name.startsWith('models/')) {
              ids.add(name.substring('models/'.length));
            } else {
              ids.add(name);
            }
          }
        }
      }

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

  static Future<List<ApiModel>> _detectClaudeModels(ApiConfig config) async {
    final client = ProviderHttpClient.create(config);
    try {
      final uri = _joinUri(config.baseUrl, 'models');
      final response = await client
          .get(
            uri,
            headers: <String, String>{
              'x-api-key': _firstKey(config.apiKey),
              'anthropic-version': '2023-06-01',
              'Accept': 'application/json',
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
      } else if (decoded is Map && decoded['models'] is List) {
        for (final item in (decoded['models'] as List)) {
          if (item is Map && item['id'] is String) {
            ids.add(item['id'] as String);
          }
        }
      }

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

