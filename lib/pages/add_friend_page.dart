import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
  String _selectedAvatar = 'assets/avatar-default.jpeg';
  bool _isLoading = false;
  
  // 预设头像列表
  final List<String> _presetAvatars = [
    'assets/avatar-default.jpeg',
    'assets/avatar.png',
    'assets/me.png',
    'assets/bella.jpeg',
    'assets/group-chat.jpg',
  ];
  
  String? _customAvatarPath;
  
  bool get _isEdit => widget.editFriend != null;
  
  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameController.text = widget.editFriend!.name;
      _promptController.text = widget.editFriend!.prompt;
      _selectedAvatar = widget.editFriend!.avatar;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }
  
  Future<void> _pickCustomAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() {
        _customAvatarPath = file.path;
        _selectedAvatar = file.path;
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
        avatar: _selectedAvatar,
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
            
            const SizedBox(height: 24),
            
            // 名称输入
            _buildInputSection(
              title: '好友名称',
              child: _buildTextField(
                controller: _nameController,
                hintText: '给好友起个名字',
                maxLength: 20,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 提示词输入
            _buildInputSection(
              title: '人设提示词',
              subtitle: '定义好友的性格、说话风格等（可选）',
              child: _buildTextField(
                controller: _promptController,
                hintText: '例如：活泼开朗的大学生，喜欢动漫和游戏',
                maxLines: 4,
                maxLength: 500,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 提示词示例
            _buildPromptExamples(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvatarSection() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择头像',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 当前选中的头像
              GestureDetector(
                onTap: _pickCustomAvatar,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _customAvatarPath != null || !_selectedAvatar.startsWith('assets/')
                        ? Image.asset(
                            _selectedAvatar.startsWith('assets/') 
                                ? _selectedAvatar 
                                : 'assets/avatar-default.jpeg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.background,
                              child: const Icon(Icons.person, size: 36),
                            ),
                          )
                        : Image.asset(
                            _selectedAvatar,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 预设头像列表
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetAvatars.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      if (index == _presetAvatars.length) {
                        // 添加自定义头像按钮
                        return GestureDetector(
                          onTap: _pickCustomAvatar,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      
                      final avatar = _presetAvatars[index];
                      final isSelected = _selectedAvatar == avatar;
                      
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedAvatar = avatar;
                            _customAvatarPath = null;
                          });
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected 
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(isSelected ? 6 : 8),
                            child: Image.asset(
                              avatar,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
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
    );
  }
  
  Widget _buildPromptExamples() {
    final examples = [
      '温柔体贴的姐姐，说话很温和',
      '毒舌但关心人的损友',
      '二次元宅，经常用日语词',
      '学霸，喜欢讲道理',
      '话少内向，但很真诚',
    ];
    
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '提示词示例',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: examples.map((example) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _promptController.text = example;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    example,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

