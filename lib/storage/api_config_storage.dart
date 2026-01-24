import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/models/api_config.dart';
import 'package:flutter/foundation.dart';

/// API 配置存储服务
class ApiConfigStorage {
  static const String _boxName = 'api_configs';
  static Box<String>? _box;

  /// 初始化
  static Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
    await _ensureBuiltInProviders();
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

  static Future<void> _ensureBuiltInProviders() async {
    final existing = getAllConfigs();
    final existingIds = existing.map((c) => c.id).toSet();

    // 移除已废弃的内置服务商（不再支持 Gemini / Claude 的特殊 API 格式）
    if (existingIds.contains('builtin-gemini')) {
      await deleteConfig('builtin-gemini');
      existingIds.remove('builtin-gemini');
    }
    if (existingIds.contains('builtin-claude')) {
      await deleteConfig('builtin-claude');
      existingIds.remove('builtin-claude');
    }

    final builtIns = <ApiConfig>[
      ApiConfig(
        id: 'builtin-openai',
        type: ProviderType.openai,
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        apiKey: '',
        models: const [
          ApiModel(
            id: 'gpt-4o-mini',
            modelId: 'gpt-4o-mini',
            displayName: 'GPT-4o mini',
            inputModalities: [ModelModality.text, ModelModality.image],
            abilities: [ModelAbility.tool, ModelAbility.reasoning],
          ),
          ApiModel(
            id: 'gpt-4o',
            modelId: 'gpt-4o',
            displayName: 'GPT-4o',
            inputModalities: [ModelModality.text, ModelModality.image],
            abilities: [ModelAbility.tool, ModelAbility.reasoning],
          ),
        ],
        isActive: false,
        createdAt: DateTime.now(),
        sortOrder: 0,
        builtIn: true,
      ),
      ApiConfig(
        id: 'builtin-aihubmix',
        type: ProviderType.openai,
        name: 'AiHubMix',
        baseUrl: 'https://aihubmix.com/v1',
        apiKey: '',
        models: const [],
        isActive: false,
        createdAt: DateTime.now(),
        sortOrder: 10,
        builtIn: true,
      ),
      ApiConfig(
        id: 'builtin-siliconflow',
        type: ProviderType.openai,
        name: '硅基流动',
        baseUrl: 'https://api.siliconflow.cn/v1',
        apiKey: '',
        models: const [],
        isActive: false,
        createdAt: DateTime.now(),
        sortOrder: 11,
        builtIn: true,
        balanceOption: const BalanceOption(
          enabled: true,
          apiPath: '/user/info',
          resultPath: 'data.totalBalance',
        ),
      ),
      ApiConfig(
        id: 'builtin-deepseek',
        type: ProviderType.openai,
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        apiKey: '',
        models: const [],
        isActive: false,
        createdAt: DateTime.now(),
        sortOrder: 12,
        builtIn: true,
        balanceOption: const BalanceOption(
          enabled: true,
          apiPath: '/user/balance',
          resultPath: 'balance_infos[0].total_balance',
        ),
      ),
      ApiConfig(
        id: 'builtin-openrouter',
        type: ProviderType.openai,
        name: 'OpenRouter',
        baseUrl: 'https://openrouter.ai/api/v1',
        apiKey: '',
        models: const [],
        isActive: false,
        createdAt: DateTime.now(),
        sortOrder: 13,
        builtIn: true,
        balanceOption: const BalanceOption(
          enabled: true,
          apiPath: '/credits',
          resultPath: 'data.total_credits - data.total_usage',
        ),
      ),
      ApiConfig(
        id: 'builtin-dashscope',
        type: ProviderType.openai,
        name: '阿里云百炼',
        baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
        apiKey: '',
        models: const [],
        isActive: false,
        createdAt: DateTime.now(),
        sortOrder: 14,
        builtIn: true,
      ),
      ApiConfig(
        id: 'builtin-volcengine',
        type: ProviderType.openai,
        name: '火山引擎',
        baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
        apiKey: '',
        models: const [],
        isActive: false,
        createdAt: DateTime.now(),
        sortOrder: 15,
        builtIn: true,
        chatCompletionsPath: '/chat/completions',
      ),
      ApiConfig(
        id: 'builtin-moonshot',
        type: ProviderType.openai,
        name: '月之暗面',
        baseUrl: 'https://api.moonshot.cn/v1',
        apiKey: '',
        models: const [],
        isActive: false,
        createdAt: DateTime.now(),
        sortOrder: 16,
        builtIn: true,
        balanceOption: const BalanceOption(
          enabled: true,
          apiPath: '/users/me/balance',
          resultPath: 'data.available_balance',
        ),
      ),
      ApiConfig(
        id: 'builtin-bigmodel',
        type: ProviderType.openai,
        name: '智谱 AI',
        baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
        apiKey: '',
        models: const [],
        isActive: false,
        createdAt: DateTime.now(),
        sortOrder: 17,
        builtIn: true,
      ),
      ApiConfig(
        id: 'builtin-stepfun',
        type: ProviderType.openai,
        name: '阶跃星辰',
        baseUrl: 'https://api.stepfun.com/v1',
        apiKey: '',
        models: const [],
        isActive: false,
        createdAt: DateTime.now(),
        sortOrder: 18,
        builtIn: true,
      ),
      ApiConfig(
        id: 'builtin-302ai',
        type: ProviderType.openai,
        name: '302.AI',
        baseUrl: 'https://api.302.ai/v1',
        apiKey: '',
        models: const [],
        isActive: false,
        createdAt: DateTime.now(),
        sortOrder: 19,
        builtIn: true,
      ),
    ];

    for (final builtin in builtIns) {
      if (existingIds.contains(builtin.id)) continue;
      await saveConfig(builtin);
    }
  }
}
