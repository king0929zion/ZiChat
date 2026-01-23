import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/services/provider_balance_service.dart';
import 'package:zichat/services/provider_model_service.dart';
import 'package:zichat/storage/ai_config_storage.dart';
import 'package:zichat/storage/api_config_storage.dart';

/// 供应商详情页 - 对标 HTML 原型 (Image 4)
class ProviderDetailPage extends StatefulWidget {
  const ProviderDetailPage({super.key, required this.configId});

  final String configId;

  @override
  State<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends State<ProviderDetailPage> {
  bool _detectingModels = false;
  bool _fetchingBalance = false;
  String? _toastMessage;
  String? _balanceLabel;
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toastMessage = message);
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  Future<void> _toggleActive(ApiConfig config, bool value) async {
    if (!value) {
      final refs = _baseModelRolesForConfig(configId: config.id);
      if (refs.isNotEmpty) {
        _showToast('该服务商正在用于：${refs.join('、')}');
        return;
      }
    }
    await ApiConfigStorage.setEnabled(config.id, value);
  }

  List<String> _baseModelRolesForConfig({required String configId}) {
    final raw = Hive.box(AiConfigStorage.boxName).get('base_models');
    if (raw is! Map) return [];
    final baseModels = AiBaseModelsConfig.fromMap(raw) ?? const AiBaseModelsConfig();
    
    final roles = <String>[];
    if (baseModels.hasChatModel && baseModels.chatConfigId == configId) {
      roles.add('默认对话');
    }
    if (baseModels.ocrEnabled && baseModels.hasOcrModel && baseModels.ocrConfigId == configId) {
      roles.add('OCR');
    }
    if (baseModels.hasImageGenModel && baseModels.imageGenConfigId == configId) {
      roles.add('生图');
    }
    return roles;
  }

  Future<void> _deleteProvider(ApiConfig config) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '删除服务商',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '确定要删除“${config.name}”吗？此操作不可撤销。',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('删除'),
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
    if (ok != true) return;

    HapticFeedback.mediumImpact();
    await ApiConfigStorage.deleteConfig(config.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _detectModels(ApiConfig config) async {
    if (_detectingModels) return;
    if (config.baseUrl.trim().isEmpty || config.apiKey.trim().isEmpty) {
      _showToast('请先填写 API 地址和密钥');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _detectingModels = true);

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
        ..sort((a, b) => a.modelId.toLowerCase().compareTo(b.modelId.toLowerCase()));

      final ids = merged.map((m) => m.modelId).toSet();
      final selected = (config.selectedModel ?? '').trim();
      final nextSelected =
          selected.isNotEmpty && ids.contains(selected) ? selected : (merged.isEmpty ? null : merged.first.modelId);

      await ApiConfigStorage.saveConfig(
        config.copyWith(models: merged, selectedModel: nextSelected),
      );
      _showToast('已导入 ${detectedModels.length} 个模型');
    } catch (e) {
      _showToast('检测失败：$e');
    } finally {
      if (mounted) setState(() => _detectingModels = false);
    }
  }

