import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/pages/model_services/base_models_page.dart';
import 'package:zichat/pages/model_services/provider_detail_page.dart';
import 'package:zichat/storage/api_config_storage.dart';

/// 模型服务页 - 对标 HTML 原型
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
      }
      return false;
    }).toList();
  }

  Future<void> _showAddProviderSheet(List<ApiConfig> current) async {
    HapticFeedback.lightImpact();
    final nextOrder = current.isEmpty
        ? 100
        : (current.map((c) => c.sortOrder ?? 100).reduce((a, b) => a > b ? a : b) + 1);

    final type = await showModalBottomSheet<ProviderType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AddProviderSheet(),
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
          name: 'Google',
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
          name: 'OpenAI',
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
            final configs = ApiConfigStorage.getAllConfigs();
            final filtered = _filterConfigs(configs);

            return Column(
              children: [
                // 搜索栏
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _SearchBar(
                    controller: _searchController,
                    hintText: '输入厂商名称',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                // 列表
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // 默认助手入口
                      _ProviderTile(
                        icon: '⚙️',
                        name: '默认助手设置',
                        onTap: _openBaseModels,
                        showChevron: true,
                      ),
                      const SizedBox(height: 12),
                      // 供应商列表
                      ...filtered.map((config) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProviderTile(
                          icon: _getProviderIcon(config),
                          iconColor: _getProviderColor(config),
                          name: config.name,
                          isActive: config.isActive,
                          onTap: () => _openProvider(config),
                        ),
                      )),
                      if (configs.isEmpty)
                        _EmptyState(onAdd: () => _showAddProviderSheet(configs)),
                    ],
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
      title: const Text(
        '模型服务',
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
            final configs = ApiConfigStorage.getAllConfigs();
            _showAddProviderSheet(configs);
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  String _getProviderIcon(ApiConfig config) {
    final name = config.name.toLowerCase();
    if (name.contains('qwen') || name.contains('通义')) return '❖';
    if (name.contains('openai') || name.contains('gpt')) return '⌘';
    if (name.contains('claude') || name.contains('anthropic')) return '✳';
    if (name.contains('google') || name.contains('gemini')) return 'G';
    if (name.contains('deepseek')) return '⚡';
    if (name.contains('ollama')) return '🦙';
    if (name.contains('doubao') || name.contains('豆包')) return '◆';
    return config.name.isNotEmpty ? config.name[0].toUpperCase() : 'AI';
  }

  Color _getProviderColor(ApiConfig config) {
    final name = config.name.toLowerCase();
    if (name.contains('qwen') || name.contains('通义')) return const Color(0xFF6366f1);
    if (name.contains('openai') || name.contains('gpt')) return Colors.black;
    if (name.contains('claude') || name.contains('anthropic')) return const Color(0xFFf97316);
    if (name.contains('google') || name.contains('gemini')) return const Color(0xFFea4335);
    if (name.contains('deepseek')) return const Color(0xFF3b82f6);
    if (name.contains('doubao') || name.contains('豆包')) return const Color(0xFFa855f7);
    return const Color(0xFF666666);
  }
}

// ============================================================================
// 组件
// ============================================================================

/// 圆形图标按钮
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

/// 搜索栏
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

/// 供应商卡片
class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.icon,
    required this.name,
    this.iconColor,
    this.isActive,
    this.showChevron = false,
    this.onTap,
  });

  final String icon;
  final String name;
  final Color? iconColor;
  final bool? isActive;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F2F7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              // 图标
              SizedBox(
                width: 28,
                child: Text(
                  icon,
                  style: TextStyle(
                    fontSize: 20,
                    color: iconColor ?? Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // 名称
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              // 状态点 / 箭头
              if (isActive == true)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34c759),
                    shape: BoxShape.circle,
                  ),
                )
              else if (showChevron)
                Text(
                  '›',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.grey[400],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 空状态
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

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
              child: Icon(Icons.api_outlined, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            const Text(
              '暂无模型服务',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角 + 添加服务商',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('添加服务商'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 添加供应商底部弹窗
class _AddProviderSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            // 标题
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '添加服务商',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            // 选项
            _SheetOption(
              title: 'OpenAI 兼容',
              subtitle: '适用于 OpenAI / SiliconFlow / DeepSeek 等',
              onTap: () => Navigator.of(context).pop(ProviderType.openai),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _SheetOption(
              title: 'Google Gemini',
              subtitle: 'Google Gemini 官方 API',
              onTap: () => Navigator.of(context).pop(ProviderType.google),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _SheetOption(
              title: 'Anthropic Claude',
              subtitle: 'Claude Messages API',
              onTap: () => Navigator.of(context).pop(ProviderType.claude),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
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
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
