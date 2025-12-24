import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/models/api_config.dart';
import 'package:zichat/services/model_detector_service.dart';

/// API 添加/编辑页面
class ApiEditPage extends StatefulWidget {
  const ApiEditPage({super.key, this.editConfig});

  final ApiConfig? editConfig;

  @override
  State<ApiEditPage> createState() => _ApiEditPageState();
}

class _ApiEditPageState extends State<ApiEditPage> {
  final _nameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _isEdit = false;
  bool _detecting = false;
  final _customModelController = TextEditingController();
  List<String> _detectedModels = [];
  String? _selectedModel;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.editConfig != null;
    if (_isEdit) {
      _nameController.text = widget.editConfig!.name;
      _baseUrlController.text = widget.editConfig!.baseUrl;
      _apiKeyController.text = widget.editConfig!.apiKey;
      _detectedModels = List.from(widget.editConfig!.models);
      _selectedModel = widget.editConfig!.selectedModel;
      
      // If selected model is not in list (legacy or removed), default to first
      if (_detectedModels.isNotEmpty && (_selectedModel == null || !_detectedModels.contains(_selectedModel))) {
          _selectedModel = _detectedModels.first;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

// ... _detectModels stays same ...

  void _save() {
    final name = _nameController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (name.isEmpty || baseUrl.isEmpty || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整信息')),
      );
      return;
    }

    if (_detectedModels.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一个模型')),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    // Default to first if none selected
    final finalSelectedModel = _selectedModel ?? _detectedModels.first;

    final config = ApiConfig(
      id: widget.editConfig?.id ?? const Uuid().v4(),
      name: name,
      baseUrl: baseUrl,
      apiKey: apiKey,
      models: _detectedModels,
      isActive: !_isEdit, // 新建默认激活，编辑不改变
      selectedModel: finalSelectedModel,
      createdAt: widget.editConfig?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(config);
  }

// ... build ... section ...

  Widget _buildModelsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('模型列表', style: AppStyles.bodyMedium),
                  Text(
                    '${_detectedModels.length} 个',
                    style: AppStyles.caption.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '点击选择默认对话模型',
                style: AppStyles.caption.copyWith(fontSize: 11),
              ),
            ),
            
            // 手动添加模型输入框
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               child: Row(
                 children: [
                   Expanded(
                     child: SizedBox(
                       height: 36,
                       child: TextField(
                         controller: _customModelController,
                         style: const TextStyle(fontSize: 13),
                         decoration: InputDecoration(
                           hintText: '手动添加模型 ID...',
                           hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                           filled: true,
                           fillColor: AppColors.background,
                           border: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(4),
                             borderSide: BorderSide.none,
                           ),
                         ),
                       ),
                     ),
                   ),
                   const SizedBox(width: 8),
                   IconButton(
                     onPressed: _addCustomModel,
                     icon: const Icon(Icons.add_circle, color: AppColors.primary),
                     padding: EdgeInsets.zero,
                     constraints: const BoxConstraints(),
                   ),
                 ],
               ),
            ),

            if (_detectedModels.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _detectedModels.map((model) {
                    final isSelected = model == _selectedModel;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedModel = model;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                         decoration: BoxDecoration(
                           color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(
                             color: isSelected ? AppColors.primary : Colors.transparent, 
                           ),
                         ),
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Text(
                               model,
                               style: TextStyle(
                                 fontSize: 12,
                                 color: isSelected ? Colors.white : AppColors.textPrimary,
                               ),
                             ),
                             const SizedBox(width: 4),
                             InkWell(
                               onTap: () {
                                 setState(() {
                                   _detectedModels.remove(model);
                                   if (_selectedModel == model) {
                                     _selectedModel = _detectedModels.isNotEmpty ? _detectedModels.first : null;
                                   }
                                 });
                               },
                               child: Icon(
                                 Icons.close, 
                                 size: 14, 
                                 color: isSelected ? Colors.white70 : AppColors.textHint,
                               ),
                             ),
                           ],
                         ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _addCustomModel() {
    final model = _customModelController.text.trim();
    if (model.isNotEmpty && !_detectedModels.contains(model)) {
      setState(() {
        _detectedModels.add(model);
        _customModelController.clear();
        // If it's the first model, auto select it
        if (_detectedModels.length == 1) {
          _selectedModel = model;
        }
      });
    }
  }

  Widget _buildErrorCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          border: Border.all(color: const Color(0xFFFFE0E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputTile extends StatefulWidget {
  const _InputTile({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.obscureText = false,
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool obscureText;

  @override
  State<_InputTile> createState() => _InputTileState();
}

class _InputTileState extends State<_InputTile> {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Text(widget.label, style: AppStyles.bodyMedium),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: widget.controller,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: AppStyles.hint,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: AppColors.textHint,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 0, 14, 0),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ],
    );
  }
}
