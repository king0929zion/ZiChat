import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/models/api_config.dart';
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
  String? _toastMessage;
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除服务商'),
        content: Text('确定要删除"${config.name}"吗？'),
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
      ),
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
        byId.putIfAbsent(model.modelId.trim(), () => model);
      }

      final merged = byId.values.toList()
        ..sort((a, b) => a.modelId.toLowerCase().compareTo(b.modelId.toLowerCase()));

      await ApiConfigStorage.saveConfig(config.copyWith(models: merged));
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

            return ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                // Toast
                if (_toastMessage != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _toastMessage!,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF856404)),
                    ),
                  ),

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
                          Text(
                            config.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 是否启用
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '是否启用',
                            style: TextStyle(fontSize: 15, color: Colors.black),
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
                      ),
                      const SizedBox(height: 12),

                      // API 地址
                      _FieldBox(
                        label: 'API 地址',
                        value: config.baseUrl.isEmpty ? '未设置' : config.baseUrl,
                      ),
                      const SizedBox(height: 12),

                      // API Key
                      _FieldBox(
                        label: 'API Key',
                        value: config.apiKey.isEmpty
                            ? '未设置'
                            : '${config.apiKey.substring(0, 8.clamp(0, config.apiKey.length))}...',
                      ),
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
                                    '共 ${config.models.length} 个模型',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '›',
                              style: TextStyle(fontSize: 24, color: Colors.grey[500]),
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
                          onPressed: _detectingModels ? null : () => _detectModels(config),
                          icon: _detectingModels
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(_detectingModels ? '检测中...' : '检测模型'),
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

  Future<void> _selectModel(ApiConfig config, String modelId) async {
    await ApiConfigStorage.saveConfig(config.copyWith(selectedModel: modelId));
  }

  Future<void> _removeModel(ApiConfig config, String modelId) async {
    HapticFeedback.mediumImpact();
    final updated = List<ApiModel>.from(config.models)
      ..removeWhere((m) => m.modelId == modelId);
    final nextSelected = config.selectedModel == modelId
        ? (updated.isEmpty ? null : updated.first.modelId)
        : config.selectedModel;
    await ApiConfigStorage.saveConfig(
      config.copyWith(models: updated, selectedModel: nextSelected),
    );
  }

  Future<void> _addModelManual(ApiConfig config) async {
    final controller = TextEditingController();
    final model = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
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
      ),
    );

    if (model == null || model.trim().isEmpty) return;
    if (config.getModelById(model.trim()) != null) return;

    final updated = List<ApiModel>.from(config.models)
      ..add(ApiModel.fromLegacy(model.trim()));
    await ApiConfigStorage.saveConfig(config.copyWith(models: updated));
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
              if (config != null) _addModelManual(config);
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '共 ${config.models.length} 个模型',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      if (config.selectedModel != null)
                        Text(
                          '默认: ${config.selectedModel}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
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
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: Key(model.modelId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _removeModel(config, model.modelId),
                          child: Material(
                            color: isSelected 
                                ? const Color(0xFFE8E8ED)
                                : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _selectModel(config, model.modelId),
                              child: Container(
                                height: 58,
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                decoration: isSelected
                                    ? BoxDecoration(
                                        border: Border.all(color: Colors.black, width: 2),
                                        borderRadius: BorderRadius.circular(16),
                                      )
                                    : null,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        model.modelId,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap?.call();
          },
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 22, color: Colors.black),
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
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

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
  });

  final String label;
  final String value;
  final bool isDropdown;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    style: const TextStyle(fontSize: 15, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDropdown)
                  Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
              ],
            ),
          ),
        ],
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
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
