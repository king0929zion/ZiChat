import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:zichat/config/api_secrets.dart';
import 'package:zichat/config/ai_models.dart';

/// 图像生成服务
/// 
/// 使用 ModelScope API 异步模式生成图片
class ImageGenService {
  /// 生成图片
  /// 
  /// [prompt] 图片描述
  /// [model] 使用的模型，默认使用内置模型
  /// 
  /// 返回图片的 base64 编码，如果失败返回 null
  static Future<String?> generateImage({
    required String prompt,
    ImageModel? model,
  }) async {
    final useModel = model ?? AiModels.defaultImageModel;
    
    // 检查 API Key
    if (!ApiSecrets.hasBuiltInImageApi) {
      throw Exception('图像生成 API 未配置');
    }
    
    try {
      // Step 1: 发起异步生成请求
      final taskId = await _createTask(prompt, useModel.id);
      debugPrint('Image generation task created: $taskId');
      
      // Step 2: 轮询等待结果
      final imageUrl = await _waitForResult(taskId);
      debugPrint('Image generated: $imageUrl');
      
      // Step 3: 下载图片并转为 base64
      return await _downloadAndEncode(imageUrl);
    } catch (e) {
      debugPrint('Image generation error: $e');
      rethrow;
    }
  }
  
  /// 创建异步任务
  static Future<String> _createTask(String prompt, String modelId) async {
    final url = '${ApiSecrets.imageBaseUrl}/images/generations';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${ApiSecrets.imageApiKey}',
        'Content-Type': 'application/json',
        'X-ModelScope-Async-Mode': 'true',
      },
      body: jsonEncode({
        'model': modelId,
        'prompt': prompt,
      }),
    ).timeout(const Duration(seconds: 30));
    
    debugPrint('Create task response: ${response.statusCode} ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 202) {
      final data = jsonDecode(response.body);
      final taskId = data['task_id'] as String?;
      if (taskId == null || taskId.isEmpty) {
        throw Exception('未返回 task_id');
      }
      return taskId;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error']?['message'] ?? '创建任务失败: ${response.statusCode}');
    }
  }
  
  /// 轮询等待任务完成
  static Future<String> _waitForResult(String taskId) async {
    final url = '${ApiSecrets.imageBaseUrl}/tasks/$taskId';
    
    const maxAttempts = 60; // 最多等待 5 分钟 (60 * 5秒)
    
    for (int i = 0; i < maxAttempts; i++) {
      // 等待 5 秒后查询
      await Future.delayed(const Duration(seconds: 5));
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${ApiSecrets.imageApiKey}',
          'X-ModelScope-Task-Type': 'image_generation',
        },
      ).timeout(const Duration(seconds: 30));
      
      debugPrint('Task status response: ${response.statusCode} ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['task_status'] as String?;
        
        if (status == 'SUCCEED') {
          // 获取图片 URL
          final outputImages = data['output_images'] as List?;
          if (outputImages != null && outputImages.isNotEmpty) {
            return outputImages[0] as String;
          }
          throw Exception('生成成功但未返回图片');
        } else if (status == 'FAILED') {
          throw Exception('图片生成失败');
        }
        
        // 继续等待 (PENDING, RUNNING 等状态)
        debugPrint('Task status: $status, waiting...');
      } else {
        throw Exception('查询任务状态失败: ${response.statusCode}');
      }
    }
    
    throw Exception('图片生成超时');
  }
  
  /// 下载图片并转为 base64
  static Future<String> _downloadAndEncode(String url) async {
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 60),
    );
    
    if (response.statusCode == 200) {
      return base64Encode(response.bodyBytes);
    }
    throw Exception('下载图片失败: ${response.statusCode}');
  }
  
  /// 检查服务是否可用
  static bool get isAvailable => ApiSecrets.hasBuiltInImageApi;
}
