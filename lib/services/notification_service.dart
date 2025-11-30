import 'package:flutter/foundation.dart';

/// 通知服务（简化版）
/// 
/// 暂时使用简化实现，避免依赖问题
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  
  NotificationService._internal();
  
  bool _initialized = false;
  
  /// 初始化
  Future<void> initialize() async {
    _initialized = true;
    debugPrint('NotificationService initialized (simplified)');
  }
  
  /// 显示新消息通知（简化版 - 仅打印日志）
  Future<void> showMessageNotification({
    required String chatId,
    required String senderName,
    required String message,
    String? avatar,
  }) async {
    if (!_initialized) return;
    debugPrint('Notification: [$senderName] $message');
    // TODO: 后续可以集成系统通知
  }
  
  /// 取消特定聊天的通知
  Future<void> cancelNotification(String chatId) async {
    // 简化版无操作
  }
  
  /// 取消所有通知
  Future<void> cancelAll() async {
    // 简化版无操作
  }
}