  Future<void> _openModelList(ApiConfig config) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _ModelListPage(configId: config.id)),
    );
  }

  Future<void> _copyToClipboard(String text, {String? hint}) async {
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    _showToast(hint ?? '已复制');
  }

  String _maskApiKey(String apiKey) {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return '未设置';
    if (trimmed.length <= 8) return '••••••••';
    return '${trimmed.substring(0, 4)}••••${trimmed.substring(trimmed.length - 4)}';
  }

  String _defaultBaseUrlForType(ProviderType type) {
    switch (type) {
      case ProviderType.openai:
        return 'https://api.openai.com/v1';
      case ProviderType.google:
        return 'https://generativelanguage.googleapis.com/v1beta';
      case ProviderType.claude:
        return 'https://api.anthropic.com/v1';
    }
  }

  String _proxyLabel(ProviderProxy proxy) {
    if (!proxy.enabled) return '未启用';
    switch (proxy.type) {
      case ProviderProxyType.http:
        final username = (proxy.username ?? '').trim();
        return '${proxy.address}:${proxy.port}${username.isEmpty ? '' : '（认证）'}';
      case ProviderProxyType.none:
        return '未启用';
    }
  }

  String _formatBalance(num value) {
    if (value is int) return value.toString();
    final v = value.toDouble();
    if (!v.isFinite) return value.toString();
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  Future<void> _pickProviderType(ApiConfig config) async {
    final current = config.type;
    final next = await showModalBottomSheet<ProviderType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '选择 API 类型',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                _SheetOption(
                  title: 'OpenAI 兼容',
                  subtitle: 'OpenAI / SiliconFlow / OpenRouter 等',
                  selected: current == ProviderType.openai,
                  onTap: () => Navigator.of(ctx).pop(ProviderType.openai),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _SheetOption(
                  title: 'Google Gemini',
                  subtitle: 'Gemini 官方 API',
                  selected: current == ProviderType.google,
                  onTap: () => Navigator.of(ctx).pop(ProviderType.google),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _SheetOption(
                  title: 'Anthropic Claude',
                  subtitle: 'Claude Messages API',
                  selected: current == ProviderType.claude,
                  onTap: () => Navigator.of(ctx).pop(ProviderType.claude),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    if (next == null || next == current) return;

    final previousDefault = _defaultBaseUrlForType(current);
    final shouldUpdateBaseUrl =
        config.baseUrl.trim().isEmpty || config.baseUrl.trim() == previousDefault;
    final nextBaseUrl =
        shouldUpdateBaseUrl ? _defaultBaseUrlForType(next) : config.baseUrl;

    await ApiConfigStorage.saveConfig(
      config.copyWith(type: next, baseUrl: nextBaseUrl),
    );
    _showToast('已更新 API 类型');
  }

  Future<String?> _showTextEditSheet({
    required String title,
    required String initialValue,
    required String hintText,
    String? helperText,
    bool allowEmpty = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initialValue);
    bool showText = !obscureText;
    String? errorText;

    try {
      return await showModalBottomSheet<String>(
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: StatefulBuilder(
                  builder: (ctx, setModalState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 36,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: TextField(
                            controller: controller,
                            keyboardType: keyboardType,
                            autofocus: true,
                            obscureText: obscureText && !showText,
                            decoration: InputDecoration(
                              hintText: hintText,
                              helperText: helperText,
                              errorText: errorText,
                              border: InputBorder.none,
                              suffixIcon: obscureText
                                  ? IconButton(
                                      onPressed: () => setModalState(
                                        () => showText = !showText,
                                      ),
                                      icon: Icon(
                                        showText
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    final v = controller.text.trim();
                                    if (!allowEmpty && v.isEmpty) {
                                      setModalState(() {
                                        errorText = '不能为空';
                                      });
                                      return;
                                    }
                                    Navigator.of(ctx).pop(v);
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
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _editProviderName(ApiConfig config) async {
    final next = await _showTextEditSheet(
      title: '服务商名称',
      initialValue: config.name,
      hintText: '例如：OpenAI / SiliconFlow',
    );
    if (next == null || next.trim().isEmpty || next.trim() == config.name) return;
    await ApiConfigStorage.saveConfig(config.copyWith(name: next.trim()));
    _showToast('已更新名称');
  }

  Future<void> _editBaseUrl(ApiConfig config) async {
    final next = await _showTextEditSheet(
      title: 'API 地址',
      initialValue: config.baseUrl,
      hintText: '例如：https://api.openai.com/v1',
      allowEmpty: true,
      keyboardType: TextInputType.url,
    );
    if (next == null) return;
    final trimmed = next.trim();
    if (trimmed == config.baseUrl.trim()) return;
    await ApiConfigStorage.saveConfig(config.copyWith(baseUrl: trimmed));
    _showToast('已更新 API 地址');
  }

  Future<void> _editApiKey(ApiConfig config) async {
    final next = await _showTextEditSheet(
      title: 'API Key',
      initialValue: config.apiKey,
      hintText: '请输入 API Key',
      helperText: '支持多个 Key，用英文逗号分隔',
      allowEmpty: true,
      obscureText: true,
    );
    if (next == null) return;
    final trimmed = next.trim();
    if (trimmed == config.apiKey.trim()) return;
    await ApiConfigStorage.saveConfig(config.copyWith(apiKey: trimmed));
    _showToast('已更新 API Key');
  }

  Future<void> _editProxy(ApiConfig config) async {
    HapticFeedback.lightImpact();

    final current = config.proxy;
    ProviderProxyType type = current.type;
    final addressController = TextEditingController(text: current.address);
    final portController = TextEditingController(
      text: current.port <= 0 ? '' : current.port.toString(),
    );
    final usernameController = TextEditingController(text: current.username ?? '');
    final passwordController = TextEditingController(text: current.password ?? '');
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: StatefulBuilder(
                  builder: (ctx, setModalState) {
                    Widget typeRow({
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
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check, color: Colors.black)
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
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 36,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '代理',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        typeRow(value: ProviderProxyType.none, label: '不使用代理'),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        typeRow(value: ProviderProxyType.http, label: 'HTTP 代理'),
                        if (type == ProviderProxyType.http) ...[
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: TextField(
                              controller: addressController,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                hintText: '地址，例如 127.0.0.1',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
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
                          const Divider(height: 1, indent: 16, endIndent: 16),
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
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: TextField(
                              controller: passwordController,
                              obscureText: !showPassword,
                              decoration: InputDecoration(
                                hintText: '密码（可选）',
                                border: InputBorder.none,
                                suffixIcon: IconButton(
                                  onPressed: () => setModalState(
                                    () => showPassword = !showPassword,
                                  ),
                                  icon: Icon(
                                    showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if ((error ?? '').trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    if (type == ProviderProxyType.none) {
                                      Navigator.of(ctx).pop(
                                        const ProviderProxy.none(),
                                      );
                                      return;
                                    }
                                    final address = addressController.text.trim();
                                    final port = int.tryParse(
                                          portController.text.trim(),
                                        ) ??
                                        0;
                                    if (address.isEmpty ||
                                        port <= 0 ||
                                        port > 65535) {
                                      setModalState(
                                        () => error = '请填写正确的地址与端口',
                                      );
                                      return;
                                    }

                                    final username = usernameController.text.trim();
                                    final password = passwordController.text.trim();
                                    Navigator.of(ctx).pop(
                                      ProviderProxy.http(
                                        address: address,
                                        port: port,
                                        username:
                                            username.isEmpty ? null : username,
                                        password:
                                            password.isEmpty ? null : password,
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
    _showToast('已更新代理');
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
      _showToast('余额已更新');
    } catch (e) {
      _showToast('获取余额失败：$e');
    } finally {
      if (!mounted) return;
      setState(() => _fetchingBalance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        bottom: true,
        child: ValueListenableBuilder<Box<String>>(
          valueListenable: ApiConfigStorage.listenable(),
          builder: (context, box, _) {
            final config = ApiConfigStorage.getConfig(widget.configId);
            if (config == null) {
              return const Center(child: Text('服务商不存在'));
            }

            final roles = _baseModelRolesForConfig(configId: config.id);
            final selected = (config.selectedModel ?? '').trim();
            final selectedName = selected.isEmpty
                ? null
                : (config.getModelById(selected)?.displayName ?? selected);

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 40),
                  children: [
                    // 配置卡片
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题行
                          Row(
                            children: [
                              Text(
                                _getProviderIcon(config),
                                style: TextStyle(
                                  fontSize: 24,
                                  color: _getProviderColor(config),
                                ),
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
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              _CircleIconButton(
                                icon: Icons.edit_outlined,
                                onTap: () => _editProviderName(config),
                              ),
                            ],
                          ),
                          if (roles.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final role in roles) _RoleChip(text: role),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),

                          // 是否启用
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '是否启用',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                              _CustomSwitch(
                                value: config.isActive,
                                onChanged: (v) => _toggleActive(config, v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // API 类型
                          _FieldBox(
                            label: 'API 类型',
                            value: _providerTypeLabel(config.type),
                            isDropdown: true,
                            onTap: () => _pickProviderType(config),
                          ),
                          const SizedBox(height: 12),

                          // API 地址
                          _FieldBox(
                            label: 'API 地址',
                            value: config.baseUrl.isEmpty ? '未设置' : config.baseUrl,
                            onTap: () => _editBaseUrl(config),
                            trailing: _FieldTrailing(
                              onCopy: config.baseUrl.trim().isEmpty
                                  ? null
                                  : () => _copyToClipboard(
                                        config.baseUrl,
                                        hint: '已复制 API 地址',
                                      ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // API Key
                          _FieldBox(
                            label: 'API Key',
                            value: _maskApiKey(config.apiKey),
                            onTap: () => _editApiKey(config),
                            trailing: _FieldTrailing(
                              onCopy: config.apiKey.trim().isEmpty
                                  ? null
                                  : () => _copyToClipboard(
                                        config.apiKey,
                                        hint: '已复制 API Key',
                                      ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 代理
                          _FieldBox(
                            label: '代理',
                            value: _proxyLabel(config.proxy),
                            onTap: () => _editProxy(config),
                          ),
                          if (config.balanceOption.enabled) ...[
                            const SizedBox(height: 12),
                            _FieldBox(
                              label: '余额',
                              value: _fetchingBalance
                                  ? '获取中…'
                                  : (_balanceLabel ?? '点击获取'),
                              enabled: !_fetchingBalance,
                              onTap: _fetchingBalance ? null : () => _fetchBalance(config),
                              trailing: _FieldTrailing(
                                onCopy: _balanceLabel == null
                                    ? null
                                    : () => _copyToClipboard(
                                          _balanceLabel!,
                                          hint: '已复制余额',
                                        ),
                                showRefresh: true,
                                refreshing: _fetchingBalance,
                                showChevron: false,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 模型列表入口
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9E9EA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _openModelList(config),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                const Text('🤖', style: TextStyle(fontSize: 24)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '模型列表',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        selectedName == null
                                            ? '共 ${config.models.length} 个模型'
                                            : '默认：$selectedName · 共 ${config.models.length} 个模型',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: Colors.grey[500],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 操作按钮
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _detectingModels
                                  ? null
                                  : () => _detectModels(config),
                              icon: _detectingModels
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh),
                              label: Text(_detectingModels ? '检测中…' : '检测模型'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 删除按钮
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextButton(
                        onPressed: () => _deleteProvider(config),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF0F0),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('删除此供应商'),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 8,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: const Offset(0, -0.15),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    child: _toastMessage == null
                        ? const SizedBox.shrink()
                        : _ToastBanner(
                            key: ValueKey(_toastMessage),
                            message: _toastMessage!,
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: _CircleIconButton(
        icon: Icons.arrow_back_ios_new,
        onTap: () => Navigator.of(context).pop(),
      ),
      title: ValueListenableBuilder<Box<String>>(
        valueListenable: ApiConfigStorage.listenable(),
        builder: (context, box, _) {
          final config = ApiConfigStorage.getConfig(widget.configId);
          return Text(
            config?.name ?? '服务商',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          );
        },
      ),
      actions: [
        _CircleIconButton(
          icon: Icons.check,
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),
      ],
    );
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

  String _getProviderIcon(ApiConfig config) {
    final name = config.name.toLowerCase();
    if (name.contains('qwen') || name.contains('通义')) return '❖';
    if (name.contains('openai') || name.contains('gpt')) return '⌘';
    if (name.contains('claude') || name.contains('anthropic')) return '✳';
    if (name.contains('google') || name.contains('gemini')) return 'G';
    if (name.contains('deepseek')) return '⚡';
    return '●';
  }

  Color _getProviderColor(ApiConfig config) {
    final name = config.name.toLowerCase();
    if (name.contains('qwen') || name.contains('通义')) return const Color(0xFF6366f1);
    if (name.contains('openai') || name.contains('gpt')) return Colors.black;
    if (name.contains('claude') || name.contains('anthropic')) return const Color(0xFFf97316);
    if (name.contains('google') || name.contains('gemini')) return const Color(0xFFea4335);
    if (name.contains('deepseek')) return const Color(0xFF3b82f6);
    return const Color(0xFF666666);
  }
}

// ============================================================================
// 模型列表页 (Image 5)
// ============================================================================

class _ModelListPage extends StatefulWidget {
  const _ModelListPage({required this.configId});

  final String configId;

  @override
  State<_ModelListPage> createState() => _ModelListPageState();
}

class _ModelListPageState extends State<_ModelListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: action,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<String> _baseModelRolesForModel({
    required String configId,
    required String modelId,
  }) {
    final raw = Hive.box(AiConfigStorage.boxName).get('base_models');
    if (raw is! Map) return [];
    final baseModels = AiBaseModelsConfig.fromMap(raw) ?? const AiBaseModelsConfig();

    final roles = <String>[];
    if (baseModels.hasChatModel &&
        baseModels.chatConfigId == configId &&
        baseModels.chatModel == modelId) {
      roles.add('默认对话');
    }
    if (baseModels.ocrEnabled &&
        baseModels.hasOcrModel &&
        baseModels.ocrConfigId == configId &&
        baseModels.ocrModel == modelId) {
      roles.add('OCR');
    }
    if (baseModels.hasImageGenModel &&
        baseModels.imageGenConfigId == configId &&
        baseModels.imageGenModel == modelId) {
      roles.add('生图');
    }
    return roles;
  }

  Future<void> _syncBaseModelsSupportsImage({
    required String configId,
    required ApiModel model,
  }) async {
    final raw = Hive.box(AiConfigStorage.boxName).get('base_models');
    if (raw is! Map) return;
    final baseModels = AiBaseModelsConfig.fromMap(raw) ?? const AiBaseModelsConfig();

    var next = baseModels;
    var changed = false;

    if (baseModels.hasChatModel &&
        baseModels.chatConfigId == configId &&
        baseModels.chatModel == model.modelId &&
        baseModels.chatModelSupportsImage != model.supportsImageInput) {
      next = next.copyWith(chatModelSupportsImage: model.supportsImageInput);
      changed = true;
    }

    if (baseModels.ocrEnabled &&
        baseModels.hasOcrModel &&
        baseModels.ocrConfigId == configId &&
        baseModels.ocrModel == model.modelId &&
        baseModels.ocrModelSupportsImage != model.supportsImageInput) {
      next = next.copyWith(ocrModelSupportsImage: model.supportsImageInput);
      changed = true;
    }

    if (!changed) return;
    await AiConfigStorage.saveBaseModelsConfig(next);
  }

  Future<void> _selectModel(ApiConfig config, String modelId) async {
    HapticFeedback.selectionClick();
    await ApiConfigStorage.saveConfig(config.copyWith(selectedModel: modelId));
  }

  Future<ApiModel?> _showModelEditorSheet({
    required String title,
    ApiModel? initial,
    required bool editModelId,
  }) async {
    final modelIdController = TextEditingController(text: initial?.modelId ?? '');
    final displayNameController = TextEditingController(
      text: initial == null
          ? ''
          : (initial.displayName.trim() == initial.modelId.trim()
              ? ''
              : initial.displayName),
    );

    var supportsImage = initial?.supportsImageInput ?? false;
    var draftModelId = modelIdController.text.trim();
    var draftName = displayNameController.text.trim();

    final result = await showModalBottomSheet<ApiModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            final canSave = draftModelId.isNotEmpty;

            Widget buildInput({
              required String label,
              required TextEditingController controller,
              required String hintText,
              bool readOnly = false,
              VoidCallback? onCopy,
              ValueChanged<String>? onChanged,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            readOnly: readOnly,
                            autofocus: initial == null && label == '模型 ID',
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                            decoration: InputDecoration(
                              hintText: hintText,
                              hintStyle:
                                  TextStyle(fontSize: 16, color: Colors.grey[400]),
                              border: InputBorder.none,
                            ),
                            onChanged: onChanged,
                          ),
                        ),
                        if (onCopy != null)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            constraints:
                                const BoxConstraints.tightFor(width: 36, height: 36),
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              onCopy();
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }

            Widget buildSwitchRow({
              required IconData icon,
              required String title,
              required String subtitle,
              required bool value,
              required ValueChanged<bool> onChanged,
            }) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 18, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    _CustomSwitch(
                      value: value,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        onChanged(v);
                      },
                    ),
                  ],
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            _CircleIconButton(
                              icon: Icons.close,
                              onTap: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        buildInput(
                          label: '模型 ID',
                          controller: modelIdController,
                          hintText: '例如：gpt-4o-mini',
                          readOnly: !editModelId,
                          onCopy: !editModelId
                              ? () {
                                  Clipboard.setData(
                                    ClipboardData(text: modelIdController.text.trim()),
                                  );
                                  _showSnack('已复制');
                                }
                              : null,
                          onChanged: (v) => setStateSheet(() {
                            draftModelId = v.trim();
                          }),
                        ),
                        const SizedBox(height: 14),
                        buildInput(
                          label: '显示名称（可选）',
                          controller: displayNameController,
                          hintText: '例如：GPT-4o mini',
                          onChanged: (v) => setStateSheet(() {
                            draftName = v.trim();
                          }),
                        ),
                        const SizedBox(height: 14),
                        buildSwitchRow(
                          icon: Icons.image_outlined,
                          title: '支持识图',
                          subtitle: '允许上传图片作为输入',
                          value: supportsImage,
                          onChanged: (v) => setStateSheet(() {
                            supportsImage = v;
                          }),
                        ),
                        const SizedBox(height: 16),
                        Row(
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
                                onPressed: !canSave
                                    ? null
                                    : () {
                                        final id = draftModelId.trim();
                                        final displayName =
                                            draftName.trim().isEmpty ? id : draftName.trim();
                                        final next = ApiModel(
                                          id: initial?.id ?? id,
                                          modelId: id,
                                          displayName: displayName,
                                          type: initial?.type ?? ModelType.chat,
                                          inputModalities: supportsImage
                                              ? const [
                                                  ModelModality.text,
                                                  ModelModality.image,
                                                ]
                                              : const [ModelModality.text],
                                          outputModalities: initial?.outputModalities ??
                                              const [ModelModality.text],
                                          abilities:
                                              initial?.abilities ?? const <ModelAbility>[],
                                        );
                                        Navigator.of(ctx).pop(next);
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(initial == null ? '添加' : '保存'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    modelIdController.dispose();
    displayNameController.dispose();
    return result;
  }

  Future<void> _addModel(ApiConfig config) async {
    final created = await _showModelEditorSheet(
      title: '添加模型',
      editModelId: true,
    );
    if (created == null) return;

    final id = created.modelId.trim();
    if (id.isEmpty) return;
    if (config.getModelById(id) != null) {
      _showSnack('模型已存在');
      return;
    }

    final updated = List<ApiModel>.from(config.models)..add(created);
    final selected = (config.selectedModel ?? '').trim();
    final nextSelected = selected.isEmpty ? id : config.selectedModel;

    await ApiConfigStorage.saveConfig(
      config.copyWith(models: updated, selectedModel: nextSelected),
    );

    if (!mounted) return;
    _showSnack('已添加 ${created.displayName}');
  }

  Future<void> _editModel(ApiConfig config, ApiModel model) async {
    HapticFeedback.selectionClick();
    final edited = await _showModelEditorSheet(
      title: '编辑模型',
      initial: model,
      editModelId: false,
    );
    if (edited == null) return;

    final updated = List<ApiModel>.from(config.models);
    final idx = updated.indexWhere((m) => m.modelId == model.modelId);
    if (idx < 0) return;
    updated[idx] = edited;

    await ApiConfigStorage.saveConfig(config.copyWith(models: updated));
    await _syncBaseModelsSupportsImage(configId: config.id, model: edited);
    if (!mounted) return;
    _showSnack('已保存');
  }

  Future<void> _removeModelWithUndo(ApiConfig config, ApiModel model) async {
    final roles = _baseModelRolesForModel(
      configId: config.id,
      modelId: model.modelId,
    );
    if (roles.isNotEmpty) {
      _showSnack('该模型正在用于：${roles.join('、')}');
      return;
    }

    final originalIndex = config.models.indexWhere((m) => m.modelId == model.modelId);
    final originalSelected = config.selectedModel;

    HapticFeedback.mediumImpact();
    final updated = List<ApiModel>.from(config.models)
      ..removeWhere((m) => m.modelId == model.modelId);
    final nextSelected = config.selectedModel == model.modelId
        ? (updated.isEmpty ? null : updated.first.modelId)
        : config.selectedModel;

    await ApiConfigStorage.saveConfig(
      config.copyWith(models: updated, selectedModel: nextSelected),
    );

    if (!mounted) return;
    _showSnack(
      '已删除 ${model.displayName.isNotEmpty ? model.displayName : model.modelId}',
      action: SnackBarAction(
        label: '撤销',
        onPressed: () async {
          final latest = ApiConfigStorage.getConfig(widget.configId);
          if (latest == null) return;
          if (latest.getModelById(model.modelId) != null) return;

          final restored = List<ApiModel>.from(latest.models);
          final insertIndex =
              (originalIndex < 0 ? restored.length : originalIndex).clamp(0, restored.length);
          restored.insert(insertIndex, model);
          await ApiConfigStorage.saveConfig(
            latest.copyWith(models: restored, selectedModel: originalSelected),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: _CircleIconButton(
          icon: Icons.arrow_back_ios_new,
          onTap: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '模型列表',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          _CircleIconButton(
            icon: Icons.add,
            onTap: () {
              final config = ApiConfigStorage.getConfig(widget.configId);
              if (config != null) _addModel(config);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<String>>(
          valueListenable: ApiConfigStorage.listenable(),
          builder: (context, box, _) {
            final config = ApiConfigStorage.getConfig(widget.configId);
            if (config == null) {
              return const Center(child: Text('配置不存在'));
            }

            final query = _searchController.text.trim().toLowerCase();
            final models = query.isEmpty
                ? config.models
                : config.models.where((m) =>
                    m.modelId.toLowerCase().contains(query) ||
                    m.displayName.toLowerCase().contains(query)).toList();
            final totalCount = config.models.length;
            final shownCount = models.length;
            final selectedId = (config.selectedModel ?? '').trim();
            final selectedName = selectedId.isEmpty
                ? null
                : (config.getModelById(selectedId)?.displayName ?? selectedId);

            return Column(
              children: [
                // 搜索栏
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _SearchBar(
                    controller: _searchController,
                    hintText: '名称或 ID',
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                // 统计行
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        shownCount == totalCount
                            ? '共 $totalCount 个模型'
                            : '显示 $shownCount/$totalCount 个模型',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      if (selectedName != null)
                        Flexible(
                          child: Text(
                            '默认: $selectedName',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                // 模型列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: models.length,
                    itemBuilder: (ctx, index) {
                      final model = models[index];
                      final isSelected = model.modelId == config.selectedModel;
                      final name = model.displayName.trim();
                      final title =
                          name.isEmpty ? model.modelId : name;
                      final subtitle = name.isEmpty || name == model.modelId
                          ? null
                          : model.modelId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Dismissible(
                            key: Key(model.modelId),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              final roles = _baseModelRolesForModel(
                                configId: config.id,
                                modelId: model.modelId,
                              );
                              if (roles.isEmpty) return true;
                              _showSnack('该模型正在用于：${roles.join('、')}');
                              return false;
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => _removeModelWithUndo(config, model),
                            child: Material(
                              color: isSelected
                                  ? const Color(0xFFE8E8ED)
                                  : const Color(0xFFF2F2F7),
                              child: InkWell(
                                onTap: () => _selectModel(config, model.modelId),
                                onLongPress: () => _editModel(config, model),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                                  decoration: isSelected
                                      ? BoxDecoration(
                                          border: Border.all(color: Colors.black, width: 2),
                                          borderRadius: BorderRadius.circular(16),
                                        )
                                      : null,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (subtitle != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                subtitle,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (model.supportsImageInput) ...[
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.image_outlined,
                                            size: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints.tightFor(
                                          width: 36,
                                          height: 36,
                                        ),
                                        icon: Icon(
                                          Icons.tune_rounded,
                                          size: 18,
                                          color: Colors.grey[700],
                                        ),
                                        onPressed: () => _editModel(config, model),
                                      ),
                                      if (isSelected)
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Colors.black,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// 组件
// ============================================================================

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: !enabled
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap?.call();
                },
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 22,
              color: enabled ? Colors.black : Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    this.hintText = '搜索',
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 16, color: Colors.black),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.trim().isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.clear();
                  onChanged?.call('');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Icon(
                    Icons.cancel,
                    size: 18,
                    color: Colors.grey[500],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({
    required this.label,
    required this.value,
    this.isDropdown = false,
    this.onTap,
    this.trailing,
    this.enabled = true,
  });

  final String label;
  final String value;
  final bool isDropdown;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final clickable = onTap != null && enabled;
    final trimmed = value.trim();
    final isPlaceholder = trimmed.isEmpty || trimmed == '未设置';
    final valueColor = isPlaceholder ? Colors.grey[400] : Colors.black;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: !clickable
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap?.call();
                },
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D1D6)),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标签
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                // 值
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          style: TextStyle(fontSize: 15, color: valueColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (trailing != null)
                        trailing!
                      else if (isDropdown)
                        Icon(Icons.arrow_drop_down, color: Colors.grey[400])
                      else if (onTap != null)
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomSwitch extends StatelessWidget {
  const _CustomSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 32,
        decoration: BoxDecoration(
          color: value ? Colors.black : const Color(0xFFE9E9EA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(2),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastBanner extends StatelessWidget {
  const _ToastBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 14, color: Color(0xFF856404)),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.1,
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FieldTrailing extends StatelessWidget {
  const _FieldTrailing({
    this.onCopy,
    this.showRefresh = false,
    this.refreshing = false,
    this.showChevron = true,
  });

  final VoidCallback? onCopy;
  final bool showRefresh;
  final bool refreshing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showRefresh) ...[
          SizedBox(
            width: 30,
            height: 30,
            child: Center(
              child: refreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.refresh,
                      size: 18,
                      color: Colors.grey[500],
                    ),
            ),
          ),
        ],
        if (onCopy != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 34, height: 30),
            icon: Icon(Icons.copy_rounded, size: 18, color: Colors.grey[600]),
            onPressed: () {
              HapticFeedback.selectionClick();
              onCopy?.call();
            },
          ),
        if (showChevron)
          Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
      ],
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check, color: Colors.black)
            else
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
