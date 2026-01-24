import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/services/provider_model_service.dart';
import 'package:zichat/storage/ai_config_storage.dart';
import 'package:zichat/storage/api_config_storage.dart';
import 'package:zichat/widgets/weui/weui.dart';

class ProviderDetailPage extends StatefulWidget {
  const ProviderDetailPage({super.key, required this.configId});

  final String configId;

  @override
  State<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends State<ProviderDetailPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  Timer? _debounce;
  ApiConfig? _latestConfig;

  void _toast(String message) => WeuiToast.show(context, message: message);

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_scheduleSave);
    _baseUrlController.addListener(_scheduleSave);
    _apiKeyController.addListener(_scheduleSave);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

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

  void _scheduleSave() {
    final config = _latestConfig;
    if (config == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final nextName = _nameController.text.trim();
      final next = config.copyWith(
        name: nextName.isEmpty ? config.name : nextName,
        baseUrl: _baseUrlController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
        type: ProviderType.openai,
      );
      await ApiConfigStorage.saveConfig(next);
    });
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

  Future<void> _openModels(ApiConfig config) async {
    _debounce?.cancel();
    final nextName = _nameController.text.trim();
    final next = config.copyWith(
      name: nextName.isEmpty ? config.name : nextName,
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      type: ProviderType.openai,
    );
    await ApiConfigStorage.saveConfig(next);

    if (next.baseUrl.trim().isEmpty || next.apiKey.trim().isEmpty) {
      _toast('请先填写 API 地址和密钥');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProviderModelsPage(configId: next.id)),
    );
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
        title: ValueListenableBuilder<Box<String>>(
          valueListenable: ApiConfigStorage.listenable(),
          builder: (context, box, _) {
            final config = ApiConfigStorage.getConfig(widget.configId);
            final title = (config?.name ?? '编辑服务商').trim();
            return Text(
              title.isEmpty ? '编辑服务商' : title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ValueListenableBuilder<Box<String>>(
              valueListenable: ApiConfigStorage.listenable(),
              builder: (context, box, _) {
                final config = ApiConfigStorage.getConfig(widget.configId);
                if (config == null) {
                  return const Center(child: Text('配置不存在'));
                }

                _latestConfig = config;
                if (_nameController.text.isEmpty && config.name.trim().isNotEmpty) {
                  _nameController.text = config.name;
                }
                if (_baseUrlController.text != config.baseUrl) {
                  _baseUrlController.text = config.baseUrl;
                }
                if (_apiKeyController.text != config.apiKey) {
                  _apiKeyController.text = config.apiKey;
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                          _Card(
                      child: Column(
                        children: [
                          _RowTile(
                            title: config.isActive ? '已启用' : '未启用',
                            trailing: WeuiSwitch(
                              value: config.isActive,
                              onChanged: (v) => _toggleEnabled(config, v),
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          _InputTile(
                            title: 'API 名称',
                            controller: _nameController,
                            hintText: '例如：硅基流动',
                            textInputAction: TextInputAction.next,
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          _InputTile(
                            title: 'API 地址',
                            controller: _baseUrlController,
                            hintText: '例如：https://api.xxx.com/v1',
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          _InputTile(
                            title: 'API Key',
                            controller: _apiKeyController,
                            hintText: '支持逗号分隔多个 key',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _openModels(config),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('进入模型列表'),
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

class ProviderModelsPage extends StatefulWidget {
  const ProviderModelsPage({super.key, required this.configId});

  final String configId;

  @override
  State<ProviderModelsPage> createState() => _ProviderModelsPageState();
}

class _ProviderModelsPageState extends State<ProviderModelsPage> {
  bool _detecting = false;
  bool _autoDetected = false;

  void _toast(String message) => WeuiToast.show(context, message: message);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDetectIfNeeded();
    });
  }

  Future<void> _autoDetectIfNeeded() async {
    if (_autoDetected) return;
    _autoDetected = true;
    await _detectModels(showToast: false);
  }

  Future<void> _detectModels({required bool showToast}) async {
    if (_detecting) return;
    final config = ApiConfigStorage.getConfig(widget.configId);
    if (config == null) return;
    if (config.baseUrl.trim().isEmpty || config.apiKey.trim().isEmpty) {
      if (showToast) _toast('请先填写 API 地址和密钥');
      return;
    }

    setState(() => _detecting = true);
    try {
      final detected = await ProviderModelService.detectModels(config);
      final byId = <String, ApiModel>{
        for (final m in config.models) m.modelId.trim(): m,
      };

      for (final m in detected) {
        final id = m.modelId.trim();
        if (id.isEmpty) continue;
        byId.putIfAbsent(id, () => ApiModel.fromLegacy(id));
      }

      final merged = byId.values.toList()
        ..sort(
          (a, b) => a.modelId.toLowerCase().compareTo(b.modelId.toLowerCase()),
        );

      await ApiConfigStorage.saveConfig(config.copyWith(models: merged));
      if (showToast) _toast('已更新模型列表');
    } catch (e) {
      if (showToast) _toast('检测失败：$e');
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  Future<void> _removeModel(ApiConfig config, ApiModel model) async {
    final updated = List<ApiModel>.from(config.models)
      ..removeWhere((m) => m.modelId == model.modelId);
    await ApiConfigStorage.saveConfig(config.copyWith(models: updated));
  }

  Future<void> _upsertModel(ApiConfig config, ApiModel model) async {
    final updated = List<ApiModel>.from(config.models);
    final idx = updated.indexWhere((m) => m.modelId == model.modelId);
    if (idx >= 0) {
      updated[idx] = model;
    } else {
      updated.add(model);
    }
    await ApiConfigStorage.saveConfig(config.copyWith(models: updated));
  }

  Future<void> _showAddModelSheet(ApiConfig config) async {
    final controller = TextEditingController();
    var supportsImage = false;

    final result = await showModalBottomSheet<ApiModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '添加模型',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _InputPill(
                        controller: controller,
                        hintText: '例如：gpt-4o-mini',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _InputTypeSelector(
                        supportsImage: supportsImage,
                        onChanged: (v) => setStateSheet(() => supportsImage = v),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
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
                              onPressed: () {
                                final id = controller.text.trim();
                                if (id.isEmpty) return;
                                final model = ApiModel(
                                  id: id,
                                  modelId: id,
                                  displayName: id,
                                  inputModalities: supportsImage
                                      ? const [
                                          ModelModality.text,
                                          ModelModality.image,
                                        ]
                                      : const [ModelModality.text],
                                );
                                Navigator.of(ctx).pop(model);
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size.fromHeight(44),
                              ),
                              child: const Text('添加'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
    if (result == null) return;
    if (config.getModelById(result.modelId) != null) {
      _toast('模型已存在');
      return;
    }
    await _upsertModel(config, result);
  }

  Future<void> _showEditModelSheet(ApiConfig config, ApiModel model) async {
    var supportsImage = model.supportsImageInput;

    final edited = await showModalBottomSheet<ApiModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            return SafeArea(
              child: Padding(
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
                        model.modelId,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InputTypeSelector(
                      supportsImage: supportsImage,
                      onChanged: (v) => setStateSheet(() => supportsImage = v),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
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
                            onPressed: () {
                              final next = ApiModel(
                                id: model.id,
                                modelId: model.modelId,
                                displayName: model.displayName,
                                type: model.type,
                                inputModalities: supportsImage
                                    ? const [
                                        ModelModality.text,
                                        ModelModality.image,
                                      ]
                                    : const [ModelModality.text],
                                outputModalities: model.outputModalities,
                                abilities: model.abilities,
                              );
                              Navigator.of(ctx).pop(next);
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size.fromHeight(44),
                            ),
                            child: const Text('保存'),
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
      },
    );

    if (edited == null) return;
    await _upsertModel(config, edited);
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
          '模型列表',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _detecting ? null : () => _detectModels(showToast: true),
            icon: _detecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: AppColors.textPrimary),
          ),
          IconButton(
            onPressed: () {
              final config = ApiConfigStorage.getConfig(widget.configId);
              if (config != null) _showAddModelSheet(config);
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
                final config = ApiConfigStorage.getConfig(widget.configId);
                if (config == null) {
                  return const Center(child: Text('配置不存在'));
                }

                final models = config.models;
                if (models.isEmpty) {
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
                          '暂无模型',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '将自动检测模型，也可手动添加',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: models.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final model = models[index];
                    return Dismissible(
                      key: ValueKey(model.modelId),
                      direction: DismissDirection.endToStart,
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
                      onDismissed: (_) => _removeModel(config, model),
                      child: _ModelTile(
                        model: model,
                        onTap: () => _showEditModelSheet(config, model),
                      ),
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

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.title, required this.trailing});

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _InputTile extends StatelessWidget {
  const _InputTile({
    required this.title,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
  });

  final String title;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
        child: Row(
          children: [
            SizedBox(
              width: 78,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  maxLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                  ).copyWith(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  const _ModelTile({
    required this.model,
    required this.onTap,
  });

  final ApiModel model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  model.modelId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _InputTypeBadge(supportsImage: model.supportsImageInput),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputTypeBadge extends StatelessWidget {
  const _InputTypeBadge({required this.supportsImage});

  final bool supportsImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        supportsImage ? '文字+图片' : '仅文字',
        style: const TextStyle(
          fontSize: 12,
          height: 1.1,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _InputTypeSelector extends StatelessWidget {
  const _InputTypeSelector({
    required this.supportsImage,
    required this.onChanged,
  });

  final bool supportsImage;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(false);
              },
              child: Center(
                child: Text(
                  '支持文字',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: supportsImage
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 22,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(!supportsImage);
              },
              child: Center(
                child: Text(
                  '支持图片',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: supportsImage
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputPill extends StatelessWidget {
  const _InputPill({
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 16, color: AppColors.textHint),
            border: InputBorder.none,
            isCollapsed: true,
          ),
        ),
      ),
    );
  }
}
