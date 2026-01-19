import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/pages/api_list_page.dart';
import 'package:zichat/pages/model_selection_page.dart';
import 'package:zichat/storage/api_config_storage.dart';
import 'package:zichat/models/api_config.dart';

/// 模型配置页面 - 统一的 AI 配置入口
/// 
/// 包含两个模块：
/// 1. API 供应商配置 - 添加/管理 API 密钥
/// 2. 模型选择 - 选择当前使用的对话模型
class ModelConfigPage extends StatefulWidget {
  const ModelConfigPage({super.key});

  @override
  State<ModelConfigPage> createState() => _ModelConfigPageState();
}

class _ModelConfigPageState extends State<ModelConfigPage> {
  ApiConfig? _activeConfig;
  int _totalProviders = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _activeConfig = ApiConfigStorage.getActiveConfig();
      _totalProviders = ApiConfigStorage.getAllConfigs().length;
    });
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              children: [
                _buildStatusCard(),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'API 配置',
                  children: [
                    _ConfigTile(
                      icon: Icons.key_rounded,
                      iconColor: const Color(0xFFFF9800),
                      title: 'API 供应商',
                      subtitle: _totalProviders > 0
                          ? (_activeConfig != null
                              ? '默认：${_activeConfig!.name} · 共 $_totalProviders 个'
                              : '已添加 $_totalProviders 个供应商')
                          : '点击添加 API 供应商',
                      onTap: () => _openApiList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSection(
                  title: '模型设置',
                  children: [
                    _ConfigTile(
                      icon: Icons.smart_toy_rounded,
                      iconColor: const Color(0xFF2196F3),
                      title: '对话模型',
                      subtitle: _activeConfig != null
                          ? '${_activeConfig!.selectedModel ?? _activeConfig!.models.first} · ${_activeConfig!.name}'
                          : '请先配置 API 供应商',
                      onTap: () => _openModelSelection(),
                      enabled: _activeConfig != null,
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

  Widget _buildStatusCard() {
    final bool isConfigured = _activeConfig != null;
    final String title = isConfigured ? '已配置' : '未配置';
    final String subtitle = isConfigured
        ? '默认供应商：${_activeConfig!.name}'
        : '添加 API 供应商后即可使用 AI';
    final String? model = _activeConfig?.selectedModel;

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
                    color: (isConfigured ? AppColors.primary : AppColors.textHint)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                  ),
                  child: Icon(
                    isConfigured
                        ? Icons.check_circle_outline_rounded
                        : Icons.info_outline_rounded,
                    color: isConfigured ? AppColors.primary : AppColors.textSecondary,
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
            if (isConfigured) ...[
              const SizedBox(height: 12),
              Text(
                '当前模型：${model ?? '未选择'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _openApiList,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppStyles.radiusMedium),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Text(isConfigured ? '管理 API' : '添加 API'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isConfigured ? _openModelSelection : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppStyles.radiusMedium),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: Colors.transparent,
                    ),
                    child: const Text('选择模型'),
                  ),
                ),
              ],
            ),
          ],
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
                      padding: EdgeInsets.only(left: 56),
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

  void _openApiList() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ApiListPage()),
    );
    _loadData();
  }

  void _openModelSelection() async {
    if (_activeConfig == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加 API 供应商')),
      );
      return;
    }
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ModelSelectionPage()),
    );
    _loadData();
  }


}

class _ConfigTile extends StatelessWidget {
  const _ConfigTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppStyles.caption.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SvgPicture.asset(
                AppAssets.iconArrowRight,
                width: 12,
                height: 12,
                colorFilter: const ColorFilter.mode(
                  AppColors.textHint,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
