import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/pages/model_services/api_service_page.dart';
import 'package:zichat/pages/model_services/base_models_page.dart';
import 'package:zichat/pages/model_services/default_assistant_settings_page.dart';
import 'package:zichat/pages/model_services/model_service_widgets.dart';
import 'package:zichat/storage/api_config_storage.dart';

class DefaultAssistantsPage extends StatefulWidget {
  const DefaultAssistantsPage({super.key});

  @override
  State<DefaultAssistantsPage> createState() => _DefaultAssistantsPageState();
}

class _DefaultAssistantsPageState extends State<DefaultAssistantsPage> {
  static const String _slotQuick = 'assistant:quick';
  static const String _slotTranslate = 'assistant:translate';

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

  Future<void> _pickDefaultAssistant(List<ApiConfig> configs) async {
    final active = ApiConfigStorage.getActiveConfig();
    final result = await _showPicker(
      context: context,
      configs: configs,
      initialConfigId: active?.id,
      initialModel: active?.selectedModel,
    );
    if (result == null) return;

    final target = ApiConfigStorage.getConfig(result.configId);
    if (target == null) return;

    await ApiConfigStorage.saveConfig(target.copyWith(selectedModel: result.model));
    await ApiConfigStorage.setActiveConfig(result.configId);
  }

