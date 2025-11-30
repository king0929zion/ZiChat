import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/storage/ai_config_storage.dart';

/// AI 提示词配置页面 - 微信风格
class AiContactPromptPage extends StatefulWidget {
  const AiContactPromptPage({
    super.key, 
    required this.chatId, 
    required this.title,
  });

  final String chatId;
  final String title;

  @override
  State<AiContactPromptPage> createState() => _AiContactPromptPageState();
}

class _AiContactPromptPageState extends State<AiContactPromptPage> {
  final TextEditingController _promptController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _hasChanges = false;

  // 预设的提示词模板
  final List<_PromptTemplate> _templates = const [
    _PromptTemplate(
      title: '温柔体贴',
      icon: Icons.favorite_outline,
      prompt: '说话温柔体贴，像个知心姐姐，善于倾听和安慰',
    ),
    _PromptTemplate(
      title: '毒舌损友',
      icon: Icons.sentiment_very_satisfied_outlined,
      prompt: '说话毒舌但不伤人，喜欢吐槽和调侃，其实很关心对方',
    ),
    _PromptTemplate(
      title: '二次元宅',
      icon: Icons.auto_awesome_outlined,
      prompt: '喜欢动漫和游戏，经常用日语词和二次元梗',
    ),
    _PromptTemplate(
      title: '话少内向',
      icon: Icons.psychology_outlined,
      prompt: '话不多但很真诚，回复简短但有内容，不喜欢废话',
    ),
    _PromptTemplate(
      title: '阳光活泼',
      icon: Icons.wb_sunny_outlined,
      prompt: '性格开朗活泼，说话热情，喜欢用语气词和表情',
    ),
    _PromptTemplate(
      title: '高冷学霸',
      icon: Icons.school_outlined,
      prompt: '知识渊博，说话有条理，偶尔会科普但不说教',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _promptController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _load() async {
    final prompt = await AiConfigStorage.loadContactPrompt(widget.chatId);
    if (!mounted) return;
    _promptController.text = prompt ?? '';
    setState(() {
      _loading = false;
      _hasChanges = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    
    setState(() => _saving = true);
    
    try {
      await AiConfigStorage.saveContactPrompt(widget.chatId, _promptController.text);
      if (!mounted) return;
      
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已保存'),
          duration: Duration(seconds: 1),
        ),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _applyTemplate(_PromptTemplate template) {
    HapticFeedback.selectionClick();
    
    final currentText = _promptController.text.trim();
    if (currentText.isEmpty) {
      _promptController.text = template.prompt;
    } else {
      // 追加到现有内容
      _promptController.text = '$currentText\n${template.prompt}';
    }
    
    // 移动光标到末尾
    _promptController.selection = TextSelection.fromPosition(
      TextPosition(offset: _promptController.text.length),
    );
  }

  @override
  void dispose() {
    _promptController.removeListener(_onTextChanged);
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            color: AppColors.background,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 52,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: SvgPicture.asset(
              'assets/icon/common/go-back.svg',
              width: 12,
              height: 20,
            ),
          ),
          // 标题
          Expanded(
            child: Center(
              child: Text(
                'AI 人设',
                style: AppStyles.titleLarge,
              ),
            ),
          ),
          // 保存按钮
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '完成',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _hasChanges ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          
          // 说明文字
          _buildSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.psychology_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '自定义 AI 人设',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '定义 AI 跟你聊天时的性格和风格',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 快捷模板
          _buildSection(
            title: '快捷人设',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _templates.map((template) {
                return _TemplateChip(
                  template: template,
                  onTap: () => _applyTemplate(template),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 提示词输入
          _buildSection(
            title: '人设描述',
            subtitle: '描述你希望 AI 有什么样的性格、说话风格',
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _promptController,
                maxLines: 6,
                maxLength: 500,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: '例如：\n- 说话温柔，像知心姐姐\n- 喜欢用"嗯嗯""好哒"等语气词\n- 偶尔会撒娇',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                    height: 1.5,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.all(12),
                  counterStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 提示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    '人设会影响 AI 的说话风格，但不会改变基本性格',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection({
    String? title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// 提示词模板
class _PromptTemplate {
  final String title;
  final IconData icon;
  final String prompt;

  const _PromptTemplate({
    required this.title,
    required this.icon,
    required this.prompt,
  });
}

/// 模板标签
class _TemplateChip extends StatefulWidget {
  const _TemplateChip({
    required this.template,
    required this.onTap,
  });

  final _PromptTemplate template;
  final VoidCallback onTap;

  @override
  State<_TemplateChip> createState() => _TemplateChipState();
}

class _TemplateChipState extends State<_TemplateChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppStyles.animationFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _pressed 
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pressed ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.template.icon,
              size: 16,
              color: _pressed ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              widget.template.title,
              style: TextStyle(
                fontSize: 13,
                color: _pressed ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
