import 'package:flutter/material.dart';

/// 启动画面 - 预加载资源
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    // 模拟最小加载时间，保持开屏展示
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 微信启动页通常是黑色背景
      body: SizedBox.expand(
        child: Image.asset(
          'assets/splash.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
             // 备用方案：如果没有 splash.png，显示简洁的白底 Logo
             return Container(
               color: Colors.white,
               child: Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Image.asset(
                       'assets/app_icon/xehelper.png',
                       width: 80,
                       height: 80,
                       errorBuilder: (_, __, ___) => const Icon(Icons.chat_bubble, size: 80, color: Color(0xFF07C160)),
                     ),
                   ],
                 ),
               ),
             );
          },
        ),
      ),
    );
  }
}
