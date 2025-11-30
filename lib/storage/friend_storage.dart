import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/models/friend.dart';

/// 好友数据存储
class FriendStorage {
  static const String _boxName = 'friends';
  static Box<String>? _box;
  
  static Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
  }
  
  static Box<String> get _safeBox {
    if (_box == null) {
      throw Exception('FriendStorage not initialized');
    }
    return _box!;
  }
  
  /// 获取所有好友
  static List<Friend> getAllFriends() {
    final friends = <Friend>[];
    for (final key in _safeBox.keys) {
      final json = _safeBox.get(key);
      if (json != null) {
        try {
          friends.add(Friend.fromMap(jsonDecode(json)));
        } catch (_) {}
      }
    }
    // 按最后消息时间排序
    friends.sort((a, b) {
      final aTime = a.lastMessageTime ?? a.createdAt;
      final bTime = b.lastMessageTime ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    return friends;
  }
  
  /// 获取单个好友
  static Friend? getFriend(String id) {
    final json = _safeBox.get(id);
    if (json == null) return null;
    try {
      return Friend.fromMap(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }
  
  /// 保存好友
  static Future<void> saveFriend(Friend friend) async {
    await _safeBox.put(friend.id, jsonEncode(friend.toMap()));
  }
  
  /// 删除好友
  static Future<void> deleteFriend(String id) async {
    await _safeBox.delete(id);
  }
  
  /// 更新最后消息
  static Future<void> updateLastMessage(String id, String message) async {
    final friend = getFriend(id);
    if (friend != null) {
      await saveFriend(friend.copyWith(
        lastMessage: message,
        lastMessageTime: DateTime.now(),
      ));
    }
  }
  
  /// 增加未读数
  static Future<void> incrementUnread(String id) async {
    final friend = getFriend(id);
    if (friend != null) {
      await saveFriend(friend.copyWith(unread: friend.unread + 1));
    }
  }
  
  /// 清除未读数
  static Future<void> clearUnread(String id) async {
    final friend = getFriend(id);
    if (friend != null) {
      await saveFriend(friend.copyWith(unread: 0));
    }
  }
}

