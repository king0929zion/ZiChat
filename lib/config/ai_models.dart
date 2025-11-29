/// AI 模型配置
/// 
/// 定义可用的对话模型和图像生成模型
class AiModels {
  /// 内置对话模型列表
  static const List<ChatModel> builtInChatModels = [
    ChatModel(
      id: 'kimi-k2-0905',
      name: 'Kimi K2',
      description: '月之暗面最新模型，擅长中文对话',
      provider: 'iflow',
    ),
    ChatModel(
      id: 'qwen3-max',
      name: 'Qwen3 Max',
      description: '阿里通义千问，综合能力强',
      provider: 'iflow',
    ),
    ChatModel(
      id: 'glm-4.6',
      name: 'GLM-4.6',
      description: '智谱 AI，逻辑推理出色',
      provider: 'iflow',
    ),
    ChatModel(
      id: 'deepseek-v3.2',
      name: 'DeepSeek V3.2',
      description: '深度求索，代码和推理能力强',
      provider: 'iflow',
    ),
  ];
  
  /// 内置图像生成模型
  static const List<ImageModel> builtInImageModels = [
    ImageModel(
      id: 'Tongyi-MAI/Z-Image-Turbo',
      name: 'Z-Image Turbo',
      description: '通义万相快速生图模型',
      provider: 'modelscope',
    ),
  ];
  
  /// 获取默认对话模型
  static ChatModel get defaultChatModel => builtInChatModels.first;
  
  /// 获取默认图像模型
  static ImageModel get defaultImageModel => builtInImageModels.first;
  
  /// 获取事件生成专用模型（DeepSeek V3.2）
  static ChatModel get eventGenerationModel => builtInChatModels.firstWhere(
    (m) => m.id == 'deepseek-v3.2',
    orElse: () => defaultChatModel,
  );
}

/// 对话模型
class ChatModel {
  final String id;
  final String name;
  final String description;
  final String provider;
  
  const ChatModel({
    required this.id,
    required this.name,
    required this.description,
    required this.provider,
  });
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'provider': provider,
  };
  
  factory ChatModel.fromMap(Map<String, dynamic> map) => ChatModel(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String,
    provider: map['provider'] as String,
  );
}

/// 图像生成模型
class ImageModel {
  final String id;
  final String name;
  final String description;
  final String provider;
  
  const ImageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.provider,
  });
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'provider': provider,
  };
  
  factory ImageModel.fromMap(Map<String, dynamic> map) => ImageModel(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String,
    provider: map['provider'] as String,
  );
}

