import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/widgets/weui/weui.dart';

class MyQrcodePage extends StatelessWidget {
  const MyQrcodePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            color: bg,
            child: Column(
              children: [
                _buildHeader(context),
                const Expanded(child: _Body()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 52,
      color: const Color(0xFFFFFFFF),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            padding: const EdgeInsets.all(8),
            icon: SvgPicture.asset(
              'assets/icon/common/go-back.svg',
              width: 12,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xFF1D2129),
                BlendMode.srcIn,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '我的二维码',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D2129),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              WeuiToast.show(context, message: '更多功能暂未开放');
            },
            icon: SvgPicture.asset(
              'assets/icon/three-dot.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xFF1D2129),
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            'assets/me.png',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Bella',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1D2129),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x26FF9B57),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '女',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFFF9B57),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '地区：深圳 中国',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF86909C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/qrcode-placeholder.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        '扫一扫上面的二维码，加我微信',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF86909C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const _ActionBar(),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    void show(String text) {
      WeuiToast.show(context, message: text);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => show('扫一扫功能暂未开放'),
            child: const Text(
              '扫一扫',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF576B95),
              ),
            ),
          ),
          TextButton(
            onPressed: () => show('保存图片功能暂未开放'),
            child: const Text(
              '保存图片',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF576B95),
              ),
            ),
          ),
          TextButton(
            onPressed: () => show('换个样式功能暂未开放'),
            child: const Text(
              '换个样式',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF576B95),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