  Future<void> _openDefaultSettings(ApiConfig? active) async {
    if (active == null) return;
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DefaultAssistantSettingsPage(configId: active.id),
      ),
    );
  }

  Future<void> _pickAndSaveSlot(String slotKey, List<ApiConfig> configs) async {
    final current = _loadSlot(slotKey);
    final result = await _showPicker(
      context: context,
      configs: configs,
      initialConfigId: current?.configId,
      initialModel: current?.model,
    );
    if (result == null) return;
    await _saveSlot(slotKey, result);
    if (!mounted) return;
    setState(() {});
  }

  _AssistantSlotSelection? _loadSlot(String slotKey) {
    final box = Hive.box('ai_config');
    final raw = box.get(slotKey);
    if (raw is Map) {
      final id = raw['configId']?.toString();
      final model = raw['model']?.toString();
      if (id != null && model != null && id.isNotEmpty && model.isNotEmpty) {
        return _AssistantSlotSelection(configId: id, model: model);
      }
    }
    return null;
  }

  Future<void> _saveSlot(String slotKey, _AssistantSlotSelection selection) async {
    final box = Hive.box('ai_config');
    await box.put(slotKey, <String, dynamic>{
      'configId': selection.configId,
      'model': selection.model,
    });
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
          '默认助手',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openBaseModels,
            icon: const Icon(Icons.tune, size: 22, color: AppColors.link),
            splashRadius: 18,
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
                final active = ApiConfigStorage.getActiveConfig();
                final quick = _loadSlot(_slotQuick);
                final translate = _loadSlot(_slotTranslate);
                final quickConfig =
                    quick == null ? null : ApiConfigStorage.getConfig(quick.configId);
                final translateConfig = translate == null
                    ? null
                    : ApiConfigStorage.getConfig(translate.configId);

                if (configs.isEmpty) {
                  return _EmptyAssistants(onAdd: _addProvider);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _AssistantSection(
                      icon: Icons.chat_bubble_outline,
                      title: '默认助手',
                      onSettings: () => _openDefaultSettings(active),
                      selection: _SelectionLabel(
                        model: active?.selectedModel ??
                            (active?.models.isNotEmpty == true
                                ? active!.models.first
                                : null),
                        provider: active?.name,
                        leadingName: active?.name,
                      ),
                      onTap: () => _pickDefaultAssistant(configs),
                      description: '创建新助手时使用的助手，如果未设置助手，将使用此助手',
                    ),
                    const SizedBox(height: 18),
                    _AssistantSection(
                      icon: Icons.rocket_launch_outlined,
                      title: '快速助手',
                      onSettings:
                          quickConfig == null ? null : () => _openDefaultSettings(quickConfig),
                      selection: _SelectionLabel(
                        model: quick?.model,
                        provider: quick == null
                            ? null
                            : quickConfig?.name,
                        leadingName: quick == null
                            ? null
                            : quickConfig?.name,
                      ),
                      onTap: () => _pickAndSaveSlot(_slotQuick, configs),
                      description: '用于简单任务的助手，例如话题命名和关键字提取',
                    ),
                    const SizedBox(height: 18),
                    _AssistantSection(
                      icon: Icons.translate_outlined,
                      title: '翻译助手',
                      onSettings: translateConfig == null
                          ? null
                          : () => _openDefaultSettings(translateConfig),
                      selection: _SelectionLabel(
                        model: translate?.model,
                        provider: translate == null
                            ? null
                            : translateConfig?.name,
                        leadingName: translate == null
                            ? null
                            : translateConfig?.name,
                      ),
                      onTap: () => _pickAndSaveSlot(_slotTranslate, configs),
                      description: '用于翻译服务的助手',
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

class _EmptyAssistants extends StatelessWidget {
  const _EmptyAssistants({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      children: [
        const Icon(Icons.api_outlined, size: 56, color: AppColors.textHint),
        const SizedBox(height: 12),
        const Text(
          '暂无模型服务',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '先添加服务商，再选择默认助手',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 18),
        Center(
          child: OutlinedButton(
            onPressed: onAdd,
            child: const Text('添加模型服务'),
          ),
        ),
      ],
    );
  }
}

class _AssistantSection extends StatelessWidget {
  const _AssistantSection({
    required this.icon,
    required this.title,
    required this.selection,
    required this.onTap,
    required this.description,
    this.onSettings,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onSettings;
  final _SelectionLabel selection;
  final VoidCallback onTap;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (onSettings != null)
              IconButton(
                onPressed: onSettings,
                icon: const Icon(Icons.tune, size: 20),
                color: AppColors.link,
                splashRadius: 18,
              ),
          ],
        ),
        const SizedBox(height: 10),
        _AssistantPickerRow(selection: selection, onTap: onTap),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SelectionLabel {
  const _SelectionLabel({
    required this.model,
    required this.provider,
    required this.leadingName,
  });

  final String? model;
  final String? provider;
  final String? leadingName;
}

class _AssistantPickerRow extends StatelessWidget {
  const _AssistantPickerRow({required this.selection, required this.onTap});

  final _SelectionLabel selection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final model = selection.model ?? '请选择';
    final provider = selection.provider ?? '未设置';
    final leadingName = selection.leadingName ?? provider;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              ProviderAvatar(name: leadingName, size: 26, radius: 10),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        model,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 18,
                      color: AppColors.border,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        provider,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantSlotSelection {
  const _AssistantSlotSelection({required this.configId, required this.model});

  final String configId;
  final String model;
}

Future<_AssistantSlotSelection?> _showPicker({
  required BuildContext context,
  required List<ApiConfig> configs,
  String? initialConfigId,
  String? initialModel,
}) async {
  if (configs.isEmpty) return null;
  final initialConfig = (initialConfigId == null)
      ? null
      : configs.where((c) => c.id == initialConfigId).firstOrNull;
  final defaultConfig = initialConfig ?? configs.firstWhere((c) => c.isActive, orElse: () => configs.first);
  final defaultModel = (initialModel != null && defaultConfig.models.contains(initialModel))
      ? initialModel
      : (defaultConfig.selectedModel ?? (defaultConfig.models.isEmpty ? null : defaultConfig.models.first));

  return showModalBottomSheet<_AssistantSlotSelection>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return _AssistantPickerSheet(
        configs: configs,
        initialConfigId: defaultConfig.id,
        initialModel: defaultModel,
      );
    },
  );
}

class _AssistantPickerSheet extends StatefulWidget {
  const _AssistantPickerSheet({
    required this.configs,
    required this.initialConfigId,
    required this.initialModel,
  });

  final List<ApiConfig> configs;
  final String initialConfigId;
  final String? initialModel;

  @override
  State<_AssistantPickerSheet> createState() => _AssistantPickerSheetState();
}

class _AssistantPickerSheetState extends State<_AssistantPickerSheet> {
  late String _configId = widget.initialConfigId;
  late String? _model = widget.initialModel;

  @override
  Widget build(BuildContext context) {
    final config = widget.configs.where((c) => c.id == _configId).firstOrNull ??
        widget.configs.first;
    final models = config.models;
    final selectedModel =
        _model ?? config.selectedModel ?? (models.isEmpty ? null : models.first);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: AppColors.surface,
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              minChildSize: 0.35,
              maxChildSize: 0.9,
              builder: (ctx, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    const Center(
                      child: Text(
                        '选择模型',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (models.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          '该服务商暂无模型，请先在服务商详情页导入模型。',
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
                                  _AssistantSlotSelection(
                                    configId: _configId,
                                    model: models[i],
                                  ),
                                ),
                              ),
                              if (i < models.length - 1)
                                const Divider(
                                  height: 1,
                                  color: AppColors.divider,
                                ),
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
