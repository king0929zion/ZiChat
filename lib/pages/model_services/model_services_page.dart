import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/pages/model_services/provider_detail_page.dart';
import 'package:zichat/storage/ai_config_storage.dart';
import 'package:zichat/storage/api_config_storage.dart';
import 'package:zichat/widgets/weui/weui.dart';

/// 供应商配置页
class ModelServicesPage extends StatefulWidget {
  const ModelServicesPage({super.key});

  @override
  State<ModelServicesPage> createState() => _ModelServicesPageState();
}

class _ModelServicesPageState extends State<ModelServicesPage> {
  void _toast(String message) => WeuiToast.show(context, message: message);

  List<String> _baseModelRolesForConfig({required String configId}) {
    final raw = Hive.box(AiConfigStorage.boxName).get('base_models');
    if (raw is! Map) return [];
    final base = AiBaseModelsConfig.fromMap(raw) ?? const AiBaseModelsConfig();

    final roles = <String>[];
    if (base.hasChatModel && base.chatConfigId == configId) roles.add('对话模型');
    if (base.hasVisionModel && base.visionConfigId == configId) roles.add('视觉模型');
    if (base.hasImageGenModel && base.imageGenConfigId == configId) roles.add('生图模型');
    return roles;
  }

  Future<void> _openProvider(ApiConfig config) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProviderDetailPage(configId: config.id)),
    );
  }

  Future<void> _addProvider(List<ApiConfig> current) async {
    HapticFeedback.lightImpact();
    final nextOrder = current.isEmpty
        ? 100
        : (current
                .map((c) => c.sortOrder ?? 100)
                .reduce((a, b) => a > b ? a : b) +
            1);

    final now = DateTime.now();
    final id = const Uuid().v4();
    final config = ApiConfig(
      id: id,
      type: ProviderType.openai,
      name: '新服务商',
      baseUrl: '',
      apiKey: '',
      models: const [],
      isActive: false,
      createdAt: now,
      sortOrder: nextOrder,
      builtIn: false,
    );

    await ApiConfigStorage.saveConfig(config);
    if (!mounted) return;
    await _openProvider(config);
  }

  Future<bool> _confirmDeleteProvider(ApiConfig config) async {
    if (config.builtIn) {
      _toast('内置服务商不可删除');
      return false;
    }

    final refs = _baseModelRolesForConfig(configId: config.id);
    if (refs.isNotEmpty) {
      _toast('该服务商正在用于：${refs.join('、')}');
      return false;
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '删除服务商',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '确定删除“${config.name}”？',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFEDEDED),
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('删除'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return ok == true;
  }

  Future<void> _deleteProvider(ApiConfig config) async {
    HapticFeedback.mediumImpact();
    await ApiConfigStorage.deleteConfig(config.id);
  }

  Future<void> _toggleEnabled(ApiConfig config, bool enabled) async {
    if (!enabled) {
      final refs = _baseModelRolesForConfig(configId: config.id);
      if (refs.isNotEmpty) {
        _toast('该服务商正在用于：${refs.join('、')}');
        return;
      }
    }
    await ApiConfigStorage.setEnabled(config.id, enabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundChat,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundChat,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: SvgPicture.asset(
            AppAssets.iconGoBack,
            width: 12,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
        title: const Text(
          '供应商配置',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              final configs = ApiConfigStorage.getAllConfigs();
              _addProvider(configs);
            },
            icon: SvgPicture.asset(
              AppAssets.iconPlus,
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                AppColors.textPrimary,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ValueListenableBuilder<Box<String>>(
              valueListenable: ApiConfigStorage.listenable(),
              builder: (context, box, _) {
                final configs = ApiConfigStorage.getAllConfigs();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (configs.isEmpty)
                      _EmptyState(onAdd: () => _addProvider(configs))
                    else
                      ...configs.map(
                        (config) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: ValueKey(config.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _confirmDeleteProvider(config),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 18),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                '删除',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            onDismissed: (_) => _deleteProvider(config),
                            child: _ProviderTile(
                              config: config,
                              onTap: () => _openProvider(config),
                              onToggleEnabled: (v) => _toggleEnabled(config, v),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.config,
    required this.onTap,
    required this.onToggleEnabled,
  });

  final ApiConfig config;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleEnabled;

  Color _getProviderColor(ApiConfig config) {
    final name = config.name.toLowerCase();
    if (name.contains('qwen') || name.contains('通义')) return const Color(0xFF6366f1);
    if (name.contains('openai') || name.contains('gpt')) return Colors.black;
    if (name.contains('deepseek')) return const Color(0xFF3b82f6);
    if (name.contains('doubao') || name.contains('豆包')) return const Color(0xFFa855f7);
    if (name.contains('ollama')) return const Color(0xFF16a34a);
    return const Color(0xFF666666);
  }

  String _subtitle(ApiConfig config) {
    final url = config.baseUrl.trim();
    if (url.isEmpty) return '未配置 API 地址与密钥';
    final key = config.apiKey.trim();
    if (key.isEmpty) return '未配置 API 密钥';
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getProviderColor(config);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    AppAssets.iconAiRobot,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(config),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              WeuiSwitch(
                value: config.isActive,
                onChanged: onToggleEnabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEDED),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: SvgPicture.asset(
                AppAssets.iconAiRobot,
                width: 32,
                height: 32,
                colorFilter: const ColorFilter.mode(
                  AppColors.textHint,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '还没有服务商',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '添加一个服务商后即可配置模型',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('添加服务商'),
            ),
          ),
        ],
      ),
    );
  }
}
