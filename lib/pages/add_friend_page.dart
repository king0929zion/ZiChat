import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/models/friend.dart';
import 'package:zichat/storage/friend_storage.dart';

/// 添加好友页面
class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key, this.editFriend});
  
  /// 如果传入则为编辑模式
  final Friend? editFriend;
  
  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final _nameController = TextEditingController();
  final _promptController = TextEditingController();
  String? _avatarPath;
  bool _isLoading = false;
  
  bool get _isEdit => widget.editFriend != null;
  
  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameController.text = widget.editFriend!.name;
      _promptController.text = widget.editFriend!.prompt;
      if (!widget.editFriend!.avatar.startsWith('assets/')) {
        _avatarPath = widget.editFriend!.avatar;
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }
  
  Future<void> _pickAvatar() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 85,
    );
    if (file != null) {
      // 保存到应用目录
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      final savedPath = '${dir.path}/$fileName';
      await File(file.path).copy(savedPath);
      
      setState(() {
        _avatarPath = savedPath;
      });
    }
  }
  
  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入好友名称')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final friend = Friend(
        id: _isEdit ? widget.editFriend!.id : 'friend_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        avatar: _avatarPath ?? 'assets/avatar-default.jpeg',
        prompt: _promptController.text.trim(),
        createdAt: _isEdit ? widget.editFriend!.createdAt : DateTime.now(),
        unread: _isEdit ? widget.editFriend!.unread : 0,
        lastMessage: _isEdit ? widget.editFriend!.lastMessage : null,
        lastMessageTime: _isEdit ? widget.editFriend!.lastMessageTime : null,
      );
      
      await FriendStorage.saveFriend(friend);
      
      if (mounted) {
        Navigator.of(context).pop(friend);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEdit ? '编辑好友' : '添加好友',
          style: AppStyles.titleLarge,
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: Text(
              '完成',
              style: TextStyle(
                color: _isLoading ? AppColors.textSecondary : AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // 头像选择
            _buildAvatarSection(),
            
            const SizedBox(height: 12),
            
            // 名称输入
            _buildInputSection(
              title: '好友名称',
              child: TextField(
                controller: _nameController,
                maxLength: 20,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '给好友起个名字',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  counterStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 提示词输入
            _buildInputSection(
              title: '人设提示词',
              subtitle: '定义好友的性格、说话风格等（可选）',
              child: TextField(
                controller: _promptController,
                maxLines: 5,
                maxLength: 500,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '例如：活泼开朗的大学生，喜欢动漫和游戏，说话很随意',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  counterStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvatarSection() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 头像
          GestureDetector(
            onTap: _pickAvatar,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _avatarPath != null
                    ? Image.file(
                        File(_avatarPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                      )
                    : _buildDefaultAvatar(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 提示文字
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '头像',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _avatarPath != null ? '点击头像更换' : '点击从相册选择',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 箭头
          const Icon(
            Icons.chevron_right,
            color: AppColors.textHint,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDefaultAvatar() {
    return Image.asset(
      'assets/avatar-default.jpeg',
      fit: BoxFit.cover,
    );
  }
  
  Widget _buildInputSection({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
