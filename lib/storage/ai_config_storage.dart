import 'package:hive/hive.dart';

/// 全局 AI 配置（OpenAI / Gemini 等）
class AiGlobalConfig {
  AiGlobalConfig({
    required this.provider, // 'openai' 或 'gemini'
    required this.apiBaseUrl,
    required this.apiKey,
    required this.model,
    required this.persona,
  });

  final String provider;
  final String apiBaseUrl;
  final String apiKey;
  final String model;
  final String persona;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'provider': provider,
      'apiBaseUrl': apiBaseUrl,
      'apiKey': apiKey,
      'model': model,
      'persona': persona,
    };
  }

  static AiGlobalConfig? fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return null;
    return AiGlobalConfig(
      provider: (map['provider'] ?? 'openai').toString(),
      apiBaseUrl: (map['apiBaseUrl'] ?? '').toString(),
      apiKey: (map['apiKey'] ?? '').toString(),
      model: (map['model'] ?? '').toString(),
      persona: (map['persona'] ?? '').toString(),
    );
  }
}

/// 基础模型配置（默认对话 / OCR / 生图）
class AiBaseModelsConfig {
  const AiBaseModelsConfig({
    this.chatConfigId,
    this.chatModel,
    this.chatModelSupportsImage = false,
    this.ocrConfigId,
    this.ocrModel,
    this.ocrEnabled = false,
    this.ocrModelSupportsImage = true,
    this.imageGenConfigId,
    this.imageGenModel,
  });

  final String? chatConfigId;
  final String? chatModel;
  final bool chatModelSupportsImage;

  final String? ocrConfigId;
  final String? ocrModel;
  final bool ocrEnabled;
  final bool ocrModelSupportsImage;

  final String? imageGenConfigId;
  final String? imageGenModel;

  AiBaseModelsConfig copyWith({
    Object? chatConfigId = _unset,
    Object? chatModel = _unset,
    bool? chatModelSupportsImage,
    Object? ocrConfigId = _unset,
    Object? ocrModel = _unset,
    bool? ocrEnabled,
    bool? ocrModelSupportsImage,
    Object? imageGenConfigId = _unset,
    Object? imageGenModel = _unset,
  }) {
    final nextChatConfigId =
        chatConfigId == _unset ? this.chatConfigId : chatConfigId as String?;
    final nextChatModel =
        chatModel == _unset ? this.chatModel : chatModel as String?;
    final nextOcrConfigId =
        ocrConfigId == _unset ? this.ocrConfigId : ocrConfigId as String?;
    final nextOcrModel = ocrModel == _unset ? this.ocrModel : ocrModel as String?;
    final nextImageGenConfigId = imageGenConfigId == _unset
        ? this.imageGenConfigId
        : imageGenConfigId as String?;
    final nextImageGenModel = imageGenModel == _unset
        ? this.imageGenModel
        : imageGenModel as String?;

    return AiBaseModelsConfig(
      chatConfigId: nextChatConfigId,
      chatModel: nextChatModel,
      chatModelSupportsImage:
          chatModelSupportsImage ?? this.chatModelSupportsImage,
      ocrConfigId: nextOcrConfigId,
      ocrModel: nextOcrModel,
      ocrEnabled: ocrEnabled ?? this.ocrEnabled,
      ocrModelSupportsImage: ocrModelSupportsImage ?? this.ocrModelSupportsImage,
      imageGenConfigId: nextImageGenConfigId,
      imageGenModel: nextImageGenModel,
    );
  }

  static const Object _unset = Object();

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'chatConfigId': chatConfigId,
      'chatModel': chatModel,
      'chatModelSupportsImage': chatModelSupportsImage,
      'ocrConfigId': ocrConfigId,
      'ocrModel': ocrModel,
      'ocrEnabled': ocrEnabled,
      'ocrModelSupportsImage': ocrModelSupportsImage,
      'imageGenConfigId': imageGenConfigId,
      'imageGenModel': imageGenModel,
    };
  }

  static AiBaseModelsConfig? fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return null;
    return AiBaseModelsConfig(
      chatConfigId: map['chatConfigId']?.toString(),
      chatModel: map['chatModel']?.toString(),
      chatModelSupportsImage: map['chatModelSupportsImage'] as bool? ?? false,
      ocrConfigId: map['ocrConfigId']?.toString(),
      ocrModel: map['ocrModel']?.toString(),
      ocrEnabled: map['ocrEnabled'] as bool? ?? false,
      ocrModelSupportsImage: map['ocrModelSupportsImage'] as bool? ?? true,
      imageGenConfigId: map['imageGenConfigId']?.toString(),
      imageGenModel: map['imageGenModel']?.toString(),
    );
  }

  bool get hasChatModel =>
      (chatConfigId ?? '').trim().isNotEmpty && (chatModel ?? '').trim().isNotEmpty;

  bool get hasOcrModel =>
      (ocrConfigId ?? '').trim().isNotEmpty && (ocrModel ?? '').trim().isNotEmpty;

  bool get hasImageGenModel =>
      (imageGenConfigId ?? '').trim().isNotEmpty &&
      (imageGenModel ?? '').trim().isNotEmpty;
}

/// 负责存储 / 读取 AI 相关配置
class AiConfigStorage {
  static const String boxName = 'ai_config';
  static const String _globalKey = 'global';
  static const String _baseModelsKey = 'base_models';
  static const String _contactPrefix = 'contact:';

  static Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  /// 读取全局配置
  static Future<AiGlobalConfig?> loadGlobalConfig() async {
    final dynamic raw = _box.get(_globalKey);
    if (raw is Map) {
      return AiGlobalConfig.fromMap(raw);
    }
    return null;
  }

  /// 保存全局配置
  static Future<void> saveGlobalConfig(AiGlobalConfig config) async {
    await _box.put(_globalKey, config.toMap());
  }

  /// 读取基础模型配置
  static Future<AiBaseModelsConfig?> loadBaseModelsConfig() async {
    final dynamic raw = _box.get(_baseModelsKey);
    if (raw is Map) {
      return AiBaseModelsConfig.fromMap(raw);
    }
    return null;
  }

  /// 保存基础模型配置
  static Future<void> saveBaseModelsConfig(AiBaseModelsConfig config) async {
    await _box.put(_baseModelsKey, config.toMap());
  }

  /// 读取单个会话的系统提示词
  static Future<String?> loadContactPrompt(String chatId) async {
    final dynamic raw = _box.get('$_contactPrefix$chatId');
    if (raw == null) return null;
    return raw.toString();
  }

  /// 保存单个会话的系统提示词
  static Future<void> saveContactPrompt(String chatId, String prompt) async {
    await _box.put('$_contactPrefix$chatId', prompt);
  }
}
