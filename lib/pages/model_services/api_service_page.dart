import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/pages/model_services/model_service_widgets.dart';
import 'package:zichat/storage/api_config_storage.dart';

/// API 服务编辑页（按 WeUI 风格重写）
class ApiServicePage extends StatefulWidget {
  const ApiServicePage({super.key, this.configId});

  final String? configId;

  @override
  State<ApiServicePage> createState() => _ApiServicePageState();
}

class _ApiServicePageState extends State<ApiServicePage> {
  final _nameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();

  bool _showApiKey = false;
  bool _saving = false;
  String? _error;
  String? _copiedHint;

  ApiConfig? _original;

  bool get _isCreate => widget.configId == null;

  @override
  void initState() {
    super.initState();
    _load();
    _apiKeyController.addListener(_clearInlineHint);
    _baseUrlController.addListener(_clearInlineHint);
    _nameController.addListener(_clearInlineHint);
  }

  void _clearInlineHint() {
    if (!mounted) return;
    if (_error != null || _copiedHint != null) {
      setState(() {
        _error = null;
        _copiedHint = null;
      });
    }
  }

  void _load() {
    if (widget.configId == null) return;
    final config = ApiConfigStorage.getConfig(widget.configId!);
    if (config == null) return;
    _original = config;
    _nameController.text = config.name;
    _apiKeyController.text = config.apiKey;
    _baseUrlController.text = config.baseUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final nameOk = !_isCreate || _nameController.text.trim().isNotEmpty;
    return nameOk &&
        _apiKeyController.text.trim().isNotEmpty &&
        _baseUrlController.text.trim().isNotEmpty &&
        !_saving;
  }

  Future<void> _copyDocsLink() async {
    HapticFeedback.selectionClick();
    final url = _guessDocsUrl(
      name: _nameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
    );
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    setState(() => _copiedHint = '已复制链接');
  }

  String _guessDocsUrl({required String name, required String baseUrl}) {
    final n = name.toLowerCase();
    final b = baseUrl.toLowerCase();
    if (b.contains('openai.com') || n.contains('openai')) {
      return 'https://platform.openai.com/api-keys';
    }
    if (b.contains('siliconflow') || name.contains('硅基')) {
      return 'https://siliconflow.cn';
    }
    if (b.contains('dashscope') || n.contains('qwen') || name.contains('通义')) {
      return 'https://dashscope.console.aliyun.com/apiKey';
    }
    if (b.contains('anthropic') || n.contains('anthropic')) {
      return 'https://console.anthropic.com/settings/keys';
    }
    if (b.contains('google') || n.contains('gemini')) {
      return 'https://aistudio.google.com/app/apikey';
    }
    if (b.contains('ollama') || n.contains('ollama')) {
      return 'https://ollama.com';
    }
    return baseUrl.isNotEmpty ? baseUrl : 'https://weui.io/';
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    HapticFeedback.lightImpact();
    setState(() {
      _saving = true;
      _error = null;
      _copiedHint = null;
    });

    try {
      final name = _nameController.text.trim();
      final apiKey = _apiKeyController.text.trim();
      final baseUrl = _baseUrlController.text.trim();

      if (_isCreate && name.isEmpty) {
        setState(() => _error = '请输入厂商名称');
        return;
      }
      if (apiKey.isEmpty) {
        setState(() => _error = '请输入 API 密钥');
        return;
      }
      if (baseUrl.isEmpty) {
        setState(() => _error = '请输入 API 主机');
        return;
      }

      final config = (_original ?? ApiConfig(
            id: const Uuid().v4(),
            name: name,
            baseUrl: baseUrl,
            apiKey: apiKey,
            models: const [],
            isActive: false,
            selectedModel: null,
            temperature: 0.7,
            topP: 0.9,
            maxTokens: 4096,
            createdAt: DateTime.now(),
          ))
          .copyWith(
            name: name,
            apiKey: apiKey,
            baseUrl: baseUrl,
          );

      await ApiConfigStorage.saveConfig(config);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
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
          'API 服务',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _canSubmit ? _submit : null,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '完成',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          _canSubmit ? AppColors.primary : AppColors.textDisabled,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (_isCreate) ...[
                  const Text(
                    '厂商名称',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PillInput(
                    controller: _nameController,
                    hintText: '例如：硅基流动 / OpenAI',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 22),
                ],
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'API 密钥',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _PillInput(
                  controller: _apiKeyController,
                  hintText: '请输入 API 密钥',
                  obscureText: !_showApiKey,
                  textInputAction: TextInputAction.next,
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _showApiKey = !_showApiKey),
                    icon: Icon(
                      _showApiKey ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '多个密钥用逗号分隔',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _copyDocsLink,
                      child: const Text(
                        '获取 API 密钥',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.link,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_copiedHint != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _copiedHint!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const Text(
                  'API 主机',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _PillInput(
                  controller: _baseUrlController,
                  hintText: '例如：https://api.openai.com/v1',
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _InlineError(text: _error!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillInput extends StatelessWidget {
  const _PillInput({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                fontSize: 16,
                height: 1.2,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0E0), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline, color: Colors.red, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
