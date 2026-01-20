import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/pages/api_edit_page.dart';
import 'package:zichat/pages/api_list_page.dart';
import 'package:zichat/services/model_detector_service.dart';
import 'package:zichat/storage/api_config_storage.dart';
import 'package:zichat/widgets/weui/weui.dart';

/// 模型配置页面 - AI 配置入口
class ModelConfigPage extends StatefulWidget {
  const ModelConfigPage({super.key});

  @override
  State<ModelConfigPage> createState() => _ModelConfigPageState();
}

class _ModelConfigPageState extends State<ModelConfigPage> {
  bool _detecting = false;
  String? _detectError;
  bool _showApiKey = false;

  String _formatHost(String baseUrl) {
    try {
      final uri = Uri.parse(baseUrl.trim());
      if (uri.host.isNotEmpty) return uri.host;
    } catch (_) {}
    return baseUrl.trim();
  }

  String _maskKey(String apiKey) {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return '';
    if (_showApiKey) return trimmed;
    if (trimmed.length <= 10) return '****';
    return '${trimmed.substring(0, 6)}…${trimmed.substring(trimmed.length - 4)}';
  }

  Future<void> _openApiList() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ApiListPage()),
    );
  }

  Future<void> _addApiQuick() async {
    HapticFeedback.lightImpact();
    final config = await Navigator.of(context).push<ApiConfig>(
      MaterialPageRoute(builder: (_) => const ApiEditPage()),
    );
    if (config == null) return;
    await ApiConfigStorage.saveConfig(config);
    await ApiConfigStorage.setActiveConfig(config.id);
  }

  Future<void> _editApi(ApiConfig config) async {
    HapticFeedback.lightImpact();
    final updated = await Navigator.of(context).push<ApiConfig>(
      MaterialPageRoute(builder: (_) => ApiEditPage(editConfig: config)),
    );
    if (updated == null) return;
    await ApiConfigStorage.saveConfig(updated);
    if (config.isActive) {
      await ApiConfigStorage.setActiveConfig(updated.id);
    }
  }

  Future<void> _pickProvider(List<ApiConfig> configs, ApiConfig? active) async {
    if (configs.isEmpty) {
      await _addApiQuick();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              color: AppColors.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '选择默认 API',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        WeuiCellGroup(
                          margin: EdgeInsets.zero,
                          children: [
                            for (final config in configs)
                              WeuiCell(
                                title: config.name,
                                description: _formatHost(config.baseUrl),
                                showArrow: false,
                                trailing: config.id == active?.id
                                    ? const Icon(
                                        Icons.check,
                                        size: 20,
                                        color: AppColors.primary,
                                      )
                                    : null,
                                onTap: () async {
                                  Navigator.of(sheetContext).pop();
                                  HapticFeedback.selectionClick();
                                  await ApiConfigStorage.setActiveConfig(
                                    config.id,
                                  );
                                },
                              ),
                          ],
                        ),
                        WeuiCellGroup(
                          margin: const EdgeInsets.only(top: 8),
                          children: [
                            WeuiCell(
                              title: '管理 API',
                              showArrow: false,
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                _openApiList();
                              },
                            ),
                            WeuiCell(
                              title: '添加新的 API',
                              showArrow: false,
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                _addApiQuick();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _detectModels(ApiConfig config) async {
    if (_detecting) return;
    HapticFeedback.lightImpact();

    setState(() {
      _detecting = true;
      _detectError = null;
    });

    try {
      final models = await ModelDetectorService.detectModels(
        baseUrl: config.baseUrl,
        apiKey: config.apiKey,
      );

      if (!mounted) return;

      final nextSelected =
          models.contains(config.selectedModel) ? config.selectedModel : null;
      final updated = config.copyWith(
        models: models,
        selectedModel: nextSelected ?? (models.isEmpty ? null : models.first),
      );
      await ApiConfigStorage.saveConfig(updated);

      if (!mounted) return;
      WeuiToast.show(context, message: '已检测到 ${models.length} 个模型');
    } catch (e) {
      if (!mounted) return;
      setState(() => _detectError = e.toString());
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  Future<void> _pickModel(ApiConfig active) async {
    final models = active.models;
    if (models.isEmpty) {
      await _detectModels(active);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              color: AppColors.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '选择对话模型',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        WeuiCellGroup(
                          margin: EdgeInsets.zero,
                          children: [
                            for (final model in models)
                              WeuiCell(
                                title: model,
                                showArrow: false,
                                trailing: model ==
                                        (active.selectedModel ?? models.first)
                                    ? const Icon(
                                        Icons.check,
                                        size: 20,
                                        color: AppColors.primary,
                                      )
                                    : null,
                                onTap: () async {
                                  Navigator.of(sheetContext).pop();
                                  HapticFeedback.selectionClick();
                                  await ApiConfigStorage.saveConfig(
                                    active.copyWith(selectedModel: model),
                                  );
                                  await ApiConfigStorage.setActiveConfig(
                                    active.id,
                                  );
                                },
                              ),
                          ],
                        ),
                        WeuiCellGroup(
                          margin: const EdgeInsets.only(top: 8),
                          children: [
                            WeuiCell(
                              title: '重新检测模型',
                              showArrow: false,
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                _detectModels(active);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateParams(
    ApiConfig active, {
    double? temperature,
    double? topP,
    int? maxTokens,
  }) async {
    final updated = active.copyWith(
      temperature: temperature,
      topP: topP,
      maxTokens: maxTokens,
    );
    await ApiConfigStorage.saveConfig(updated);
    if (active.isActive) {
      await ApiConfigStorage.setActiveConfig(active.id);
    }
  }

  Future<void> _resetParams(ApiConfig active) async {
    HapticFeedback.lightImpact();
    await _updateParams(active, temperature: 0.7, topP: 0.9, maxTokens: 4096);
    if (mounted) {
      WeuiToast.show(context, message: '已恢复默认参数');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
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
        title: const Text('AI 设置', style: AppStyles.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: ValueListenableBuilder(
          valueListenable: ApiConfigStorage.listenable(),
          builder: (context, _, __) {
            final configs = ApiConfigStorage.getAllConfigs();
            final active = ApiConfigStorage.getActiveConfig();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  children: [
                    _OverviewCard(
                      totalProviders: configs.length,
                      active: active,
                      onPickProvider: () => _pickProvider(configs, active),
                      onAddQuick: _addApiQuick,
                      onManage: _openApiList,
                    ),
                    const SizedBox(height: 12),
                    if (active == null) ...[
                      _GuideCard(onAdd: _addApiQuick, onManage: _openApiList),
                    ] else ...[
                      _buildSection(
                        title: '当前 API',
                        children: [
                          _InfoRow(
                            label: '供应商',
                            value: active.name,
                            onTap: () => _pickProvider(configs, active),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColors.textHint,
                            ),
                          ),
                          _InfoRow(
                            label: '地址',
                            value: _formatHost(active.baseUrl),
                          ),
                          _KeyRow(
                            value: _maskKey(active.apiKey),
                            onToggle: () {
                              HapticFeedback.selectionClick();
                              setState(() => _showApiKey = !_showApiKey);
                            },
                            toggleText: _showApiKey ? '隐藏' : '显示',
                            onCopy: () async {
                              await Clipboard.setData(
                                ClipboardData(text: active.apiKey),
                              );
                              if (!mounted) return;
                              WeuiToast.show(context, message: '已复制密钥');
                            },
                          ),
                          _ActionRow(
                            primaryLabel: _detecting ? '检测中...' : '检测模型',
                            primaryEnabled: !_detecting,
                            onPrimary: () => _detectModels(active),
                            secondaryLabel: '编辑',
                            onSecondary: () => _editApi(active),
                            tertiaryLabel: '管理',
                            onTertiary: _openApiList,
                          ),
                          if (_detectError != null)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Text(
                                _detectError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSection(
                        title: '模型',
                        children: [
                          _InfoRow(
                            label: '对话模型',
                            value: active.models.isEmpty
                                ? '未检测到模型'
                                : (active.selectedModel ?? active.models.first),
                            onTap: () => _pickModel(active),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSection(
                        title: '参数',
                        children: [
                          _SliderRow(
                            label: '温度',
                            value: active.temperature.clamp(0.0, 2.0),
                            min: 0,
                            max: 2,
                            divisions: 20,
                            onChangedEnd: (v) =>
                                _updateParams(active, temperature: v),
                          ),
                          _SliderRow(
                            label: 'Top P',
                            value: active.topP.clamp(0.0, 1.0),
                            min: 0,
                            max: 1,
                            divisions: 20,
                            onChangedEnd: (v) =>
                                _updateParams(active, topP: v),
                          ),
                          _StepperRow(
                            label: '最大 Tokens',
                            value: active.maxTokens.clamp(1, 4096),
                            min: 128,
                            max: 4096,
                            step: 128,
                            onChanged: (v) =>
                                _updateParams(active, maxTokens: v),
                          ),
                          _FooterButtonRow(onTap: () => _resetParams(active)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(title, style: AppStyles.caption),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.totalProviders,
    required this.active,
    required this.onPickProvider,
    required this.onAddQuick,
    required this.onManage,
  });

  final int totalProviders;
  final ApiConfig? active;
  final VoidCallback onPickProvider;
  final VoidCallback onAddQuick;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final hasConfig = totalProviders > 0;
    final title = hasConfig ? '已配置' : '未配置';
    final subtitle = hasConfig
        ? (active != null ? '默认：${active!.name}' : '已添加 $totalProviders 个 API')
        : '添加 API 后即可使用 AI';

    final modelText = active == null
        ? '未选择'
        : (active!.models.isEmpty
            ? '未检测'
            : (active!.selectedModel ?? active!.models.first));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (hasConfig ? AppColors.primary : AppColors.textHint)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                  ),
                  child: Icon(
                    hasConfig
                        ? Icons.check_circle_outline_rounded
                        : Icons.info_outline_rounded,
                    color:
                        hasConfig ? AppColors.primary : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppStyles.titleSmall),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '当前模型：$modelText',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: hasConfig ? onPickProvider : onAddQuick,
                    child: Text(hasConfig ? '切换默认' : '添加 API'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onManage,
                    child: const Text('管理 API'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.onAdd,
    required this.onManage,
  });

  final VoidCallback onAdd;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('开始配置', style: AppStyles.titleSmall),
            const SizedBox(height: 6),
            const Text(
              '1. 添加一个 API 供应商\n2. 检测模型\n3. 选择对话模型',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAdd,
                    child: const Text('添加 API'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onManage,
                    child: const Text('管理列表'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.value,
    required this.onToggle,
    required this.toggleText,
    required this.onCopy,
  });

  final String value;
  final VoidCallback onToggle;
  final String toggleText;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const SizedBox(
            width: 88,
            child: Text(
              '密钥',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: onCopy,
            child: const Text('复制'),
          ),
          TextButton(
            onPressed: onToggle,
            child: Text(toggleText),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    required this.tertiaryLabel,
    required this.onTertiary,
    this.primaryEnabled = true,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final bool primaryEnabled;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final String tertiaryLabel;
  final VoidCallback onTertiary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: primaryEnabled ? onPrimary : null,
              child: Text(primaryLabel),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: onSecondary,
              child: Text(secondaryLabel),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: onTertiary,
              child: Text(tertiaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterButtonRow extends StatelessWidget {
  const _FooterButtonRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '恢复默认参数',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatefulWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChangedEnd,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChangedEnd;

  @override
  State<_SliderRow> createState() => _SliderRowState();
}

class _SliderRowState extends State<_SliderRow> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant _SliderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && (widget.value - _value).abs() > 1e-6) {
      _value = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                _value.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            onChanged: (v) => setState(() => _value = v),
            onChangeEnd: (v) => widget.onChangedEnd(v),
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final canMinus = value - step >= min;
    final canPlus = value + step <= max;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            onPressed: canMinus ? () => onChanged(value - step) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.textPrimary,
          ),
          IconButton(
            onPressed: canPlus ? () => onChanged(value + step) : null,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
