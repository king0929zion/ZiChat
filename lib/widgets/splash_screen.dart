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
      backgroundColor: const Color(0xFFEDEDED), // 浅灰背景
      body: SizedBox.expand(
        child: Image.asset(
          'assets/splash.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            // 备用方案：显示应用图标
            return Container(
              color: const Color(0xFFEDEDED),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF07C160),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.chat_bubble,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ZiChat',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D2129),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const CircularProgressIndicator(
                      color: Color(0xFF07C160),
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
