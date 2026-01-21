import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/pages/model_services/api_service_page.dart';
import 'package:zichat/pages/model_services/base_models_page.dart';
import 'package:zichat/pages/model_services/provider_detail_page.dart';
import 'package:zichat/pages/model_services/model_service_widgets.dart';
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
      backgroundColor: AppColors.surface,
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
            padding: const EdgeInsets.only(right: 4),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: _openBaseModels,
                  child: const Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0x0D000000),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.tune,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
            child: ValueListenableBuilder<Box<String>>(
              valueListenable: ApiConfigStorage.listenable(),
              builder: (context, box, _) {
                final configs = ApiConfigStorage.getAllConfigs();
                final filtered = _filterConfigs(configs);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    WeuiPillSearchBar(
                      controller: _searchController,
                      hintText: '输入厂商名称',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    if (configs.isEmpty)
                      _EmptyState(onAdd: _addProvider)
                    else if (filtered.isEmpty)
                      const _NoSearchResult()
                    else
                      ...[
                        for (final config in filtered) ...[
                          ModelServiceCard(
                            onTap: () => _openProvider(config),
                            child: Row(
                              children: [
                                ProviderAvatar(name: config.name),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    config.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (config.isActive)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.online,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
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
  const _NoSearchResult();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          const Text(
            '未找到匹配的厂商',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '试试换个关键词',
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
