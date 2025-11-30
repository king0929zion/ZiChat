/// API 密钥配置
/// 
/// 这些值在编译时通过 --dart-define 注入
/// 本地开发时可以创建 .env 文件或直接修改这里的默认值
/// 
/// GitHub Actions 会自动从 Secrets 中读取并注入
class ApiSecrets {
  // 对话 API (iflow) - 内置URL，只需配置API Key
  static const String chatApiKey = String.fromEnvironment(
    'CHAT_API_KEY',
    defaultValue: '',
  );
  
  // 固定的对话API地址
  static const String chatBaseUrl = 'https://apis.iflow.cn/v1';
  
  // 图像生成 API (ModelScope) - 内置URL，只需配置API Key
  static const String imageApiKey = String.fromEnvironment(
    'IMAGE_API_KEY',
    defaultValue: '',
  );
  
  // 固定的图像生成API地址
  static const String imageBaseUrl = 'https://api-inference.modelscope.cn/v1';
  
  /// 检查是否配置了内置 API
  static bool get hasBuiltInChatApi => chatApiKey.isNotEmpty;
  static bool get hasBuiltInImageApi => imageApiKey.isNotEmpty;
}

