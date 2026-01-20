import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/pages/api_edit_page.dart';
import 'package:zichat/storage/api_config_storage.dart';
import 'package:zichat/widgets/weui/weui.dart';

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
        WeuiToast.show(context, message: 'API 已添加');
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
        WeuiToast.show(context, message: 'API 已更新');
      }
    }
  }

  Future<void> _setActive(ApiConfig config) async {
    HapticFeedback.selectionClick();
    await ApiConfigStorage.setActiveConfig(config.id);
    _loadConfigs();
    if (mounted) {
      WeuiToast.show(context, message: '${config.name} 已设为默认');
    }
  }

  Future<void> _deleteConfig(ApiConfig config) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除 API'),
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
    if (confirm == true) {
      HapticFeedback.mediumImpact();
      await ApiConfigStorage.deleteConfig(config.id);
      _loadConfigs();
      if (mounted) {
        WeuiToast.show(context, message: 'API 已删除');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
        title: const Text('API 管理'),
        actions: [
          IconButton(
            onPressed: _addConfig,
            icon: const Icon(Icons.add, size: 28),
            color: AppColors.textPrimary,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _configs.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 20),
                    children: [
                      WeuiCellGroup(
                        inset: true,
                        margin: EdgeInsets.zero,
                        children: [
                          for (final config in _configs)
                            _ApiConfigTile(
                              config: config,
                              onTap: () {
                                _editConfig(config);
                              },
                              onMore: () {
                                _showMoreOptions(config);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.api_outlined,
                  size: 40,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 12),
                const Text(
                  '暂无 API 配置',
                  style: AppStyles.titleSmall,
                ),
                const SizedBox(height: 4),
                const Text(
                  '点击下方按钮添加你的第一个 API',
                  style: AppStyles.caption,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMoreOptions(ApiConfig config) {
    final actions = <WeuiActionSheetAction>[
      if (!config.isActive)
        WeuiActionSheetAction(
          label: '设为默认',
          tone: WeuiActionSheetTone.primary,
          onTap: () {
            _setActive(config);
          },
        ),
      WeuiActionSheetAction(
        label: '编辑',
        onTap: () {
          _editConfig(config);
        },
      ),
      WeuiActionSheetAction(
        label: '删除',
        tone: WeuiActionSheetTone.destructive,
        onTap: () {
          _deleteConfig(config);
        },
      ),
    ];

    showWeuiActionSheet(context: context, actions: actions);
  }
}

class _ApiConfigTile extends StatelessWidget {
  const _ApiConfigTile({
    required this.config,
    required this.onTap,
    required this.onMore,
  });

  final ApiConfig config;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return WeuiCell(
      title: config.name,
      description: config.baseUrl,
      showArrow: false,
      onTap: onTap,
      onLongPress: onMore,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '默认',
                style: TextStyle(fontSize: 10, color: AppColors.primary),
              ),
            ),
          const SizedBox(width: 8),
          SvgPicture.asset(
            AppAssets.iconArrowRight,
            width: 12,
            height: 12,
            colorFilter: const ColorFilter.mode(
              Colors.black26,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
