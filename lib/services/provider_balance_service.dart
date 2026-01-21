import 'dart:async';
import 'dart:convert';

import 'package:zichat/models/api_config.dart';
import 'package:zichat/services/provider_http_client.dart';

class ProviderBalanceService {
  static Future<num> fetchBalance(ApiConfig config) async {
    if (!config.balanceOption.enabled) {
      throw Exception('该服务商未配置余额接口');
    }

    final client = ProviderHttpClient.create(config);
    try {
      final apiPath = config.balanceOption.apiPath.trim();
      final uri = _joinUri(
        config.baseUrl,
        apiPath.startsWith('/') ? apiPath.substring(1) : apiPath,
      );

      final response = await client
          .get(
            uri,
            headers: _headersForProvider(config),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('API 返回错误: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final value = _evalExpression(decoded, config.balanceOption.resultPath);
      if (value is num) return value;
      if (value is String) return num.parse(value);
      throw Exception('余额字段不是数字');
    } finally {
      client.close();
    }
  }

  static Map<String, String> _headersForProvider(ApiConfig config) {
    switch (config.type) {
      case ProviderType.claude:
        return <String, String>{
          'x-api-key': _firstKey(config.apiKey),
          'anthropic-version': '2023-06-01',
          'Accept': 'application/json',
        };
      case ProviderType.google:
        return const <String, String>{'Accept': 'application/json'};
      case ProviderType.openai:
        return <String, String>{
          'Authorization': 'Bearer ${_firstKey(config.apiKey)}',
          'Accept': 'application/json',
        };
    }
  }

  static dynamic _evalExpression(dynamic json, String expr) {
    final raw = expr.trim();
    final minusIndex = raw.indexOf(' - ');
    if (minusIndex >= 0) {
      final left = raw.substring(0, minusIndex).trim();
      final right = raw.substring(minusIndex + 3).trim();
      final a = _readNum(_evalExpression(json, left));
      final b = _readNum(_evalExpression(json, right));
      return a - b;
    }

    final plusIndex = raw.indexOf(' + ');
    if (plusIndex >= 0) {
      final left = raw.substring(0, plusIndex).trim();
      final right = raw.substring(plusIndex + 3).trim();
      final a = _readNum(_evalExpression(json, left));
      final b = _readNum(_evalExpression(json, right));
      return a + b;
    }

    return _readPath(json, raw);
  }

  static num _readNum(dynamic raw) {
    if (raw is num) return raw;
    if (raw is String) return num.parse(raw);
    throw Exception('表达式不是数字');
  }

  static dynamic _readPath(dynamic json, String path) {
    if (path.isEmpty) return json;
    dynamic current = json;

    for (final segment in path.split('.')) {
      if (segment.isEmpty) continue;
      current = _readSegment(current, segment);
    }

    return current;
  }

  static dynamic _readSegment(dynamic current, String segment) {
    final firstBracket = segment.indexOf('[');
    if (firstBracket < 0) {
      return _readKey(current, segment);
    }

    final key = segment.substring(0, firstBracket);
    dynamic next = key.isEmpty ? current : _readKey(current, key);

    final bracketPart = segment.substring(firstBracket);
    final matches = RegExp(r'\\[(\\d+)\\]').allMatches(bracketPart);
    for (final m in matches) {
      final idx = int.parse(m.group(1)!);
      if (next is List) {
        if (idx < 0 || idx >= next.length) {
          throw Exception('数组下标越界: $segment');
        }
        next = next[idx];
      } else {
        throw Exception('不是数组: $segment');
      }
    }

    return next;
  }

  static dynamic _readKey(dynamic current, String key) {
    if (current is Map) {
      final map = current.cast<dynamic, dynamic>();
      if (!map.containsKey(key)) {
        throw Exception('字段不存在: $key');
      }
      return map[key];
    }
    throw Exception('不是对象: $key');
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
