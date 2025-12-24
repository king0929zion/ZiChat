/// API 密钥配置
/// 注意：此文件不再包含内置 API 密钥
/// 用户需要通过"设置 > API 管理"添加自己的 API 配置
class ApiSecrets {
  /// 已弃用 - 不再使用内置 API
  /// 请使用 ApiConfigStorage 管理用户自定义 API
  @Deprecated('Use ApiConfigStorage instead')
  static const String chatApiKey = '';

  @Deprecated('Use ApiConfigStorage instead')
  static const String chatBaseUrl = '';

  @Deprecated('Use ApiConfigStorage instead')
  static const String imageApiKey = '';

  @Deprecated('Use ApiConfigStorage instead')
  static const String imageBaseUrl = '';

  /// 检查是否配置了内置 API（始终返回 false）
  @Deprecated('Use ApiConfigStorage.hasConfig() instead')
  static bool get hasBuiltInChatApi => false;

  @Deprecated('Use ApiConfigStorage.hasConfig() instead')
  static bool get hasBuiltInImageApi => false;
}


