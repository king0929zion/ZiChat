enum ProviderType {
  openai,
  google,
  claude,
}

enum ProviderProxyType {
  none,
  http,
}

class ProviderProxy {
  const ProviderProxy._({
    required this.type,
    required this.address,
    required this.port,
    required this.username,
    required this.password,
  });

  const ProviderProxy.none()
      : this._(
          type: ProviderProxyType.none,
          address: '',
          port: 0,
          username: null,
          password: null,
        );

  const ProviderProxy.http({
    required String address,
    required int port,
    String? username,
    String? password,
  }) : this._(
          type: ProviderProxyType.http,
          address: address,
          port: port,
          username: username,
          password: password,
        );

  final ProviderProxyType type;
  final String address;
  final int port;
  final String? username;
  final String? password;

  bool get enabled => type != ProviderProxyType.none;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.name,
      'address': address,
      'port': port,
      'username': username,
      'password': password,
    };
  }

  static ProviderProxy fromMap(dynamic raw) {
    if (raw is Map) {
      final map = raw.cast<String, dynamic>();
      final typeStr = (map['type'] ?? 'none').toString();
      final type = ProviderProxyType.values
          .where((e) => e.name == typeStr)
          .firstOrNull ??
          ProviderProxyType.none;
      if (type == ProviderProxyType.http) {
        return ProviderProxy.http(
          address: (map['address'] ?? '').toString(),
          port: (map['port'] as num?)?.toInt() ?? 8080,
          username: map['username']?.toString(),
          password: map['password']?.toString(),
        );
      }
      return const ProviderProxy.none();
    }
    return const ProviderProxy.none();
  }
}

class BalanceOption {
  const BalanceOption({
    this.enabled = false,
    this.apiPath = '/credits',
    this.resultPath = 'data.total_usage',
  });

  final bool enabled;
  final String apiPath;
  final String resultPath;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'apiPath': apiPath,
      'resultPath': resultPath,
    };
  }

  static BalanceOption fromMap(dynamic raw) {
    if (raw is Map) {
      final map = raw.cast<String, dynamic>();
      return BalanceOption(
        enabled: map['enabled'] as bool? ?? false,
        apiPath: (map['apiPath'] ?? '/credits').toString(),
        resultPath: (map['resultPath'] ?? 'data.total_usage').toString(),
      );
    }
    return const BalanceOption();
  }
}

enum ModelType {
  chat,
  image,
  embedding,
}

enum ModelModality {
  text,
  image,
}

enum ModelAbility {
  tool,
  reasoning,
}

class ApiModel {
  const ApiModel({
    required this.id,
    required this.modelId,
    required this.displayName,
    this.type = ModelType.chat,
    this.inputModalities = const [ModelModality.text],
    this.outputModalities = const [ModelModality.text],
    this.abilities = const [],
  });

  final String id;
  final String modelId;
  final String displayName;
  final ModelType type;
  final List<ModelModality> inputModalities;
  final List<ModelModality> outputModalities;
  final List<ModelAbility> abilities;

