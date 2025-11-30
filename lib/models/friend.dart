/// 好友数据模型
class Friend {
  final String id;
  final String name;
  final String avatar;
  final String prompt;
  final DateTime createdAt;
  final int unread;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  
  const Friend({
    required this.id,
    required this.name,
    required this.avatar,
    this.prompt = '',
    required this.createdAt,
    this.unread = 0,
    this.lastMessage,
    this.lastMessageTime,
  });
  
  Friend copyWith({
    String? name,
    String? avatar,
    String? prompt,
    int? unread,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) {
    return Friend(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      prompt: prompt ?? this.prompt,
      createdAt: createdAt,
      unread: unread ?? this.unread,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'prompt': prompt,
    'createdAt': createdAt.toIso8601String(),
    'unread': unread,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime?.toIso8601String(),
  };
  
  factory Friend.fromMap(Map<String, dynamic> map) => Friend(
    id: map['id'] as String,
    name: map['name'] as String,
    avatar: map['avatar'] as String,
    prompt: map['prompt'] as String? ?? '',
    createdAt: DateTime.parse(map['createdAt'] as String),
    unread: map['unread'] as int? ?? 0,
    lastMessage: map['lastMessage'] as String?,
    lastMessageTime: map['lastMessageTime'] != null 
        ? DateTime.parse(map['lastMessageTime'] as String)
        : null,
  );
}

