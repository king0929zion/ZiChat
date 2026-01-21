import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/pages/model_services/model_service_widgets.dart';
import 'package:zichat/storage/ai_config_storage.dart';
import 'package:zichat/storage/api_config_storage.dart';
import 'package:zichat/widgets/weui/weui_switch.dart';

class BaseModelsPage extends StatelessWidget {
  const BaseModelsPage({super.key});

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
          '基础模型',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ValueListenableBuilder<Box>(
              valueListenable: Hive.box(AiConfigStorage.boxName).listenable(),
              builder: (context, _, __) {
                return ValueListenableBuilder<Box<String>>(
                  valueListenable: ApiConfigStorage.listenable(),
                  builder: (context, ___, ____) {
                    return _BaseModelsBody();
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

class _BaseModelsBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final configs = ApiConfigStorage.getAllConfigs();
    final enabledConfigs = configs.where((c) => c.isActive).toList();
    final pickableConfigs = enabledConfigs;

    final baseConfig =
        Hive.box(AiConfigStorage.boxName).get('base_models') as Map?;
    final models = AiBaseModelsConfig.fromMap(baseConfig) ?? const AiBaseModelsConfig();

    if (configs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        children: const [
          Icon(Icons.api_outlined, size: 56, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            '还没有服务商',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '请先在“模型服务”中添加并启用服务商',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      );
    }

    if (pickableConfigs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        children: const [
          Icon(Icons.toggle_off_outlined, size: 56, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            '还没有启用的服务商',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '请先在“模型服务”中启用至少一个服务商',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      );
    }

    final chatLabel = _formatSelectionLabel(
      configs: configs,
      configId: models.chatConfigId,
      model: models.chatModel,
      placeholder: '未设置',
    );
    final ocrLabel = _formatSelectionLabel(
      configs: configs,
      configId: models.ocrConfigId,
      model: models.ocrModel,
      placeholder: '未设置（可选）',
    );
    final imageGenLabel = _formatSelectionLabel(
      configs: configs,
      configId: models.imageGenConfigId,
      model: models.imageGenModel,
      placeholder: '未设置（可选）',
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const WeuiSectionTitle(title: '默认对话'),
        WeuiInsetCard(
          child: Column(
            children: [
              _SettingRow(
                title: '默认对话模型',
                value: chatLabel,
                onTap: () async {
                  final selection = await _showModelPicker(
                    context: context,
                    title: '选择默认对话模型',
                    configs: pickableConfigs,
                    initialConfigId: models.chatConfigId,
                    initialModel: models.chatModel,
                    allowClear: false,
                  );
                  if (selection == null) return;
                  await AiConfigStorage.saveBaseModelsConfig(
                    models.copyWith(
                      chatConfigId: selection.configId,
                      chatModel: selection.model,
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: AppColors.divider),
              _SettingRow(
                title: '对话模型支持识图',
                description: '开启后会把图片随消息一起发给对话模型',
                showArrow: false,
                trailing: WeuiSwitch(
                  value: models.chatModelSupportsImage,
                  onChanged: (v) => AiConfigStorage.saveBaseModelsConfig(
                    models.copyWith(chatModelSupportsImage: v),
                  ),
                ),
              ),
            ],
          ),
        ),

        const WeuiSectionTitle(title: 'OCR（可选）'),
        WeuiInsetCard(
          child: Column(
            children: [
              _SettingRow(
                title: '启用 OCR 回退',
                description: '对话模型不支持识图时，先用 OCR 模型解析图片',
                showArrow: false,
                trailing: WeuiSwitch(
                  value: models.ocrEnabled,
                  onChanged: (v) async {
                    if (v && !models.hasOcrModel) {
                      final selection = await _showModelPicker(
                        context: context,
                        title: '选择 OCR 模型',
                        configs: pickableConfigs,
                        initialConfigId: models.ocrConfigId,
                        initialModel: models.ocrModel,
                        allowClear: true,
                      );
                      if (selection == null) return;
                      if (selection.configId.trim().isEmpty ||
                          selection.model.trim().isEmpty) {
                        await AiConfigStorage.saveBaseModelsConfig(
                          models.copyWith(
                            ocrEnabled: false,
                            ocrConfigId: null,
                            ocrModel: null,
                          ),
                        );
                        return;
                      }
                      await AiConfigStorage.saveBaseModelsConfig(
                        models.copyWith(
                          ocrEnabled: true,
                          ocrConfigId: selection.configId,
                          ocrModel: selection.model,
                        ),
                      );
                      return;
                    }
                    await AiConfigStorage.saveBaseModelsConfig(
                      models.copyWith(ocrEnabled: v),
                    );
                  },
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _SettingRow(
                title: 'OCR 模型',
                value: ocrLabel,
                enabled: models.ocrEnabled,
                onTap: () async {
                  final selection = await _showModelPicker(
                    context: context,
                    title: '选择 OCR 模型',
                    configs: pickableConfigs,
                    initialConfigId: models.ocrConfigId,
                    initialModel: models.ocrModel,
                    allowClear: true,
                  );
                  if (selection == null) return;
                  if (selection.configId.trim().isEmpty ||
                      selection.model.trim().isEmpty) {
                    await AiConfigStorage.saveBaseModelsConfig(
                      models.copyWith(
                        ocrEnabled: false,
                        ocrConfigId: null,
                        ocrModel: null,
                      ),
                    );
                    return;
                  }
                  await AiConfigStorage.saveBaseModelsConfig(
                    models.copyWith(
                      ocrConfigId: selection.configId,
                      ocrModel: selection.model,
                      ocrEnabled: true,
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: AppColors.divider),
              _SettingRow(
                title: 'OCR 模型支持识图',
                showArrow: false,
                enabled: models.ocrEnabled,
                trailing: WeuiSwitch(
                  value: models.ocrModelSupportsImage,
                  onChanged: models.ocrEnabled
                      ? (v) => AiConfigStorage.saveBaseModelsConfig(
                            models.copyWith(ocrModelSupportsImage: v),
                          )
                      : null,
                  enabled: models.ocrEnabled,
                ),
              ),
            ],
          ),
        ),

        const WeuiSectionTitle(title: '生图（可选）'),
        WeuiInsetCard(
          child: Column(
            children: [
              _SettingRow(
                title: '生图模型',
                value: imageGenLabel,
                onTap: () async {
                  final selection = await _showModelPicker(
                    context: context,
                    title: '选择生图模型',
                    configs: pickableConfigs,
                    initialConfigId: models.imageGenConfigId,
                    initialModel: models.imageGenModel,
                    allowClear: true,
                  );
                  if (selection == null) return;
                  if (selection.configId.trim().isEmpty ||
                      selection.model.trim().isEmpty) {
                    await AiConfigStorage.saveBaseModelsConfig(
                      models.copyWith(
                        imageGenConfigId: null,
                        imageGenModel: null,
                      ),
                    );
                    return;
                  }
                  await AiConfigStorage.saveBaseModelsConfig(
                    models.copyWith(
                      imageGenConfigId: selection.configId,
                      imageGenModel: selection.model,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatSelectionLabel({
    required List<ApiConfig> configs,
    required String? configId,
    required String? model,
    required String placeholder,
  }) {
    final m = (model ?? '').trim();
    final id = (configId ?? '').trim();
    if (m.isEmpty || id.isEmpty) return placeholder;
    final provider = configs.where((c) => c.id == id).firstOrNull;
    final name = provider?.name ?? '未知';
    return '$m | $name';
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    this.description,
    this.value,
    this.onTap,
    this.trailing,
    this.showArrow = true,
    this.enabled = true,
  });

  final String title;
  final String? description;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showArrow;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final clickable = enabled && onTap != null;
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: clickable
            ? () {
                HapticFeedback.selectionClick();
                onTap?.call();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textDisabled,
                      ),
                    ),
                    if (description != null && description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      value!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        color: enabled
                            ? AppColors.textSecondary
                            : AppColors.textDisabled,
                      ),
                    ),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (showArrow) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: enabled ? AppColors.textHint : AppColors.textDisabled,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelSelection {
  const _ModelSelection({required this.configId, required this.model});

  final String configId;
  final String model;
}

Future<_ModelSelection?> _showModelPicker({
  required BuildContext context,
  required String title,
  required List<ApiConfig> configs,
  String? initialConfigId,
  String? initialModel,
  required bool allowClear,
}) async {
  if (configs.isEmpty) return null;
  final initConfig = (initialConfigId == null || initialConfigId.trim().isEmpty)
      ? null
      : configs.where((c) => c.id == initialConfigId).firstOrNull;
  final selectedConfig =
      initConfig ?? configs.firstWhere((c) => c.isActive, orElse: () => configs.first);
  final fallbackModel =
      selectedConfig.selectedModel ?? (selectedConfig.models.isEmpty ? null : selectedConfig.models.first);
  final initSelectedModel =
      (initialModel != null && selectedConfig.models.contains(initialModel))
          ? initialModel
          : fallbackModel;

  return showModalBottomSheet<_ModelSelection>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return _ModelPickerSheet(
        title: title,
        configs: configs,
        initialConfigId: selectedConfig.id,
        initialModel: initSelectedModel,
        allowClear: allowClear,
      );
    },
  );
}

class _ModelPickerSheet extends StatefulWidget {
  const _ModelPickerSheet({
    required this.title,
    required this.configs,
    required this.initialConfigId,
    required this.initialModel,
    required this.allowClear,
  });

  final String title;
  final List<ApiConfig> configs;
  final String initialConfigId;
  final String? initialModel;
  final bool allowClear;

  @override
  State<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<_ModelPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late String _configId = widget.initialConfigId;
  late String? _model = widget.initialModel;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.configs.where((c) => c.id == _configId).firstOrNull ??
        widget.configs.first;
    final allModels = config.models;
    final query = _searchController.text.trim().toLowerCase();
    final models = query.isEmpty
        ? allModels
        : allModels.where((m) => m.toLowerCase().contains(query)).toList();
    final selectedModel =
        _model ?? config.selectedModel ?? (allModels.isEmpty ? null : allModels.first);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: AppColors.surface,
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.72,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              builder: (ctx, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    Center(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    WeuiPillSearchBar(
                      controller: _searchController,
                      hintText: '搜索…',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in widget.configs)
                          _ProviderChip(
                            name: c.name,
                            selected: c.id == _configId,
                            onTap: () => setState(() {
                              _configId = c.id;
                              _model = c.selectedModel ??
                                  (c.models.isEmpty ? null : c.models.first);
                              _searchController.clear();
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.allowClear)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(
                            const _ModelSelection(configId: '', model: ''),
                          ),
                          child: const Text('清除（不使用）'),
                        ),
                      ),
                    if (models.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                          '该服务商暂无匹配模型，请先在服务商详情页导入模型。',
                          style: TextStyle(fontSize: 13, color: AppColors.textHint),
                        ),
                      )
                    else
                      WeuiInsetCard(
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (int i = 0; i < models.length; i++) ...[
                              _ModelPickRow(
                                model: models[i],
                                selected: selectedModel == models[i],
                                onTap: () => Navigator.of(context).pop(
                                  _ModelSelection(
                                    configId: _configId,
                                    model: models[i],
                                  ),
                                ),
                              ),
                              if (i < models.length - 1)
                                const Divider(height: 1, color: AppColors.divider),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
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

class _ProviderChip extends StatelessWidget {
  const _ProviderChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
              width: 0.8,
            ),
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModelPickRow extends StatelessWidget {
  const _ModelPickRow({
    required this.model,
    required this.selected,
    required this.onTap,
  });

  final String model;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: selected
                    ? null
                    : Border.all(color: AppColors.divider, width: 1.5),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                model,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
