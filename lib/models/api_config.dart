/// API 配置模型
class ApiConfig {
  ApiConfig({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.models,
    this.isActive = false,
    this.selectedModel,
    this.chatModelSupportsImage = false,
    this.ocrEnabled = false,
    this.ocrModel,
    this.ocrModelSupportsImage = true,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.maxTokens = 4096,
    this.createdAt,
  });

  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final List<String> models;
  final bool isActive;
  final String? selectedModel;

  /// 对话模型是否支持图片输入（视觉模型）
  final bool chatModelSupportsImage;

  /// 是否启用 OCR 作为视觉回退（当对话模型不支持图片时）
  final bool ocrEnabled;

  /// OCR 使用的模型（可与对话模型不同）
  final String? ocrModel;

  /// OCR 模型是否支持图片输入（视觉模型）
  final bool ocrModelSupportsImage;
  final double temperature;
  final double topP;
  final int maxTokens;
  final DateTime? createdAt;

  ApiConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    List<String>? models,
    bool? isActive,
    String? selectedModel,
    bool? chatModelSupportsImage,
    bool? ocrEnabled,
    String? ocrModel,
    bool? ocrModelSupportsImage,
    double? temperature,
    double? topP,
    int? maxTokens,
    DateTime? createdAt,
  }) {
    return ApiConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      models: models ?? this.models,
      isActive: isActive ?? this.isActive,
      selectedModel: selectedModel ?? this.selectedModel,
      chatModelSupportsImage: chatModelSupportsImage ?? this.chatModelSupportsImage,
      ocrEnabled: ocrEnabled ?? this.ocrEnabled,
      ocrModel: ocrModel ?? this.ocrModel,
      ocrModelSupportsImage: ocrModelSupportsImage ?? this.ocrModelSupportsImage,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      maxTokens: maxTokens ?? this.maxTokens,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'models': models,
      'isActive': isActive,
      'selectedModel': selectedModel,
      'chatModelSupportsImage': chatModelSupportsImage,
      'ocrEnabled': ocrEnabled,
      'ocrModel': ocrModel,
      'ocrModelSupportsImage': ocrModelSupportsImage,
      'temperature': temperature,
      'topP': topP,
      'maxTokens': maxTokens,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static ApiConfig fromMap(Map<String, dynamic> map) {
    return ApiConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      baseUrl: map['baseUrl'] as String,
      apiKey: map['apiKey'] as String,
      models: (map['models'] as List<dynamic>).cast<String>(),
      isActive: map['isActive'] as bool? ?? false,
      selectedModel: map['selectedModel'] as String?,
      chatModelSupportsImage: map['chatModelSupportsImage'] as bool? ?? false,
      ocrEnabled: map['ocrEnabled'] as bool? ?? false,
      ocrModel: map['ocrModel'] as String?,
      ocrModelSupportsImage: map['ocrModelSupportsImage'] as bool? ?? true,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
      topP: (map['topP'] as num?)?.toDouble() ?? 0.9,
      maxTokens: (map['maxTokens'] as int?) ?? 4096,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  /// 获取显示的 API Key (脱敏)
  String get maskedApiKey {
    if (apiKey.length <= 8) return '****';
    return '${apiKey.substring(0, 8)}...';
  }
}
