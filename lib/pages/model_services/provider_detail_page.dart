import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/pages/model_services/api_service_page.dart';
import 'package:zichat/pages/model_services/base_models_page.dart';
import 'package:zichat/pages/model_services/model_service_widgets.dart';
import 'package:zichat/services/provider_balance_service.dart';
import 'package:zichat/services/provider_model_service.dart';
import 'package:zichat/storage/ai_config_storage.dart';
import 'package:zichat/storage/api_config_storage.dart';
import 'package:zichat/widgets/weui/weui_switch.dart';

class ProviderDetailPage extends StatefulWidget {
  const ProviderDetailPage({super.key, required this.configId});

  final String configId;

  @override
  State<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends State<ProviderDetailPage> {
  final TextEditingController _modelSearchController = TextEditingController();
  final Set<String> _collapsedGroups = <String>{};

  bool _detectingModels = false;
  String? _modelsHint;
  String? _modelsError;
  bool _fetchingBalance = false;
  String? _balanceLabel;

  Timer? _hintTimer;

  @override
  void dispose() {
    _hintTimer?.cancel();
    _modelSearchController.dispose();
    super.dispose();
  }

  void _setModelsHint(String? text) {
    _hintTimer?.cancel();
    setState(() {
      _modelsHint = text;
      _modelsError = null;
    });
    if (text == null) return;
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _modelsHint = null);
    });
  }

  String _providerTypeLabel(ProviderType type) {
    switch (type) {
      case ProviderType.openai:
        return 'OpenAI';
      case ProviderType.google:
        return 'Gemini';
      case ProviderType.claude:
        return 'Claude';
    }
  }

  String _proxyLabel(ProviderProxy proxy) {
    if (!proxy.enabled) return '未启用';
    switch (proxy.type) {
      case ProviderProxyType.http:
        final username = (proxy.username ?? '').trim();
        final hasAuth = username.isNotEmpty;
        return '${proxy.address}:${proxy.port}${hasAuth ? "（认证）" : ""}';
      case ProviderProxyType.none:
        return '未启用';
    }
  }

  String _formatBalance(num value) {
    if (value is int) return value.toString();
    final v = value.toDouble();
    if (v.isFinite && v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  Future<void> _fetchBalance(ApiConfig config) async {
    if (_fetchingBalance) return;
    if (!config.balanceOption.enabled) return;

    HapticFeedback.lightImpact();
    setState(() => _fetchingBalance = true);
    try {
      final value = await ProviderBalanceService.fetchBalance(config);
      if (!mounted) return;
      setState(() => _balanceLabel = _formatBalance(value));
      _setModelsHint('余额已更新');
    } catch (e) {
      if (!mounted) return;
      _setModelsHint('获取余额失败：$e');
    } finally {
      if (!mounted) return;
      setState(() => _fetchingBalance = false);
    }
  }

  Future<void> _editProxy(ApiConfig config) async {
    HapticFeedback.lightImpact();
    final current = config.proxy;

    final addressController = TextEditingController(text: current.address);
    final portController = TextEditingController(
      text: current.port <= 0 ? '' : current.port.toString(),
    );
    final usernameController = TextEditingController(text: current.username ?? '');
    final passwordController = TextEditingController(text: current.password ?? '');

    ProviderProxyType type = current.type;
    bool showPassword = false;
    String? error;

    ProviderProxy? result;
    try {
      result = await showModalBottomSheet<ProviderProxy>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                0,
                12,
                12 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: AppColors.surface,
                  child: StatefulBuilder(
                    builder: (ctx, setModalState) {
                      Widget buildTypeRow({
                        required ProviderProxyType value,
                        required String label,
                      }) {
                        final selected = type == value;
                        return ListTile(
                          dense: true,
                          title: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => setModalState(() {
                            type = value;
                            error = null;
                          }),
                        );
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            '代理',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: AppColors.divider),
                          buildTypeRow(value: ProviderProxyType.none, label: '不使用代理'),
                          const Divider(height: 1, color: AppColors.divider),
                          buildTypeRow(value: ProviderProxyType.http, label: 'HTTP 代理'),
                          const Divider(height: 1, color: AppColors.divider),
                          if (type == ProviderProxyType.http) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: TextField(
                                controller: addressController,
                                keyboardType: TextInputType.url,
                                decoration: const InputDecoration(
                                  hintText: '代理地址，例如 127.0.0.1',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.divider),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: TextField(
                                controller: portController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '端口，例如 7890',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.divider),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: TextField(
                                controller: usernameController,
                                decoration: const InputDecoration(
                                  hintText: '用户名（可选）',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.divider),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: TextField(
                                controller: passwordController,
                                obscureText: !showPassword,
                                decoration: InputDecoration(
                                  hintText: '密码（可选）',
                                  border: InputBorder.none,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      showPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => setModalState(
                                      () => showPassword = !showPassword,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if ((error ?? '').trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    error!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('取消'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      if (type == ProviderProxyType.none) {
                                        Navigator.of(ctx).pop(
                                          const ProviderProxy.none(),
                                        );
                                        return;
                                      }

                                      final address = addressController.text.trim();
                                      final portRaw = portController.text.trim();
                                      final port = int.tryParse(portRaw) ?? 0;
                                      if (address.isEmpty || port <= 0 || port > 65535) {
                                        setModalState(() {
                                          error = '请填写正确的代理地址与端口';
                                        });
                                        return;
                                      }

                                      final username = usernameController.text.trim();
                                      final password = passwordController.text;
                                      Navigator.of(ctx).pop(
                                        ProviderProxy.http(
                                          address: address,
                                          port: port,
                                          username:
                                              username.isEmpty ? null : username,
                                          password:
                                              password.trim().isEmpty ? null : password,
                                        ),
                                      );
                                    },
                                    child: const Text('保存'),
                                  ),
                                ),
                              ],
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
        },
      );
    } finally {
      addressController.dispose();
      portController.dispose();
      usernameController.dispose();
      passwordController.dispose();
    }

    if (result == null) return;
    await ApiConfigStorage.saveConfig(config.copyWith(proxy: result));
    _setModelsHint('已更新代理');
  }

  Future<void> _openApiService(ApiConfig config) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ApiServicePage(configId: config.id)),
    );
  }

  Future<void> _openBaseModels() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BaseModelsPage()),
    );
  }

  Future<void> _toggleActive(ApiConfig config, bool value) async {
    if (!value) {
      final refs = _baseModelRolesForConfig(
        baseModels: _readBaseModelsConfig(),
        configId: config.id,
      );
      if (refs.isNotEmpty) {
        _setModelsHint('该服务商正在用于基础模型：${refs.join('、')}。请先在“基础模型”中更换后再禁用。');
        return;
      }
    }
    await ApiConfigStorage.setEnabled(config.id, value);
  }

  AiBaseModelsConfig _readBaseModelsConfig() {
    final raw = Hive.box(AiConfigStorage.boxName).get('base_models');
    if (raw is Map) {
      return AiBaseModelsConfig.fromMap(raw) ?? const AiBaseModelsConfig();
    }
    return const AiBaseModelsConfig();
  }

  List<String> _baseModelRolesForConfig({
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

  Future<void> _detachBaseModelsReferences(String configId) async {
    final current = _readBaseModelsConfig();
    var next = current;
    var changed = false;

    if (current.chatConfigId == configId) {
      next = next.copyWith(
        chatConfigId: null,
        chatModel: null,
        chatModelSupportsImage: false,
      );
      changed = true;
    }

    if (current.ocrConfigId == configId) {
      next = next.copyWith(
        ocrEnabled: false,
        ocrConfigId: null,
        ocrModel: null,
        ocrModelSupportsImage: true,
      );
      changed = true;
    }

    if (current.imageGenConfigId == configId) {
      next = next.copyWith(
        imageGenConfigId: null,
        imageGenModel: null,
      );
      changed = true;
    }

    if (!changed) return;
    await AiConfigStorage.saveBaseModelsConfig(next);
  }

  Future<void> _renameProvider(ApiConfig config) async {
    final controller = TextEditingController(text: config.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('重命名'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '请输入新的名称',
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
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (name == null || name.trim().isEmpty || name.trim() == config.name) return;
    HapticFeedback.mediumImpact();
    await ApiConfigStorage.saveConfig(config.copyWith(name: name.trim()));
  }

  Future<void> _deleteProvider(ApiConfig config) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('删除服务商'),
          content: Text('确定要删除“${config.name}”吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    HapticFeedback.mediumImpact();
    await _detachBaseModelsReferences(config.id);
    await ApiConfigStorage.deleteConfig(config.id);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _showMore(ApiConfig config) async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Material(
                color: AppColors.surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SheetAction(
                      label: '重命名',
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _renameProvider(config);
                      },
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _SheetAction(
                      label: '删除',
                      destructive: true,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _deleteProvider(config);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _detectModels(ApiConfig config) async {
    if (_detectingModels) return;
    if (config.baseUrl.trim().isEmpty || config.apiKey.trim().isEmpty) {
      setState(() => _modelsError = '请先在“API 服务”中填写主机与密钥');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _detectingModels = true;
      _modelsError = null;
      _modelsHint = null;
    });

    try {
      final detectedModels = await ProviderModelService.detectModels(config);

      final byId = <String, ApiModel>{
        for (final model in config.models) model.modelId: model,
      };
      for (final model in detectedModels) {
        final trimmed = model.modelId.trim();
        if (trimmed.isEmpty) continue;
        byId.putIfAbsent(trimmed, () => model);
      }

      final merged = byId.values.toList()
        ..sort(
          (a, b) => a.modelId.toLowerCase().compareTo(b.modelId.toLowerCase()),
        );

      final mergedIds = merged.map((m) => m.modelId).toSet();
      final nextSelected = (config.selectedModel != null &&
              mergedIds.contains(config.selectedModel))
          ? config.selectedModel
          : (merged.isEmpty ? null : merged.first.modelId);

      await ApiConfigStorage.saveConfig(
        config.copyWith(models: merged, selectedModel: nextSelected),
      );

      _setModelsHint('已导入 ${detectedModels.length} 个模型');
    } catch (e) {
      setState(() => _modelsError = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _detectingModels = false);
    }
  }

  Future<void> _addModelManual(ApiConfig config) async {
    final controller = TextEditingController();
    final model = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('添加模型'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '例如：gpt-4o-mini',
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
              child: const Text('添加'),
            ),
          ],
        );
      },
    );

    if (model == null || model.trim().isEmpty) return;
    if (config.getModelById(model.trim()) != null) {
      _setModelsHint('模型已存在');
      return;
    }

    final updated = List<ApiModel>.from(config.models)
      ..add(ApiModel.fromLegacy(model.trim()));
    await ApiConfigStorage.saveConfig(
      config.copyWith(
        models: updated,
        selectedModel: config.selectedModel ?? model.trim(),
      ),
    );
    _setModelsHint('已添加模型');
  }

  Future<void> _removeModel(ApiConfig config, String model) async {
    HapticFeedback.mediumImpact();
    final updated = List<ApiModel>.from(config.models)
      ..removeWhere((m) => m.modelId == model);
    final nextSelected = config.selectedModel == model
        ? (updated.isEmpty ? null : updated.first.modelId)
        : config.selectedModel;

    await ApiConfigStorage.saveConfig(
      config.copyWith(models: updated, selectedModel: nextSelected),
    );
  }

  Future<void> _selectModel(ApiConfig config, String model) async {
    if (config.selectedModel == model) return;
    HapticFeedback.selectionClick();
    await ApiConfigStorage.saveConfig(config.copyWith(selectedModel: model));
    _setModelsHint('已设为默认模型');
  }

  Map<String, List<ApiModel>> _groupModels(List<ApiModel> models) {
    final query = _modelSearchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? models
        : models
            .where((m) =>
                m.modelId.toLowerCase().contains(query) ||
                m.displayName.toLowerCase().contains(query))
            .toList();

    final map = <String, List<ApiModel>>{};
    for (final model in filtered) {
      final group = model.modelId.contains('/')
          ? model.modelId.split('/').first
          : '其他';
      map.putIfAbsent(group, () => []).add(model);
    }

    final sortedKeys = map.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final result = <String, List<ApiModel>>{};
    for (final k in sortedKeys) {
      final list = map[k]!
        ..sort(
          (a, b) =>
              a.modelId.toLowerCase().compareTo(b.modelId.toLowerCase()),
        );
      result[k] = list;
    }
    return result;
  }

  String _modelDisplay(String group, ApiModel model) {
    final id = model.modelId;
    if (group != '其他' && id.startsWith('$group/')) {
      return id.substring(group.length + 1);
    }
    return model.displayName.isNotEmpty ? model.displayName : id;
  }

  Future<void> _showModelActions(ApiConfig config) async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Material(
                color: AppColors.surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SheetAction(
                      label: _detectingModels ? '正在检测…' : '检测并导入模型',
                      enabled: !_detectingModels,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _detectModels(config);
                      },
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _SheetAction(
                      label: '手动添加模型',
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _addModelManual(config);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: WeuiCircleIconButton(
              assetName: AppAssets.iconThreeDot,
              backgroundColor: const Color(0x0D000000),
              iconSize: 18,
              onTap: () async {
                final config = ApiConfigStorage.getConfig(widget.configId);
                if (config == null) return;
                await _showMore(config);
              },
            ),
          ),
        ],
        title: ValueListenableBuilder<Box<String>>(
          valueListenable: ApiConfigStorage.listenable(),
          builder: (context, box, _) {
            final config = ApiConfigStorage.getConfig(widget.configId);
            return Text(
              config?.name ?? '服务商',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            );
          },
        ),
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
                final baseModels = _readBaseModelsConfig();
                return ValueListenableBuilder<Box<String>>(
                  valueListenable: ApiConfigStorage.listenable(),
                  builder: (context, box, _) {
                final config = ApiConfigStorage.getConfig(widget.configId);
                if (config == null) {
                  return const Center(
                    child: Text(
                      '服务商不存在',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                final roles = _baseModelRolesForConfig(
                  baseModels: baseModels,
                  configId: config.id,
                );
                final groups = _groupModels(config.models);

                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          ProviderAvatar(
                            name: config.name,
                            size: 44,
                            radius: 14,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              config.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (roles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final role in roles) WeuiTag(label: role),
                          ],
                        ),
                      ),
                    if (_modelsError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _InlineMessage(
                          text: _modelsError!,
                          tone: _InlineTone.error,
                        ),
                      )
                    else if (_modelsHint != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _InlineMessage(
                          text: _modelsHint!,
                          tone: _InlineTone.hint,
                        ),
                      ),

                    const WeuiSectionTitle(title: '管理'),
                    WeuiInsetCard(
                      child: Column(
                        children: [
                          _ManageRow(
                            title: '已启用',
                            trailing: WeuiSwitch(
                              value: config.isActive,
                              onChanged: (v) => _toggleActive(config, v),
                            ),
                            showArrow: false,
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          _ManageRow(
                            title: '服务商类型',
                            trailing: _ProtocolPill(
                              label: _providerTypeLabel(config.type),
                              onTap: () => _setModelsHint(
                                _providerTypeLabel(config.type),
                              ),
                            ),
                            showArrow: false,
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          _ManageRow(
                            title: 'API 服务',
                            onTap: () => _openApiService(config),
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          _ManageRow(
                            title: '代理',
                            onTap: () => _editProxy(config),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _proxyLabel(config.proxy),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textHint,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: AppColors.textHint,
                                ),
                              ],
                            ),
                            showArrow: false,
                          ),
                          if (config.balanceOption.enabled) ...[
                            const Divider(height: 1, color: AppColors.divider),
                            _ManageRow(
                              title: '余额',
                              onTap: _fetchingBalance
                                  ? null
                                  : () => _fetchBalance(config),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _fetchingBalance
                                        ? '获取中…'
                                        : (_balanceLabel ?? '点击获取'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: _balanceLabel == null
                                          ? FontWeight.w400
                                          : FontWeight.w600,
                                      color: _balanceLabel == null
                                          ? AppColors.textHint
                                          : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.refresh,
                                    size: 18,
                                    color: _fetchingBalance
                                        ? AppColors.textHint
                                        : AppColors.textSecondary,
                                  ),
                                ],
                              ),
                              showArrow: false,
                            ),
                          ],
                          const Divider(height: 1, color: AppColors.divider),
                          _ManageRow(
                            title: '基础模型',
                            onTap: _openBaseModels,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  roles.isEmpty ? '未使用' : roles.join('、'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: roles.isEmpty
                                        ? FontWeight.w400
                                        : FontWeight.w600,
                                    color: roles.isEmpty
                                        ? AppColors.textHint
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: AppColors.textHint,
                                ),
                              ],
                            ),
                            showArrow: false,
                          ),
                        ],
                      ),
                    ),

                    WeuiSectionTitle(
                      title: '模型',
                      trailing: TextButton.icon(
                        onPressed: () => _showModelActions(config),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('添加'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: WeuiPillSearchBar(
                        controller: _modelSearchController,
                        hintText: '搜索模型',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (config.models.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _EmptyModelsCard(
                          detecting: _detectingModels,
                          onDetect: () => _detectModels(config),
                          onAdd: () => _addModelManual(config),
                        ),
                      )
                    else if (groups.isEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 48, 16, 0),
                        child: _NoSearchResultModels(),
                      )
                    else
                      WeuiInsetCard(
                        child: Column(
                          children: [
                            for (final entry in groups.entries) ...[
                              _GroupHeader(
                                title: entry.key,
                                count: entry.value.length,
                                collapsed:
                                    _collapsedGroups.contains(entry.key),
                                onTap: () {
                                  setState(() {
                                    if (_collapsedGroups.contains(entry.key)) {
                                      _collapsedGroups.remove(entry.key);
                                    } else {
                                      _collapsedGroups.add(entry.key);
                                    }
                                  });
                                },
                              ),
                              if (!_collapsedGroups.contains(entry.key))
                                for (final model in entry.value) ...[
                                  const Divider(
                                    height: 1,
                                    color: AppColors.divider,
                                  ),
                                  _ModelRow(
                                    leadingName: entry.key,
                                    title: _modelDisplay(entry.key, model),
                                    fullModel: model.modelId,
                                    selected: model.modelId == config.selectedModel,
                                    supportsImageInput: model.supportsImageInput,
                                    onTap: () => _selectModel(config, model.modelId),
                                    onRemove: () => _removeModel(config, model.modelId),
                                  ),
                                ],
                              const Divider(
                                height: 1,
                                color: AppColors.divider,
                              ),
                            ],
                          ],
                        ),
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

class _ManageRow extends StatelessWidget {
  const _ManageRow({
    required this.title,
    this.onTap,
    this.trailing,
    this.showArrow = true,
  });

  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final clickable = onTap != null;
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: clickable
            ? () {
                HapticFeedback.selectionClick();
                onTap?.call();
              }
            : null,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
                if (trailing == null && showArrow)
                  const Icon(Icons.chevron_right, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProtocolPill extends StatelessWidget {
  const _ProtocolPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.title,
    required this.count,
    required this.collapsed,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                collapsed ? Icons.expand_more : Icons.expand_less,
                size: 20,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
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

class _ModelRow extends StatelessWidget {
  const _ModelRow({
    required this.leadingName,
    required this.title,
    required this.fullModel,
    required this.selected,
    required this.supportsImageInput,
    required this.onTap,
    required this.onRemove,
  });

  final String leadingName;
  final String title;
  final String fullModel;
  final bool selected;
  final bool supportsImageInput;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 选中状态指示器
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: selected ? null : Border.all(color: AppColors.border, width: 1.5),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 11, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              color: selected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (supportsImageInput) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '识图',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '默认',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!selected)
                      Text(
                        fullModel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textHint.withValues(alpha: 0.6),
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

class _EmptyModelsCard extends StatelessWidget {
  const _EmptyModelsCard({
    required this.detecting,
    required this.onDetect,
    required this.onAdd,
  });

  final bool detecting;
  final VoidCallback onDetect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '还没有可用模型',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '建议先检测并导入模型列表，再选择默认模型。',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: detecting ? null : onDetect,
                  child: Text(detecting ? '检测中…' : '检测模型'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onAdd,
                  child: const Text('手动添加'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoSearchResultModels extends StatelessWidget {
  const _NoSearchResultModels();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.search_off, size: 56, color: AppColors.textHint),
        const SizedBox(height: 12),
        const Text(
          '未找到匹配的模型',
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
    );
  }
}

enum _InlineTone { hint, error }

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.text, required this.tone});

  final String text;
  final _InlineTone tone;

  @override
  Widget build(BuildContext context) {
    final isError = tone == _InlineTone.error;
    final bg = isError ? const Color(0xFFFFF0F0) : const Color(0xFFF7F7F7);
    final border = isError ? const Color(0xFFFFE0E0) : AppColors.border;
    final color = isError ? Colors.red : AppColors.textHint;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, height: 1.35, color: color),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red : AppColors.textPrimary;
    return InkWell(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap();
            }
          : null,
      child: SizedBox(
        height: 54,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: enabled ? color : AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}
