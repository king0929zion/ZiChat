/// API 密钥配置
class ApiSecrets {
  // 对话 API (iflow)
  static const String chatApiKey = 'sk-46ecb698fa0a80811a463cf78149fc9c';
  static const String chatBaseUrl = 'https://apis.iflow.cn/v1';
  
  // 图像生成 API (ModelScope)
  static const String imageApiKey = 'ms-a2995d2b-3843-456a-83fc-3c813e696b08';
  static const String imageBaseUrl = 'https://api-inference.modelscope.cn/v1';
  
  /// 检查是否配置了内置 API
  static bool get hasBuiltInChatApi => chatApiKey.isNotEmpty;
  static bool get hasBuiltInImageApi => imageApiKey.isNotEmpty;
}

