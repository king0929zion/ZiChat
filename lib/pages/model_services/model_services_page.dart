import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/pages/model_services/base_models_page.dart';
import 'package:zichat/pages/model_services/provider_detail_page.dart';
import 'package:zichat/pages/model_services/model_service_widgets.dart';
import 'package:zichat/storage/ai_config_storage.dart';
import 'package:zichat/storage/api_config_storage.dart';

/// 模型服务（AI 供应商）列表页：对齐 RikkaHub 的信息架构（搜索/排序/导入导出/快速入口）
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

  Future<void> _openProvider(ApiConfig config) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProviderDetailPage(configId: config.id)),
    );
  }

  Future<void> _openBaseModels() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BaseModelsPage()),
    );
  }

  List<ApiConfig> _filterConfigs(List<ApiConfig> configs) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return configs;
    return configs.where((c) {
      if (c.name.toLowerCase().contains(q)) return true;
      if (c.baseUrl.toLowerCase().contains(q)) return true;
      for (final m in c.models) {
        if (m.modelId.toLowerCase().contains(q)) return true;
        if (m.displayName.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }

  AiBaseModelsConfig _readBaseModels() {
    final raw = Hive.box(AiConfigStorage.boxName).get('base_models');
    if (raw is Map) {
      return AiBaseModelsConfig.fromMap(raw) ?? const AiBaseModelsConfig();
    }
    return const AiBaseModelsConfig();
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

  Future<void> _toggleEnabled({
    required ApiConfig config,
    required bool enabled,
    required AiBaseModelsConfig baseModels,
  }) async {
    if (!enabled) {
      final refs = _rolesForConfig(baseModels: baseModels, configId: config.id);
      if (refs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('该服务商正在用于基础模型：${refs.join('、')}。请先在“基础模型”中更换。'),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    await ApiConfigStorage.setEnabled(config.id, enabled);
  }

  Future<void> _reorderProviders(List<ApiConfig> ordered) async {
    for (int i = 0; i < ordered.length; i++) {
      final c = ordered[i];
      if (c.sortOrder == i) continue;
      await ApiConfigStorage.saveConfig(c.copyWith(sortOrder: i));
    }
  }

  Future<void> _showAddProviderSheet(List<ApiConfig> current) async {
    HapticFeedback.lightImpact();
    final nextOrder = current.isEmpty
        ? 100
        : (current.map((c) => c.sortOrder ?? 100).reduce((a, b) => a > b ? a : b) +
            1);

    final type = await showModalBottomSheet<ProviderType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: AppColors.surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    const _SheetHandle(),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '添加服务商',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    _SheetTile(
                      title: 'OpenAI 兼容',
                      subtitle: '适用于 OpenAI / SiliconFlow / OpenRouter 等兼容接口',
                      onTap: () => Navigator.of(ctx).pop(ProviderType.openai),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _SheetTile(
                      title: 'Gemini',
                      subtitle: 'Google Gemini 官方 API（支持识图）',
                      onTap: () => Navigator.of(ctx).pop(ProviderType.google),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _SheetTile(
                      title: 'Anthropic Claude',
                      subtitle: 'Anthropic Messages API（支持识图）',
                      onTap: () => Navigator.of(ctx).pop(ProviderType.claude),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (type == null) return;

    final now = DateTime.now();
    final id = const Uuid().v4();
    final config = _buildDefaultProvider(
      id: id,
      type: type,
      sortOrder: nextOrder,
      createdAt: now,
    );

    await ApiConfigStorage.saveConfig(config);
    if (!mounted) return;
    await _openProvider(config);
  }

  ApiConfig _buildDefaultProvider({
    required String id,
    required ProviderType type,
    required int sortOrder,
    required DateTime createdAt,
  }) {
    switch (type) {
      case ProviderType.google:
        return ApiConfig(
          id: id,
          type: ProviderType.google,
          name: 'Gemini',
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
          apiKey: '',
          models: const [],
          isActive: false,
          createdAt: createdAt,
          sortOrder: sortOrder,
          builtIn: false,
        );
      case ProviderType.claude:
        return ApiConfig(
          id: id,
          type: ProviderType.claude,
          name: 'Anthropic',
          baseUrl: 'https://api.anthropic.com/v1',
          apiKey: '',
          models: const [],
          isActive: false,
          createdAt: createdAt,
          sortOrder: sortOrder,
          builtIn: false,
        );
      case ProviderType.openai:
        return ApiConfig(
          id: id,
          type: ProviderType.openai,
          name: 'OpenAI 兼容',
          baseUrl: 'https://api.openai.com/v1',
          apiKey: '',
          models: const [],
          isActive: false,
          createdAt: createdAt,
          sortOrder: sortOrder,
          builtIn: false,
        );
    }
  }

  Future<void> _showImportDialog(List<ApiConfig> current) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('导入服务商'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: '粘贴导出内容（JSON 或 base64）',
              border: InputBorder.none,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('导入'),
            ),
          ],
        );
      },
    );

    if (result == null || result.trim().isEmpty) return;

    try {
      final imported = _decodeProviderText(result.trim());
      final now = DateTime.now();
      final nextOrder = current.isEmpty
          ? 100
          : (current
                  .map((c) => c.sortOrder ?? 100)
                  .reduce((a, b) => a > b ? a : b) +
              1);

      final config = imported.copyWith(
        id: const Uuid().v4(),
        builtIn: false,
        sortOrder: nextOrder,
        createdAt: now,
      );

      await ApiConfigStorage.saveConfig(config);
      if (!mounted) return;
      await _openProvider(config);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导入失败：$e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  ApiConfig _decodeProviderText(String text) {
    // 兼容：zichat://provider?data=...
    final lower = text.toLowerCase();
    if (lower.startsWith('zichat://provider?data=')) {
      final data = text.substring('zichat://provider?data='.length);
      final jsonStr = utf8.decode(base64Decode(data));
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ApiConfig.fromMap(map);
    }

    // 兼容：直接 base64
    if (!text.trimLeft().startsWith('{') && !text.trimLeft().startsWith('[')) {
      final jsonStr = utf8.decode(base64Decode(text));
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ApiConfig.fromMap(map);
    }

    final map = jsonDecode(text) as Map<String, dynamic>;
    return ApiConfig.fromMap(map);
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
          IconButton(
            tooltip: '基础模型',
            onPressed: _openBaseModels,
            icon: const Icon(Icons.tune, color: AppColors.textPrimary),
          ),
          IconButton(
            tooltip: '导入',
            onPressed: () {
              final configs = ApiConfigStorage.getAllConfigs();
              _showImportDialog(configs);
            },
            icon: const Icon(Icons.download_outlined, color: AppColors.textPrimary),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: WeuiCircleIconButton(
              assetName: AppAssets.iconCirclePlus,
              backgroundColor: const Color(0x0D000000),
              iconSize: 20,
              onTap: () {
                final configs = ApiConfigStorage.getAllConfigs();
                _showAddProviderSheet(configs);
              },
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
                final baseModels = _readBaseModels();
                return ValueListenableBuilder<Box<String>>(
                  valueListenable: ApiConfigStorage.listenable(),
                  builder: (context, box, _) {
                    final configs = ApiConfigStorage.getAllConfigs();
                    final filtered = _filterConfigs(configs);
                    final isSearching = _searchController.text.trim().isNotEmpty;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: WeuiPillSearchBar(
                            controller: _searchController,
                            hintText: '搜索服务商 / URL / 模型',
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        Expanded(
                          child: configs.isEmpty
                              ? _EmptyState(
                                  onAdd: () => _showAddProviderSheet(configs),
                                )
                              : (filtered.isEmpty
                                  ? _NoSearchResult(query: _searchController.text)
                                  : (isSearching
                                      ? ListView.separated(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            8,
                                            16,
                                            24,
                                          ),
                                          itemBuilder: (ctx, index) {
                                            final c = filtered[index];
                                            return ProviderCard(
                                              config: c,
                                              baseModels: baseModels,
                                              onTap: () => _openProvider(c),
                                              onToggle: (v) => _toggleEnabled(
                                                config: c,
                                                enabled: v,
                                                baseModels: baseModels,
                                              ),
                                              showDragHandle: false,
                                            );
                                          },
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 10),
                                          itemCount: filtered.length,
                                        )
                                      : ReorderableListView.builder(
                                          buildDefaultDragHandles: false,
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            8,
                                            16,
                                            24,
                                          ),
                                          onReorder: (oldIndex, newIndex) async {
                                            if (newIndex > oldIndex) {
                                              newIndex -= 1;
                                            }
                                            final next = List<ApiConfig>.from(
                                              filtered,
                                            );
                                            final item = next.removeAt(oldIndex);
                                            next.insert(newIndex, item);

                                            // 保持当前搜索为空时，filtered == configs 的顺序
                                            await _reorderProviders(next);
                                          },
                                          itemCount: filtered.length,
                                          itemBuilder: (ctx, index) {
                                            final c = filtered[index];
                                            return ProviderCard(
                                              key: ValueKey('provider_${c.id}'),
                                              config: c,
                                              baseModels: baseModels,
                                              onTap: () => _openProvider(c),
                                              onToggle: (v) => _toggleEnabled(
                                                config: c,
                                                enabled: v,
                                                baseModels: baseModels,
                                              ),
                                              showDragHandle: true,
                                              dragIndex: index,
                                            );
                                          },
                                        ))),
                        ),
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
}

class ProviderCard extends StatelessWidget {
  const ProviderCard({
    super.key,
    required this.config,
    required this.baseModels,
    required this.onTap,
    required this.onToggle,
    required this.showDragHandle,
    this.dragIndex,
  });

  final ApiConfig config;
  final AiBaseModelsConfig baseModels;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final bool showDragHandle;
  final int? dragIndex;

  List<String> _roles() {
    final roles = <String>[];
    if (baseModels.hasChatModel && baseModels.chatConfigId == config.id) {
      roles.add('默认对话');
    }
    if (baseModels.ocrEnabled &&
        baseModels.hasOcrModel &&
        baseModels.ocrConfigId == config.id) {
      roles.add('OCR');
    }
    if (baseModels.hasImageGenModel && baseModels.imageGenConfigId == config.id) {
      roles.add('生图');
    }
    return roles;
  }

  String _typeLabel() {
    switch (config.type) {
      case ProviderType.google:
        return 'Gemini';
      case ProviderType.claude:
        return 'Claude';
      case ProviderType.openai:
        return 'OpenAI 兼容';
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = _roles();
    final host = Uri.tryParse(config.baseUrl)?.host;
    final subtitle = (host == null || host.trim().isEmpty) ? config.baseUrl : host;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProviderLeading(type: config.type, name: config.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            config.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: config.isActive,
                          onChanged: onToggle,
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        WeuiTag(label: _typeLabel()),
                        if (config.models.isNotEmpty)
                          WeuiTag(label: '${config.models.length} 模型'),
                        if (roles.isNotEmpty) ...[
                          for (final role in roles) WeuiTag(label: role),
                        ],
                        if (config.builtIn) WeuiTag(label: '内置'),
                      ],
                    ),
                  ],
                ),
              ),
              if (showDragHandle)
                ReorderableDragStartListener(
                  index: dragIndex ?? 0,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6, top: 6),
                    child: Icon(
                      Icons.drag_handle,
                      size: 20,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderLeading extends StatelessWidget {
  const _ProviderLeading({required this.type, required this.name});

  final ProviderType type;
  final String name;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final IconData icon;
    switch (type) {
      case ProviderType.google:
        bg = const Color(0x1434A853);
        icon = Icons.auto_awesome;
        break;
      case ProviderType.claude:
        bg = const Color(0x14FF6A00);
        icon = Icons.blur_on;
        break;
      case ProviderType.openai:
        bg = const Color(0x1407C160);
        icon = Icons.hub_outlined;
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 22, color: AppColors.textPrimary),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.textDisabled.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
      children: [
        const Icon(Icons.api_outlined, size: 56, color: AppColors.textHint),
        const SizedBox(height: 12),
        const Text(
          '暂无模型服务',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '添加服务商后，才能在“基础模型”中选择默认对话 / OCR / 生图模型。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton(
          onPressed: onAdd,
          child: const Text('添加服务商'),
        ),
      ],
    );
  }
}

class _NoSearchResult extends StatelessWidget {
  const _NoSearchResult({this.query = ''});

  final String query;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFF2F2F2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.search_off, size: 32, color: AppColors.textHint),
        ),
        const SizedBox(height: 16),
        Text(
          query.isEmpty ? '暂无数据' : '未找到匹配结果',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          query.isEmpty ? '请添加服务商' : '试试换个关键词',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
