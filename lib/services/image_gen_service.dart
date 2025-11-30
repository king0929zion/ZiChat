import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zichat/config/api_secrets.dart';
import 'package:zichat/config/ai_models.dart';

/// 图像生成服务
/// 
/// 使用 ModelScope API (OpenAI兼容格式) 生成图片
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
      // 使用 OpenAI 兼容的 images/generations 接口
      final url = '${ApiSecrets.imageBaseUrl}/images/generations';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${ApiSecrets.imageApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': useModel.id,
          'prompt': prompt,
          'size': '1024x1024',
          'n': 1,
          'response_format': 'b64_json',
        }),
      ).timeout(const Duration(seconds: 120));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // OpenAI 兼容格式返回
        if (data['data'] != null && (data['data'] as List).isNotEmpty) {
          final result = data['data'][0];
          if (result['b64_json'] != null) {
            return result['b64_json'];
          } else if (result['url'] != null) {
            return await _downloadAndEncode(result['url']);
          }
        }
        
        throw Exception('生成结果格式异常');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? '生成失败: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  /// 下载图片并转为 base64
  static Future<String> _downloadAndEncode(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return base64Encode(response.bodyBytes);
    }
    throw Exception('下载图片失败');
  }
  
  /// 检查服务是否可用
  static bool get isAvailable => ApiSecrets.hasBuiltInImageApi;
}

