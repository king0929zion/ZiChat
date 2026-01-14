import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/storage/chat_background_storage.dart';
import 'package:zichat/utils/cupertino_toast.dart';

/// 聊天背景选择页面
class ChatBackgroundPage extends StatefulWidget {
  const ChatBackgroundPage({super.key, required this.chatId});

  final String chatId;

  @override
  State<ChatBackgroundPage> createState() => _ChatBackgroundPageState();
}

class _ChatBackgroundPageState extends State<ChatBackgroundPage> {
  String? _currentBackground;
  bool _isLoading = false;

  // 预设背景色
  final List<Color> _presetColors = [
    const Color(0xFFEDEDED), // 默认灰色
    const Color(0xFFE8F5E9), // 浅绿
    const Color(0xFFE3F2FD), // 浅蓝
    const Color(0xFFFCE4EC), // 浅粉
    const Color(0xFFFFF3E0), // 浅橙
    const Color(0xFFF3E5F5), // 浅紫
    const Color(0xFFE0F7FA), // 浅青
    const Color(0xFFFFFDE7), // 浅黄
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentBackground();
  }

  void _loadCurrentBackground() {
    _currentBackground = ChatBackgroundStorage.getBackground(widget.chatId);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _isLoading = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'bg_${widget.chatId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      final savedPath = '${dir.path}/$fileName';
      await File(file.path).copy(savedPath);

      await ChatBackgroundStorage.setBackground(widget.chatId, savedPath);

      setState(() {
        _currentBackground = savedPath;
        _isLoading = false;
      });

      if (mounted) {
        CupertinoToast.show(context, '背景已更新');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        CupertinoToast.show(context, '设置失败: $e');
      }
    }
  }

  Future<void> _setColorBackground(Color color) async {
    HapticFeedback.selectionClick();
    // 使用颜色值作为背景标识
    final colorString = 'color:${color.toARGB32()}';
    await ChatBackgroundStorage.setBackground(widget.chatId, colorString);
    setState(() {
      _currentBackground = colorString;
    });
  }

  Future<void> _clearBackground() async {
    await ChatBackgroundStorage.clearBackground(widget.chatId);
    setState(() {
      _currentBackground = null;
    });
    if (mounted) {
      CupertinoToast.show(context, '已恢复默认背景');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '设置聊天背景',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 当前背景预览
                _buildPreviewSection(),
                const SizedBox(height: 24),

                // 从相册选择
                _buildSectionTitle('从相册选择'),
                const SizedBox(height: 12),
                _buildPickImageButton(),
                const SizedBox(height: 24),

                // 预设颜色
                _buildSectionTitle('纯色背景'),
                const SizedBox(height: 12),
                _buildColorGrid(),
                const SizedBox(height: 24),

                // 清除背景
                if (_currentBackground != null) ...[
                  _buildClearButton(),
                ],
              ],
            ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        image: _currentBackground != null && !_currentBackground!.startsWith('color:')
            ? DecorationImage(
                image: FileImage(File(_currentBackground!)),
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '预览效果',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (_currentBackground == null) {
      return const Color(0xFFEDEDED);
    }
    if (_currentBackground!.startsWith('color:')) {
      final colorValue = int.tryParse(_currentBackground!.substring(6));
      if (colorValue != null) {
        return Color(colorValue);
      }
    }
    return const Color(0xFFEDEDED);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPickImageButton() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.photo_library, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                '从相册选择图片',
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildColorGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _presetColors.map((color) {
        final isSelected = _currentBackground == 'color:${color.toARGB32()}';
        return GestureDetector(
          onTap: () => _setColorBackground(color),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 3)
                  : Border.all(color: AppColors.border),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: AppColors.primary, size: 24)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClearButton() {
    return TextButton(
      onPressed: _clearBackground,
      child: const Text(
        '恢复默认背景',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