  bool get supportsImageInput => inputModalities.contains(ModelModality.image);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'modelId': modelId,
      'displayName': displayName,
      'type': type.name,
      'inputModalities': inputModalities.map((e) => e.name).toList(),
      'outputModalities': outputModalities.map((e) => e.name).toList(),
      'abilities': abilities.map((e) => e.name).toList(),
    };
  }

  static ApiModel fromMap(Map<String, dynamic> map) {
    final typeStr = (map['type'] ?? ModelType.chat.name).toString();
    final type =
        ModelType.values.where((e) => e.name == typeStr).firstOrNull ??
            ModelType.chat;

    final inputModalities = (map['inputModalities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .map(
              (s) =>
                  ModelModality.values.where((m) => m.name == s).firstOrNull ??
                  ModelModality.text,
            )
            .toList() ??
        const [ModelModality.text];

    final outputModalities = (map['outputModalities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .map(
              (s) =>
                  ModelModality.values.where((m) => m.name == s).firstOrNull ??
                  ModelModality.text,
            )
            .toList() ??
        const [ModelModality.text];

    final abilities = (map['abilities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .map(
              (s) =>
                  ModelAbility.values.where((a) => a.name == s).firstOrNull ??
                  ModelAbility.tool,
            )
            .toList() ??
        const <ModelAbility>[];

    return ApiModel(
      id: (map['id'] ?? '').toString(),
      modelId: (map['modelId'] ?? '').toString(),
      displayName: (map['displayName'] ?? '').toString(),
      type: type,
      inputModalities: inputModalities.isEmpty
          ? const [ModelModality.text]
          : inputModalities,
      outputModalities: outputModalities.isEmpty
          ? const [ModelModality.text]
          : outputModalities,
      abilities: abilities,
    );
  }

  static ApiModel fromLegacy(String modelId) {
    final id = modelId.trim().isEmpty ? 'model' : modelId.trim();
    return ApiModel(
      id: id,
      modelId: modelId.trim(),
      displayName: modelId.trim(),
    );
  }
}

/// API 配置模型（对齐 RikkaHub 的 ProviderSetting 思路）
class ApiConfig {
  ApiConfig({
    required this.id,
    required this.type,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.models,
    this.isActive = false,
    this.selectedModel,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.maxTokens = 4096,
    this.createdAt,
    this.sortOrder,
    this.builtIn = false,
    this.chatCompletionsPath = '/chat/completions',
    this.useResponseApi = false,
    this.proxy = const ProviderProxy.none(),
    this.balanceOption = const BalanceOption(),
    this.vertexAI = false,
    this.privateKey = '',
    this.serviceAccountEmail = '',
    this.location = 'us-central1',
    this.projectId = '',
  });

  final String id;
  final ProviderType type;
  final String name;
  final String baseUrl;
  final String apiKey;
  final List<ApiModel> models;
  final bool isActive;
  final String? selectedModel;
  final double temperature;
  final double topP;
  final int maxTokens;
  final DateTime? createdAt;
  final int? sortOrder;
  final bool builtIn;
  final String chatCompletionsPath;
  final bool useResponseApi;
  final ProviderProxy proxy;
  final BalanceOption balanceOption;

  final bool vertexAI;
  final String privateKey;
  final String serviceAccountEmail;
  final String location;
  final String projectId;

  ApiConfig copyWith({
    String? id,
    ProviderType? type,
    String? name,
    String? baseUrl,
    String? apiKey,
    List<ApiModel>? models,
    bool? isActive,
    String? selectedModel,
    double? temperature,
    double? topP,
    int? maxTokens,
    DateTime? createdAt,
    int? sortOrder,
    bool? builtIn,
    String? chatCompletionsPath,
    bool? useResponseApi,
    ProviderProxy? proxy,
    BalanceOption? balanceOption,
    bool? vertexAI,
    String? privateKey,
    String? serviceAccountEmail,
    String? location,
    String? projectId,
  }) {
    return ApiConfig(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      models: models ?? this.models,
      isActive: isActive ?? this.isActive,
      selectedModel: selectedModel ?? this.selectedModel,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      maxTokens: maxTokens ?? this.maxTokens,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
      builtIn: builtIn ?? this.builtIn,
      chatCompletionsPath: chatCompletionsPath ?? this.chatCompletionsPath,
      useResponseApi: useResponseApi ?? this.useResponseApi,
      proxy: proxy ?? this.proxy,
      balanceOption: balanceOption ?? this.balanceOption,
      vertexAI: vertexAI ?? this.vertexAI,
      privateKey: privateKey ?? this.privateKey,
      serviceAccountEmail: serviceAccountEmail ?? this.serviceAccountEmail,
      location: location ?? this.location,
      projectId: projectId ?? this.projectId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'name': name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'models': models.map((m) => m.toMap()).toList(),
      'isActive': isActive,
      'selectedModel': selectedModel,
      'temperature': temperature,
      'topP': topP,
      'maxTokens': maxTokens,
      'createdAt': createdAt?.toIso8601String(),
      'sortOrder': sortOrder,
      'builtIn': builtIn,
      'chatCompletionsPath': chatCompletionsPath,
      'useResponseApi': useResponseApi,
      'proxy': proxy.toMap(),
      'balanceOption': balanceOption.toMap(),
      'vertexAI': vertexAI,
      'privateKey': privateKey,
      'serviceAccountEmail': serviceAccountEmail,
      'location': location,
      'projectId': projectId,
    };
  }

  static ApiConfig fromMap(Map<String, dynamic> map) {
    final typeStr = (map['type'] ?? ProviderType.openai.name).toString();
    final type =
        ProviderType.values.where((e) => e.name == typeStr).firstOrNull ??
            ProviderType.openai;

    final rawModels = map['models'];
    final models = <ApiModel>[];
    if (rawModels is List) {
      for (final item in rawModels) {
        if (item is String) {
          models.add(ApiModel.fromLegacy(item));
        } else if (item is Map) {
          models.add(ApiModel.fromMap(item.cast<String, dynamic>()));
        }
      }
    }

    return ApiConfig(
      id: (map['id'] ?? '').toString(),
      type: type,
      name: (map['name'] ?? '').toString(),
      baseUrl: (map['baseUrl'] ?? '').toString(),
      apiKey: (map['apiKey'] ?? '').toString(),
      models: models,
      isActive: map['isActive'] as bool? ?? false,
      selectedModel: map['selectedModel'] as String?,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
      topP: (map['topP'] as num?)?.toDouble() ?? 0.9,
      maxTokens: (map['maxTokens'] as int?) ?? 4096,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      sortOrder: (map['sortOrder'] as num?)?.toInt(),
      builtIn: map['builtIn'] as bool? ?? false,
      chatCompletionsPath:
          (map['chatCompletionsPath'] ?? '/chat/completions').toString(),
      useResponseApi: map['useResponseApi'] as bool? ?? false,
      proxy: ProviderProxy.fromMap(map['proxy']),
      balanceOption: BalanceOption.fromMap(map['balanceOption']),
      vertexAI: map['vertexAI'] as bool? ?? false,
      privateKey: (map['privateKey'] ?? '').toString(),
      serviceAccountEmail: (map['serviceAccountEmail'] ?? '').toString(),
      location: (map['location'] ?? 'us-central1').toString(),
      projectId: (map['projectId'] ?? '').toString(),
    );
  }

  /// 获取显示的 API Key (脱敏)
  String get maskedApiKey {
    if (apiKey.length <= 8) return '****';
    return '${apiKey.substring(0, 8)}...';
  }

  bool get hasModels => models.isNotEmpty;

  ApiModel? getModelById(String modelId) {
    final id = modelId.trim();
    if (id.isEmpty) return null;
    return models.where((m) => m.modelId == id).firstOrNull;
  }

  ApiModel? get defaultChatModel {
    final preferredId = (selectedModel ?? '').trim();
    if (preferredId.isNotEmpty) {
      final found = getModelById(preferredId);
      if (found != null) return found;
    }
    return models.where((m) => m.type == ModelType.chat).firstOrNull ??
        models.firstOrNull;
  }
}
