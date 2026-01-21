import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/pages/model_services/model_service_widgets.dart';
import 'package:zichat/storage/api_config_storage.dart';
import 'package:zichat/widgets/weui/weui_switch.dart';

class DefaultAssistantSettingsPage extends StatelessWidget {
  const DefaultAssistantSettingsPage({super.key, required this.configId});

  final String configId;

  Future<void> _save(ApiConfig config) => ApiConfigStorage.saveConfig(config);

  Future<void> _pickOcrModel(BuildContext context, ApiConfig config) async {
    if (config.models.isEmpty) {
      HapticFeedback.selectionClick();
      return;
    }

    final selected = await showModalBottomSheet<String>(
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
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        '选择 OCR 模型',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          for (final model in config.models)
                            ListTile(
                              title: Text(
                                model,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15),
                              ),
                              trailing: (config.ocrModel == model)
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: AppColors.primary,
                                    )
                                  : null,
                              onTap: () => Navigator.of(ctx).pop(model),
                            ),
                          const Divider(height: 1, color: AppColors.divider),
                          ListTile(
                            title: const Text('手动输入'),
                            onTap: () => Navigator.of(ctx).pop('__manual__'),
                          ),
                          if (config.ocrModel != null &&
                              config.ocrModel!.trim().isNotEmpty)
                            ListTile(
                              title: const Text('清除 OCR 模型'),
                              onTap: () => Navigator.of(ctx).pop('__clear__'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    if (!context.mounted) return;

    if (selected == '__manual__') {
      final controller = TextEditingController(text: config.ocrModel ?? '');
      final manual = await showDialog<String>(
        context: context,
        builder: (dctx) {
          return AlertDialog(
            title: const Text('OCR 模型'),
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
                onPressed: () => Navigator.of(dctx).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dctx).pop(controller.text.trim()),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
      if (manual == null) return;
      await _save(config.copyWith(ocrModel: manual.trim().isEmpty ? null : manual.trim()));
      return;
    }

    if (selected == '__clear__') {
      await _save(config.copyWith(ocrModel: null));
      return;
    }

    await _save(config.copyWith(ocrModel: selected));
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
        title: const Text(
          '默认助手',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ValueListenableBuilder<Box<String>>(
              valueListenable: ApiConfigStorage.listenable(),
              builder: (context, box, _) {
                final config = ApiConfigStorage.getConfig(configId);
                if (config == null) {
                  return const Center(
                    child: Text(
                      '服务商不存在',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                final ocrModelLabel = (config.ocrModel == null ||
                        config.ocrModel!.trim().isEmpty)
                    ? '未设置'
                    : config.ocrModel!.trim();

                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    const WeuiSectionTitle(title: '视觉与 OCR'),
                    WeuiInsetCard(
                      child: Column(
                        children: [
                          _SettingRow(
                            title: '图片输入',
                            description: '对话模型支持图片时直接发送图片',
                            trailing: WeuiSwitch(
                              value: config.chatModelSupportsImage,
                              onChanged: (v) =>
                                  _save(config.copyWith(chatModelSupportsImage: v)),
                            ),
                            showArrow: false,
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          _SettingRow(
                            title: 'OCR 回退',
                            description: '对话模型不支持图片时先做图片解析',
                            trailing: WeuiSwitch(
                              value: config.ocrEnabled,
                              onChanged: (v) => _save(config.copyWith(ocrEnabled: v)),
                            ),
                            showArrow: false,
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          _SettingRow(
                            title: 'OCR 模型',
                            value: ocrModelLabel,
                            onTap: () => _pickOcrModel(context, config),
                            enabled: config.ocrEnabled,
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          _SettingRow(
                            title: 'OCR 模型支持图片输入',
                            showArrow: false,
                            trailing: WeuiSwitch(
                              value: config.ocrModelSupportsImage,
                              onChanged: config.ocrEnabled
                                  ? (v) => _save(
                                        config.copyWith(ocrModelSupportsImage: v),
                                      )
                                  : null,
                              enabled: config.ocrEnabled,
                            ),
                            enabled: config.ocrEnabled,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: const Text(
                          '提示：\n'
                          '1) 若开启“图片输入”，图片会直接随消息发送给对话模型。\n'
                          '2) 若对话模型不支持图片且开启“OCR 回退”，将先用 OCR 模型做图片解析，再把解析结果作为文字发送给对话模型。',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
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

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    this.description,
    this.value,
    this.onTap,
    this.trailing,
    this.showArrow = true,
    this.enabled = true,
  });

  final String title;
  final String? description;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showArrow;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final clickable = enabled && onTap != null;
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: clickable
            ? () {
                HapticFeedback.selectionClick();
                onTap?.call();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textDisabled,
                      ),
                    ),
                    if (description != null && description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 10),
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          enabled ? AppColors.textSecondary : AppColors.textDisabled,
                    ),
                  ),
                ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (showArrow) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: enabled ? AppColors.textHint : AppColors.textDisabled,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

