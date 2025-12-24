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
    this.createdAt,
  });

  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final List<String> models;
  final bool isActive;
  final String? selectedModel;
  final DateTime? createdAt;

  ApiConfig copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    List<String>? models,
    bool? isActive,
    String? selectedModel,
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
