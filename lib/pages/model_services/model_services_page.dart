import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/pages/model_services/api_service_page.dart';
import 'package:zichat/pages/model_services/base_models_page.dart';
import 'package:zichat/pages/model_services/provider_detail_page.dart';
import 'package:zichat/pages/model_services/model_service_widgets.dart';
import 'package:zichat/storage/ai_config_storage.dart';
import 'package:zichat/storage/api_config_storage.dart';

/// 模型服务（供应商）列表页
class ModelServicesPage extends StatefulWidget {
  const ModelServicesPage({super.key});

  @override
  State<ModelServicesPage> createState() => _ModelServicesPageState();
}

class _ModelServicesPageState extends State<ModelServicesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ApiConfig> _filterConfigs(List<ApiConfig> configs) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return configs;
    return configs
        .where((c) => c.name.trim().toLowerCase().contains(q))
        .toList();
  }

  Future<void> _openProvider(ApiConfig config) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProviderDetailPage(configId: config.id)),
    );
  }

  Future<void> _addProvider() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ApiServicePage()),
    );
  }

  Future<void> _openBaseModels() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BaseModelsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: const Border(bottom: BorderSide.none),
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: WeuiCircleIconButton(
            assetName: AppAssets.iconGoBack,
            backgroundColor: const Color(0x0D000000),
            iconSize: 18,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text(
          '模型服务',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: WeuiCircleIconButton(
              assetName: AppAssets.iconCirclePlus,
              backgroundColor: const Color(0x0D000000),
              iconSize: 20,
              onTap: _addProvider,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ValueListenableBuilder<Box>(
              valueListenable: Hive.box(AiConfigStorage.boxName).listenable(
                keys: const ['base_models'],
              ),
              builder: (context, _, __) {
                final raw = Hive.box(AiConfigStorage.boxName).get('base_models');
                final baseModels = raw is Map
                    ? (AiBaseModelsConfig.fromMap(raw) ??
                        const AiBaseModelsConfig())
                    : const AiBaseModelsConfig();

                return ValueListenableBuilder<Box<String>>(
                  valueListenable: ApiConfigStorage.listenable(),
                  builder: (context, box, _) {
                    final configs = ApiConfigStorage.getAllConfigs();
                    final filtered = _filterConfigs(configs);

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        WeuiPillSearchBar(
                          controller: _searchController,
                          hintText: '搜索厂商或模型',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _BaseModelsSummaryCard(
                          baseModels: baseModels,
                          configs: configs,
                          onTap: _openBaseModels,
                        ),
                        const SizedBox(height: 16),
                        if (configs.isEmpty)
                          _EmptyState(onAdd: _addProvider)
                        else if (filtered.isEmpty)
                          _NoSearchResult(query: _searchController.text)
                        else ...[
                          _StatsBar(configs: configs, filtered: filtered),
                          const SizedBox(height: 8),
                          for (final config in filtered) ...[
                            ModelServiceCard(
                              onTap: () => _openProvider(config),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  ProviderAvatar(name: config.name),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          config.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              config.models.isEmpty
                                                  ? '暂无模型'
                                                  : '${config.models.length} 个模型',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            if (config.isActive) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.online,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                '已启用',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.online,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        _RoleTags(
                                          labels: _rolesForConfig(
                                            baseModels: baseModels,
                                            configId: config.id,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textHint,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<String> _rolesForConfig({
    required AiBaseModelsConfig baseModels,
    required String configId,
  }) {
    final roles = <String>[];
    if (baseModels.hasChatModel && baseModels.chatConfigId == configId) {
      roles.add('默认对话');
    }
    if (baseModels.ocrEnabled &&
        baseModels.hasOcrModel &&
        baseModels.ocrConfigId == configId) {
      roles.add('OCR');
    }
    if (baseModels.hasImageGenModel && baseModels.imageGenConfigId == configId) {
      roles.add('生图');
    }
    return roles;
  }
}

class _RoleTags extends StatelessWidget {
  const _RoleTags({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final label in labels) WeuiTag(label: label),
        ],
      ),
    );
  }
}

class _BaseModelsSummaryCard extends StatelessWidget {
  const _BaseModelsSummaryCard({
    required this.baseModels,
    required this.configs,
    required this.onTap,
  });

  final AiBaseModelsConfig baseModels;
  final List<ApiConfig> configs;
  final VoidCallback onTap;

  String _formatSelection({
    required String? configId,
    required String? model,
    required String placeholder,
  }) {
    final id = (configId ?? '').trim();
    final m = (model ?? '').trim();
    if (id.isEmpty || m.isEmpty) return placeholder;
    final provider = configs.where((c) => c.id == id).firstOrNull;
    final name = provider?.name ?? '未知服务商';
    final disabledSuffix =
        (provider != null && !provider.isActive) ? '（未启用）' : '';
    return '$m | $name$disabledSuffix';
  }

  @override
  Widget build(BuildContext context) {
    final chatLabel = _formatSelection(
      configId: baseModels.chatConfigId,
      model: baseModels.chatModel,
      placeholder: '未设置（必选）',
    );
    final ocrLabel = baseModels.ocrEnabled
        ? _formatSelection(
            configId: baseModels.ocrConfigId,
            model: baseModels.ocrModel,
            placeholder: '未选择模型',
          )
        : '未启用';
    final imageGenLabel = _formatSelection(
      configId: baseModels.imageGenConfigId,
      model: baseModels.imageGenModel,
      placeholder: '未配置',
    );

    final chatProvider = configs
        .where((c) => c.id == (baseModels.chatConfigId ?? '').trim())
        .firstOrNull;
    final chatOk = baseModels.hasChatModel && (chatProvider?.isActive ?? false);

    return WeuiInsetCard(
      margin: EdgeInsets.zero,
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tune,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '基础模型',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '默认对话：$chatLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: chatOk
                              ? AppColors.textSecondary
                              : AppColors.error,
                          fontWeight:
                              chatOk ? FontWeight.w400 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'OCR：$ocrLabel · 生图：$imageGenLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: AppColors.textHint,
                ),
              ],
            ),
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
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const Icon(Icons.api_outlined, size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          const Text(
            '暂无模型服务',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '点击右上角 + 添加服务商',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onAdd,
            child: const Text('添加模型服务'),
          ),
        ],
      ),
    );
  }
}

class _NoSearchResult extends StatelessWidget {
  const _NoSearchResult({this.query = ''});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off, size: 32, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? '暂无数据' : '未找到匹配结果',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            query.isEmpty ? '请添加服务商' : '试试换个关键词',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.configs, required this.filtered});

  final List<ApiConfig> configs;
  final List<ApiConfig> filtered;

  @override
  Widget build(BuildContext context) {
    final enabledCount = configs.where((c) => c.isActive).length;
    final filteredEnabled = filtered.where((c) => c.isActive).length;

    return Row(
      children: [
        Text(
          '共 ${filtered.length} 个服务商',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        if (filteredEnabled > 0) ...[
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.online,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$filteredEnabled 个已启用',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.online,
            ),
          ),
        ],
      ],
    );
  }
}
