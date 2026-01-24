import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/models/api_config.dart';

/// API 配置存储服务
class ApiConfigStorage {
  static const String _boxName = 'api_configs';
  static Box<String>? _box;

  /// 初始化
  static Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
    await _cleanupBuiltInProviders();
  }

  static Box<String> get _safeBox {
    if (_box == null) {
      throw Exception('ApiConfigStorage not initialized');
    }
    return _box!;
  }

  static ValueListenable<Box<String>> listenable() {
    return _safeBox.listenable();
  }

  /// 获取所有 API 配置
  static List<ApiConfig> getAllConfigs() {
    final configs = <ApiConfig>[];
    for (final key in _safeBox.keys) {
      final json = _safeBox.get(key);
      if (json != null) {
        try {
          configs.add(ApiConfig.fromMap(jsonDecode(json)));
        } catch (_) {}
      }
    }
    // 先按 sortOrder，再按创建时间排序
    configs.sort((a, b) {
      final aOrder = a.sortOrder ?? 1 << 30;
      final bOrder = b.sortOrder ?? 1 << 30;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return configs;
  }

  /// 获取单个配置
  static ApiConfig? getConfig(String id) {
    final json = _safeBox.get(id);
    if (json == null) return null;
    try {
      return ApiConfig.fromMap(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  /// 保存配置
  static Future<void> saveConfig(ApiConfig config) async {
    await _safeBox.put(config.id, jsonEncode(config.toMap()));
  }

  /// 删除配置
  static Future<void> deleteConfig(String id) async {
    await _safeBox.delete(id);
  }

  /// 启用/禁用配置（允许多个同时启用）
  static Future<void> setEnabled(String id, bool enabled) async {
    final target = getConfig(id);
    if (target == null) return;
    await saveConfig(target.copyWith(isActive: enabled));
  }

  /// 获取所有已启用的配置
  static List<ApiConfig> getEnabledConfigs() {
    return getAllConfigs().where((c) => c.isActive).toList();
  }

  static Future<void> _cleanupBuiltInProviders() async {
    // 仅保留用户手动添加的服务商：清理历史遗留的内置服务商。
    final existing = getAllConfigs();
    final builtInIds = existing
        .where((c) => c.builtIn || c.id.startsWith('builtin-'))
        .map((c) => c.id)
        .toList();

    for (final id in builtInIds) {
      await deleteConfig(id);
    }
  }
}
