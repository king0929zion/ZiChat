import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/storage/ai_config_storage.dart';
import 'package:zichat/storage/api_config_storage.dart';

/// 基础模型页 (默认助手) - 对标 HTML 原型 (Image 3)
class BaseModelsPage extends StatelessWidget {
  const BaseModelsPage({super.key});

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
          '默认助手',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: ValueListenableBuilder<Box>(
          valueListenable: Hive.box(AiConfigStorage.boxName).listenable(),
          builder: (context, _, __) {
            return ValueListenableBuilder<Box<String>>(
              valueListenable: ApiConfigStorage.listenable(),
              builder: (context, ___, ____) {
                return const _BaseModelsBody();
              },
            );
          },
        ),
      ),
    );
  }
}

class _BaseModelsBody extends StatelessWidget {
  const _BaseModelsBody();

  @override
  Widget build(BuildContext context) {
    final configs = ApiConfigStorage.getAllConfigs();
    final enabledConfigs = configs.where((c) => c.isActive).toList();

    final baseConfig = Hive.box(AiConfigStorage.boxName).get('base_models') as Map?;
    final models = AiBaseModelsConfig.fromMap(baseConfig) ?? const AiBaseModelsConfig();

    if (configs.isEmpty) {
      return _EmptyState(
        icon: Icons.api_outlined,
        title: '还没有服务商',
        subtitle: '请先在"模型服务"中添加并启用服务商',
      );
    }

    if (enabledConfigs.isEmpty) {
      return _EmptyState(
        icon: Icons.toggle_off_outlined,
        title: '还没有启用的服务商',
        subtitle: '请先在"模型服务"中启用至少一个服务商',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 10),

        // 默认助手
        _SectionHeader(
          icon: Icons.chat_bubble_outline,
          title: '默认助手',
        ),
        _ModelSelectCard(
          modelName: models.chatModel ?? '未设置',
          providerName: _getProviderName(configs, models.chatConfigId),
          iconColor: const Color(0xFF6366f1),
          icon: '❖',
          onTap: () => _showModelPicker(
            context: context,
            title: '选择默认对话模型',
            configs: enabledConfigs,
            initialConfigId: models.chatConfigId,
            initialModel: models.chatModel,
            onSelected: (configId, model) async {
              final selectedConfig = configs.where((c) => c.id == configId).firstOrNull;
              final selectedModel = selectedConfig?.getModelById(model);
              await AiConfigStorage.saveBaseModelsConfig(
                models.copyWith(
                  chatConfigId: configId,
                  chatModel: model,
                  chatModelSupportsImage: selectedModel?.supportsImageInput ?? false,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            '创建新助手时使用的助手，如果未设置助手，将使用此助手',
            style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.4),
          ),
        ),

        const SizedBox(height: 32),

        // 快速助手
        _SectionHeader(
          icon: Icons.flash_on,
          title: '快速助手',
        ),
        _ModelSelectCard(
          modelName: models.ocrModel ?? '未设置',
          providerName: _getProviderName(configs, models.ocrConfigId),
          iconColor: const Color(0xFF3b82f6),
          icon: '⚡',
          onTap: () => _showModelPicker(
            context: context,
            title: '选择快速助手模型',
            configs: enabledConfigs,
            initialConfigId: models.ocrConfigId,
            initialModel: models.ocrModel,
            onSelected: (configId, model) async {
              final selectedConfig = configs.where((c) => c.id == configId).firstOrNull;
              final selectedModel = selectedConfig?.getModelById(model);
              await AiConfigStorage.saveBaseModelsConfig(
                models.copyWith(
                  ocrEnabled: true,
                  ocrConfigId: configId,
                  ocrModel: model,
                  ocrModelSupportsImage: selectedModel?.supportsImageInput ?? true,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            '用于简单任务的助手，例如话题命名和关键字提取',
            style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.4),
          ),
        ),

        const SizedBox(height: 32),

        // 生图助手
        _SectionHeader(
          icon: Icons.image_outlined,
          title: '生图助手',
        ),
        _ModelSelectCard(
          modelName: models.imageGenModel ?? '未设置',
          providerName: _getProviderName(configs, models.imageGenConfigId),
          iconColor: const Color(0xFF10b981),
          icon: '🎨',
          onTap: () => _showModelPicker(
            context: context,
            title: '选择生图模型',
            configs: enabledConfigs,
            initialConfigId: models.imageGenConfigId,
            initialModel: models.imageGenModel,
            onSelected: (configId, model) async {
              await AiConfigStorage.saveBaseModelsConfig(
                models.copyWith(
                  imageGenConfigId: configId,
                  imageGenModel: model,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            '用于图片生成的模型',
            style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.4),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  String _getProviderName(List<ApiConfig> configs, String? configId) {
    if (configId == null || configId.isEmpty) return '';
    final provider = configs.where((c) => c.id == configId).firstOrNull;
    return provider?.name ?? '';
  }

  void _showModelPicker({
    required BuildContext context,
    required String title,
    required List<ApiConfig> configs,
    required String? initialConfigId,
    required String? initialModel,
    required Future<void> Function(String configId, String model) onSelected,
  }) {
    if (configs.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ModelPickerSheet(
        title: title,
        configs: configs,
        initialConfigId: initialConfigId ?? configs.first.id,
        initialModel: initialModel,
        onSelected: onSelected,
      ),
    );
  }
}

// ============================================================================
// 底部弹窗选择器 (Bottom Sheet)
// ============================================================================

class _ModelPickerSheet extends StatefulWidget {
  const _ModelPickerSheet({
    required this.title,
    required this.configs,
    required this.initialConfigId,
    required this.initialModel,
    required this.onSelected,
  });

  final String title;
  final List<ApiConfig> configs;
  final String initialConfigId;
  final String? initialModel;
  final Future<void> Function(String configId, String model) onSelected;

  @override
  State<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<_ModelPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedConfigId;
  late String? _selectedModel;

  @override
  void initState() {
    super.initState();
    _selectedConfigId = widget.initialConfigId;
    _selectedModel = widget.initialModel;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ModelOption> _buildModelOptions() {
    final options = <_ModelOption>[];
    
    for (final config in widget.configs) {
      for (final model in config.models) {
        options.add(_ModelOption(
          configId: config.id,
          modelId: model.modelId,
          providerName: config.name,
          iconColor: _getProviderColor(config.name),
          icon: _getProviderIcon(config.name),
        ));
      }
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return options;

    return options.where((o) =>
      o.modelId.toLowerCase().contains(query) ||
      o.providerName.toLowerCase().contains(query)
    ).toList();
  }

  String _getProviderIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('qwen') || n.contains('通义')) return '❖';
    if (n.contains('openai') || n.contains('gpt')) return '⌘';
    if (n.contains('claude') || n.contains('anthropic')) return '✳';
    if (n.contains('google') || n.contains('gemini')) return 'G';
    if (n.contains('deepseek')) return '⚡';
    return '●';
  }

  Color _getProviderColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('qwen') || n.contains('通义')) return const Color(0xFF6366f1);
    if (n.contains('openai') || n.contains('gpt')) return Colors.black;
    if (n.contains('claude') || n.contains('anthropic')) return const Color(0xFFf97316);
    if (n.contains('google') || n.contains('gemini')) return const Color(0xFFea4335);
    if (n.contains('deepseek')) return const Color(0xFF3b82f6);
    return const Color(0xFF666666);
  }

  @override
  Widget build(BuildContext context) {
    final options = _buildModelOptions();
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 拖拽条
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Text(
                    '完成',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 搜索栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      decoration: InputDecoration(
                        hintText: '搜索模型...',
                        hintStyle: TextStyle(fontSize: 16, color: Colors.grey[400]),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 模型列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              itemCount: options.length,
              itemBuilder: (ctx, index) {
                final option = options[index];
                final isSelected = option.configId == _selectedConfigId &&
                    option.modelId == _selectedModel;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected
                        ? const Color(0xFFE8E8ED)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedConfigId = option.configId;
                          _selectedModel = option.modelId;
                        });
                        await widget.onSelected(option.configId, option.modelId);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: isSelected
                            ? BoxDecoration(
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(14),
                              )
                            : null,
                        child: Row(
                          children: [
                            // 图标
                            Text(
                              option.icon,
                              style: TextStyle(
                                fontSize: 20,
                                color: option.iconColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 内容
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.modelId,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    option.providerName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 选中标记
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelOption {
  const _ModelOption({
    required this.configId,
    required this.modelId,
    required this.providerName,
    required this.iconColor,
    required this.icon,
  });

  final String configId;
  final String modelId;
  final String providerName;
  final Color iconColor;
  final String icon;
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Icon(Icons.settings, size: 20, color: const Color(0xFF007AFF)),
        ],
      ),
    );
  }
}

class _ModelSelectCard extends StatelessWidget {
  const _ModelSelectCard({
    required this.modelName,
    required this.providerName,
    required this.iconColor,
    required this.icon,
    required this.onTap,
  });

  final String modelName;
  final String providerName;
  final Color iconColor;
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEEEEEE)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // 图标
              Text(
                icon,
                style: TextStyle(fontSize: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              // 模型名
              Text(
                modelName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              if (providerName.isNotEmpty) ...[
                Text(
                  '  |  ',
                  style: TextStyle(color: Colors.grey[300]),
                ),
                Text(
                  providerName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
              const Spacer(),
              // 下拉箭头
              Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
