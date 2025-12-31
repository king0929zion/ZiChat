import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/config/app_config.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/pages/home_page.dart';
import 'package:zichat/services/user_data_manager.dart';
import 'package:zichat/storage/api_config_storage.dart';
import 'package:zichat/storage/chat_background_storage.dart';
import 'package:zichat/storage/friend_storage.dart';
import 'package:zichat/storage/real_friend_storage.dart';
import 'package:zichat/storage/user_profile_storage.dart';

/// 应用入口
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置系统 UI 样式
  _setupSystemUI();
  
  // 初始化核心服务
  await _initializeCoreServices();
  
  // 启动应用
  runApp(const ZiChatApp());
}

/// 设置系统 UI 样式
void _setupSystemUI() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
}

/// 初始化核心服务
Future<void> _initializeCoreServices() async {
  try {
    // Hive 必须首先完成
    await Hive.initFlutter();

    // 并行打开必要的 Hive Box
    await Future.wait([
      Hive.openBox('chat_messages'),
      Hive.openBox('ai_config'),
      Hive.openBox('real_friends'),
      Hive.openBox('friends'), // FriendStorage 需要
      Hive.openBox('chat_backgrounds'), // ChatBackgroundStorage 需要
      Hive.openBox('api_configs'), // ApiConfigStorage 需要
    ]);

    // 并行初始化核心存储服务
    await Future.wait([
      FriendStorage.initialize(),
      ChatBackgroundStorage.initialize(),
      ApiConfigStorage.initialize(),
      UserProfileStorage.initialize(),
      RealFriendStorage.initialize(),
    ]);

    // 初始化用户数据管理器（支持头像/昵称实时更新）
    await UserDataManager.instance.initialize();
  } catch (e) {
    // 打印错误但不阻止应用启动
    debugPrint('初始化核心服务失败: $e');
  }
}

/// ZiChat 应用
class ZiChatApp extends StatelessWidget {
  const ZiChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZiChat',
      debugShowCheckedModeBanner: false,
      theme: AppConfig.createTheme(),
      home: const AppRouter(),
    );
  }
}

/// 应用路由器 - 处理主页面显示
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage(title: 'ZiChat');
  }
}
