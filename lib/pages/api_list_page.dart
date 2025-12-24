import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/pages/api_edit_page.dart';
import 'package:zichat/storage/api_config_storage.dart';

/// API 管理列表页面
class ApiListPage extends StatefulWidget {
  const ApiListPage({super.key});

  @override
  State<ApiListPage> createState() => _ApiListPageState();
}

class _ApiListPageState extends State<ApiListPage> {
  List<ApiConfig> _configs = [];

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  void _loadConfigs() {
    setState(() {
      _configs = ApiConfigStorage.getAllConfigs();
    });
  }

  Future<void> _addConfig() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.of(context).push<ApiConfig>(
      MaterialPageRoute(builder: (_) => const ApiEditPage()),
    );
    if (result != null) {
      await ApiConfigStorage.saveConfig(result);
      _loadConfigs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API 已添加')),
        );
      }
    }
  }

  Future<void> _editConfig(ApiConfig config) async {
    HapticFeedback.lightImpact();
    final result = await Navigator.of(context).push<ApiConfig>(
      MaterialPageRoute(
        builder: (_) => ApiEditPage(editConfig: config),
      ),
    );
    if (result != null) {
      await ApiConfigStorage.saveConfig(result);
      _loadConfigs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API 已更新')),
        );
      }
    }
  }

  Future<void> _setActive(ApiConfig config) async {
    HapticFeedback.selectionClick();
    await ApiConfigStorage.setActiveConfig(config.id);
    _loadConfigs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${config.name} 已设为默认')),
      );
    }
  }

  Future<void> _deleteConfig(ApiConfig config) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除 API'),
        content: Text('确定要删除 "${config.name}" 吗？'),
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
    if (confirm == true) {
      HapticFeedback.mediumImpact();
      await ApiConfigStorage.deleteConfig(config.id);
      _loadConfigs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API 已删除')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: SvgPicture.asset(
            'assets/icon/common/go-back.svg',
            width: 12,
            height: 20,
          ),
        ),
        title: const Text(
          'API 管理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D2129),
          ),
        ),
      ),
      body: _configs.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: _configs.length,
              itemBuilder: (context, index) {
                final config = _configs[index];
                return _ApiConfigTile(
                  config: config,
                  onEdit: () => _editConfig(config),
                  onSetActive: () => _setActive(config),
                  onDelete: () => _deleteConfig(config),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addConfig,
        backgroundColor: const Color(0xFF07C160),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '添加 API',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.api_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无 API 配置',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF86909C),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击下方按钮添加你的第一个 API',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFB8C0CC),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiConfigTile extends StatelessWidget {
  const _ApiConfigTile({
    required this.config,
    required this.onEdit,
    required this.onSetActive,
    required this.onDelete,
  });

  final ApiConfig config;
  final VoidCallback onEdit;
  final VoidCallback onSetActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = config.isActive;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: const Color(0xFF07C160), width: 1)
            : null,
      ),
      child: ListTile(
        title: Row(
          children: [
            Text(
              config.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? const Color(0xFF07C160) : const Color(0xFF1D2129),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF07C160).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '默认',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF07C160),
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          config.baseUrl,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF86909C),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isActive)
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: onSetActive,
                tooltip: '设为默认',
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 12),
                      Text('编辑'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 12),
                      Text('删除', style: TextStyle(color: Colors.red)),
                    ],
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
