import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 通知服务
/// 
/// 用于 AI 主动消息时推送通知
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  /// 初始化
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Android 设置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS 设置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      _initialized = true;
      debugPrint('NotificationService initialized');
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }
  
  /// 点击通知时的回调
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: 跳转到对应的聊天页面
  }
  
  /// 显示新消息通知
  Future<void> showMessageNotification({
    required String chatId,
    required String senderName,
    required String message,
    String? avatar,
  }) async {
    if (!_initialized) return;
    
    // Android 通知详情
    final androidDetails = AndroidNotificationDetails(
      'chat_messages',
      '聊天消息',
      channelDescription: '好友发来的消息',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: senderName,
        summaryText: '新消息',
      ),
    );
    
    // iOS 通知详情
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    try {
      await _notifications.show(
        chatId.hashCode,
        senderName,
        message,
        details,
        payload: chatId,
      );
    } catch (e) {
      debugPrint('Show notification error: $e');
    }
  }
  
  /// 取消特定聊天的通知
  Future<void> cancelNotification(String chatId) async {
    await _notifications.cancel(chatId.hashCode);
  }
  
  /// 取消所有通知
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

