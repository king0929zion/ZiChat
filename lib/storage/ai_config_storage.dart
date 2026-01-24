import 'package:hive/hive.dart';

/// 基础模型配置（对话 / 视觉 / 生图）
class AiBaseModelsConfig {
  const AiBaseModelsConfig({
    this.chatConfigId,
    this.chatModel,
    this.chatModelSupportsImage = false,
    this.visionConfigId,
    this.visionModel,
    this.visionModelSupportsImage = true,
    this.imageGenConfigId,
    this.imageGenModel,
  });

  final String? chatConfigId;
  final String? chatModel;
  final bool chatModelSupportsImage;

  final String? visionConfigId;
  final String? visionModel;
  final bool visionModelSupportsImage;

  final String? imageGenConfigId;
  final String? imageGenModel;

  AiBaseModelsConfig copyWith({
    Object? chatConfigId = _unset,
    Object? chatModel = _unset,
    bool? chatModelSupportsImage,
    Object? visionConfigId = _unset,
    Object? visionModel = _unset,
    bool? visionModelSupportsImage,
    Object? imageGenConfigId = _unset,
    Object? imageGenModel = _unset,
  }) {
    final nextChatConfigId =
        chatConfigId == _unset ? this.chatConfigId : chatConfigId as String?;
    final nextChatModel =
        chatModel == _unset ? this.chatModel : chatModel as String?;
    final nextVisionConfigId = visionConfigId == _unset
        ? this.visionConfigId
        : visionConfigId as String?;
    final nextVisionModel =
        visionModel == _unset ? this.visionModel : visionModel as String?;
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
      visionConfigId: nextVisionConfigId,
      visionModel: nextVisionModel,
      visionModelSupportsImage:
          visionModelSupportsImage ?? this.visionModelSupportsImage,
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
      'visionConfigId': visionConfigId,
      'visionModel': visionModel,
      'visionModelSupportsImage': visionModelSupportsImage,
      'imageGenConfigId': imageGenConfigId,
      'imageGenModel': imageGenModel,
    };
  }

  static AiBaseModelsConfig? fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return null;

    // 兼容旧字段（ocr* -> vision*）
    final visionConfigId = map['visionConfigId']?.toString() ??
        map['ocrConfigId']?.toString();
    final visionModel =
        map['visionModel']?.toString() ?? map['ocrModel']?.toString();
    final visionModelSupportsImage = map['visionModelSupportsImage'] as bool? ??
        map['ocrModelSupportsImage'] as bool? ??
        true;

    return AiBaseModelsConfig(
      chatConfigId: map['chatConfigId']?.toString(),
      chatModel: map['chatModel']?.toString(),
      chatModelSupportsImage: map['chatModelSupportsImage'] as bool? ?? false,
      visionConfigId: visionConfigId,
      visionModel: visionModel,
      visionModelSupportsImage: visionModelSupportsImage,
      imageGenConfigId: map['imageGenConfigId']?.toString(),
      imageGenModel: map['imageGenModel']?.toString(),
    );
  }

  bool get hasChatModel =>
      (chatConfigId ?? '').trim().isNotEmpty && (chatModel ?? '').trim().isNotEmpty;

  bool get hasVisionModel =>
      (visionConfigId ?? '').trim().isNotEmpty && (visionModel ?? '').trim().isNotEmpty;

  bool get hasImageGenModel =>
      (imageGenConfigId ?? '').trim().isNotEmpty &&
      (imageGenModel ?? '').trim().isNotEmpty;
}

/// 负责存储 / 读取 AI 相关配置
class AiConfigStorage {
  static const String boxName = 'ai_config';
  static const String _baseModelsKey = 'base_models';
  static const String _contactPrefix = 'contact:';

  static Box<dynamic> get _box => Hive.box<dynamic>(boxName);

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
