import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/storage/api_config_storage.dart';
import 'package:zichat/widgets/weui/weui.dart';

/// 模型选择页面
/// 
/// 显示所有已配置供应商的可用模型，允许用户选择当前使用的对话模型
class ModelSelectionPage extends StatefulWidget {
  const ModelSelectionPage({super.key});

  @override
  State<ModelSelectionPage> createState() => _ModelSelectionPageState();
}

class _ModelSelectionPageState extends State<ModelSelectionPage> {
  List<ApiConfig> _configs = [];
  String? _selectedConfigId;
  String? _selectedModel;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final configs = ApiConfigStorage.getAllConfigs();
    final active = configs.where((c) => c.isActive).firstOrNull;
    
    setState(() {
      _configs = configs;
      _selectedConfigId = active?.id;
      _selectedModel = active?.selectedModel;
    });
  }

  Future<void> _selectModel(ApiConfig config, String model) async {
    HapticFeedback.selectionClick();
    
    // 更新配置的选中模型
    final updatedConfig = config.copyWith(selectedModel: model);
    await ApiConfigStorage.saveConfig(updatedConfig);
    
    // 设置为活动配置
    await ApiConfigStorage.setActiveConfig(config.id);
    
    _loadData();
    
    if (mounted) {
      WeuiToast.show(context, message: '已选择模型：$model');
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
        title: const Text('选择模型', style: AppStyles.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _configs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 12, bottom: 20),
                    itemCount: _configs.length,
                    itemBuilder: (context, index) {
                      final config = _configs[index];
                      return _buildProviderSection(config);
                    },
                  ),
          ),
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
            '暂无可用模型',
            style: AppStyles.titleSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            '请先添加 API 供应商',
            style: AppStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSection(ApiConfig config) {
    final isActiveProvider = config.id == _selectedConfigId;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActiveProvider ? AppColors.primary : AppColors.textHint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                config.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActiveProvider ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              if (isActiveProvider) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '当前供应商',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
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
                for (int i = 0; i < config.models.length; i++) ...[
                  _ModelTile(
                    model: config.models[i],
                    isSelected: isActiveProvider && config.models[i] == _selectedModel,
                    onTap: () => _selectModel(config, config.models[i]),
                  ),
                  if (i < config.models.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(left: 48),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ModelTile extends StatelessWidget {
  const _ModelTile({
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  final String model;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary 
                    : AppColors.background,
                shape: BoxShape.circle,
                border: isSelected 
                    ? null 
                    : Border.all(color: AppColors.divider, width: 1.5),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                model,
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
