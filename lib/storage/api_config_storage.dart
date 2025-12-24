import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/models/api_config.dart';

/// API 配置存储服务
class ApiConfigStorage {
  static const String _boxName = 'api_configs';
  static Box<String>? _box;

  /// 初始化
  static Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  static Box<String> get _safeBox {
    if (_box == null) {
      throw Exception('ApiConfigStorage not initialized');
    }
    return _box!;
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
    // 按创建时间排序
    configs.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.now();
      final bTime = b.createdAt ?? DateTime.now();
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

  /// 设置活动配置
  static Future<void> setActiveConfig(String id) async {
    // 取消所有活动的配置
    final configs = getAllConfigs();
    for (final config in configs) {
      if (config.isActive) {
        await saveConfig(config.copyWith(isActive: false));
      }
    }
    // 设置新的活动配置
    final target = getConfig(id);
    if (target != null) {
      await saveConfig(target.copyWith(isActive: true));
    }
  }

  /// 获取当前活动的配置
  static ApiConfig? getActiveConfig() {
    final configs = getAllConfigs();
    try {
      return configs.firstWhere((c) => c.isActive);
    } catch (_) {
      return null;
    }
  }

  /// 检查是否已配置 API
  static bool hasConfig() {
    return getActiveConfig() != null;
  }
}
