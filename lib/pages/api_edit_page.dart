import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
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
  bool _saving = false;
  bool _detecting = false;
  List<String> _detectedModels = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.editConfig != null;
    if (_isEdit) {
      _nameController.text = widget.editConfig!.name;
      _baseUrlController.text = widget.editConfig!.baseUrl;
      _apiKeyController.text = widget.editConfig!.apiKey;
      _detectedModels = widget.editConfig!.models;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _detectModels() async {
    final baseUrl = _baseUrlController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (baseUrl.isEmpty || apiKey.isEmpty) {
      setState(() {
        _error = '请先填写 API 地址和密钥';
      });
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _detecting = true;
      _error = null;
    });

    try {
      final models = await ModelDetectorService.detectModels(
        baseUrl: baseUrl,
        apiKey: apiKey,
      );
      if (mounted) {
        setState(() {
          _detectedModels = models;
          _detecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('检测到 ${models.length} 个可用模型')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detecting = false;
          _error = e.toString();
        });
      }
    }
  }

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

    HapticFeedback.mediumImpact();

    final config = ApiConfig(
      id: widget.editConfig?.id ?? const Uuid().v4(),
      name: name,
      baseUrl: baseUrl,
      apiKey: apiKey,
      models: _detectedModels,
      isActive: !_isEdit, // 新添加的默认激活
      createdAt: widget.editConfig?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: SvgPicture.asset(
            'assets/icon/common/go-back.svg',
            width: 12,
            height: 20,
          ),
        ),
        title: Text(
          _isEdit ? '编辑 API' : '添加 API',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D2129),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF07C160),
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildInputCard(
            label: '名称',
            hint: '例如: OpenAI、DeepSeek',
            controller: _nameController,
          ),
          const SizedBox(height: 8),
          _buildInputCard(
            label: 'API 地址',
            hint: 'https://api.openai.com/v1',
            controller: _baseUrlController,
          ),
          const SizedBox(height: 8),
          _buildInputCard(
            label: 'API 密钥',
            hint: 'sk-...',
            controller: _apiKeyController,
            obscureText: true,
          ),
          const SizedBox(height: 8),
          _buildDetectCard(),
          if (_detectedModels.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildModelsCard(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            _buildErrorCard(),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF4E5969),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFFB8C0CC),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E6EB), width: 0.8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E6EB), width: 0.8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF07C160), width: 1),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '可用模型',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF4E5969),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _detecting ? null : _detectModels,
            icon: _detecting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(_detecting ? '检测中...' : '检测可用模型'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF07C160),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击按钮自动检测该 API 支持的模型列表',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFB8C0CC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelsCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '已检测模型',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF4E5969),
                ),
              ),
              Text(
                '${_detectedModels.length} 个',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF07C160),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _detectedModels.map((model) {
              return Chip(
                label: Text(
                  model,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: const Color(0xFF07C160).withOpacity(0.1),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _detectedModels.remove(model);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(8),
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
    );
  }
}
