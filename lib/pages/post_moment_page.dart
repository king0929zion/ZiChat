import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

class PostMomentPage extends StatefulWidget {
  const PostMomentPage({super.key});

  @override
  State<PostMomentPage> createState() => _PostMomentPageState();
}

class _PostMomentPageState extends State<PostMomentPage> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedImages = []; // 用户选择的图片路径
  static const int _maxImages = 9; // 最多9张图片

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= _maxImages) {
      _showSimpleSnackBar(context, '最多只能选择 $_maxImages 张图片');
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      setState(() {
        _selectedImages.add(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Widget _buildImageGrid() {
    // 如果没有图片，只显示添加按钮
    if (_selectedImages.isEmpty) {
      return SizedBox(
        height: 100,
        child: Row(
          children: [
            _AddMediaButton(onTap: _pickImage),
          ],
        ),
      );
    }

    // 有图片时显示网格
    final List<Widget> children = [];
    
    // 添加已选择的图片
    for (int i = 0; i < _selectedImages.length; i++) {
      children.add(
        _SelectedMediaItem(
          imagePath: _selectedImages[i],
          onRemove: () => _removeImage(i),
        ),
      );
    }
    
    // 如果还没有达到最大数量，添加"添加"按钮
    if (_selectedImages.length < _maxImages) {
      children.add(_AddMediaButton(onTap: _pickImage));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            color: Colors.white,
            child: Column(
              children: [
                // Header
                Container(
                  height: 44, // HTML: height: 44px
                  padding: const EdgeInsets.symmetric(horizontal: 10), // HTML: padding: 0 10px
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFF0F0F0), // HTML: border-bottom: 0.5px solid #f0f0f0
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(6), // HTML: padding: 6px
                        onPressed: () => Navigator.of(context).pop(),
                        icon: SvgPicture.asset(
                          'assets/icon/common/go-back.svg',
                          width: 12,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF1D2129),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(
                              _textController.text.trim(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF07C160),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: const Size(48, 28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            '发表',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Main Content
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        32,
                        16,
                        32,
                        24,
                      ),
                      children: [
                        // 文本输入框
                        TextField(
                          controller: _textController,
                          minLines: 3,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: '这一刻的想法...',
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: Color(0xFFBBBBBB),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 图片网格
                        _buildImageGrid(),
                        const SizedBox(height: 26),
                        // 选项列表
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFFF0F0F0),
                                width: 0.5,
                              ),
                              bottom: BorderSide(
                                color: Color(0xFFF0F0F0),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            children: const [
                              _OptionRow(
                                icon: 'assets/icon/discover/location.svg',
                                label: '所在位置',
                              ),
                              _OptionRow(
                                icon: 'assets/icon/discover/at.svg',
                                label: '提醒谁看',
                              ),
                              _OptionRow(
                                icon: 'assets/icon/discover/location.svg',
                                label: '谁可以看',
                                value: '公开',
                                isLast: true,
                              ),
                            ],
                          ),
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
    }
  }

class _AddMediaButton extends StatelessWidget {
  const _AddMediaButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            size: 40,
            color: Colors.black45,
          ),
        ),
      ),
    );
  }
}

/// 已选择的图片项（可删除）
class _SelectedMediaItem extends StatelessWidget {
  const _SelectedMediaItem({
    required this.imagePath,
    required this.onRemove,
  });

  final String imagePath;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 图片
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF0F0F0),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF8A8F99),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // 删除按钮
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 0, 0, 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    this.value,
    this.isLast = false,
  });

  final String icon;
  final String label;
  final String? value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _showSimpleSnackBar(context, '功能暂未开放');
      },
      child: Container(
        height: 48, // HTML: height: 48px
        padding: const EdgeInsets.symmetric(horizontal: 14), // HTML: padding: 0 14px
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: Color(0xFFF0F0F0), // HTML: border-bottom: 0.5px solid #f0f0f0
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: 18, // HTML: width: 18px
              height: 18, // HTML: height: 18px
            ),
            const SizedBox(width: 10), // HTML: gap: 10px
            Text(
              label,
              style: const TextStyle(
                fontSize: 15, // HTML: font-size: 15px
                color: Color(0xFF222222), // HTML: color: #222
              ),
            ),
            const Spacer(),
            if (value != null) ...[
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 14, // HTML: font-size: 14px
                  color: Color(0xFF8A8A8A), // HTML: color: #8a8a8a
                ),
              ),
              const SizedBox(width: 8), // HTML: margin-right: 8px
            ],
            SvgPicture.asset(
              'assets/icon/common/arrow-right.svg',
              width: 8,
              height: 14,
              colorFilter: const ColorFilter.mode(
                Color(0x66000000), // HTML: opacity: 0.4
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showSimpleSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
}
