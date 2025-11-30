import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';

/// 功能面板项目定义
class FnItem {
  const FnItem({
    required this.label,
    required this.asset,
  });

  final String label;
  final String asset;
}

/// 默认功能项列表
const List<FnItem> defaultFnItems = [
  FnItem(label: '相册', asset: AppAssets.iconAlbum),
  FnItem(label: '拍摄', asset: AppAssets.iconCamera),
  FnItem(label: '视频通话', asset: AppAssets.iconVideoCall),
  FnItem(label: '位置', asset: AppAssets.iconLocation),
  FnItem(label: '转账', asset: AppAssets.iconTransfer),
  FnItem(label: '红包', asset: AppAssets.iconRedPacket),
  FnItem(label: '语音输入', asset: AppAssets.iconVoiceInput),
  FnItem(label: '收藏', asset: AppAssets.iconFavorites),
];

/// 功能面板组件
class FnPanel extends StatefulWidget {
  const FnPanel({
    super.key,
    required this.onItemTap,
    this.items = defaultFnItems,
  });

  final ValueChanged<FnItem> onItemTap;
  final List<FnItem> items;

  @override
  State<FnPanel> createState() => _FnPanelState();
}

class _FnPanelState extends State<FnPanel> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: AppStyles.animationNormal,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int chunkSize = 8;
    final List<List<FnItem>> pages = [];
    for (int i = 0; i < widget.items.length; i += chunkSize) {
      pages.add(widget.items.sublist(i, min(i + chunkSize, widget.items.length)));
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        color: AppColors.backgroundChat,
        height: 220,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _pageIndex = index);
                },
                itemBuilder: (context, pageIndex) {
                  return _FnPage(
                    items: pages[pageIndex],
                    pageIndex: pageIndex,
                    onItemTap: widget.onItemTap,
                  );
                },
              ),
            ),
            if (pages.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PageIndicator(
                  count: pages.length,
                  current: _pageIndex,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 功能面板单页
class _FnPage extends StatelessWidget {
  const _FnPage({
    required this.items,
    required this.pageIndex,
    required this.onItemTap,
  });

  final List<FnItem> items;
  final int pageIndex;
  final ValueChanged<FnItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            crossAxisSpacing: 10,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _FnCell(
              item: items[index],
              index: index,
              onTap: () => onItemTap(items[index]),
            );
          },
        ),
      ),
    );
  }
}

/// 功能单元格组件
class _FnCell extends StatefulWidget {
  const _FnCell({
    required this.item,
    required this.index,
    required this.onTap,
  });

  final FnItem item;
  final int index;
  final VoidCallback onTap;

  @override
  State<_FnCell> createState() => _FnCellState();
}

class _FnCellState extends State<_FnCell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 交错动画效果
    final delay = widget.index * 0.05;
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, 0.5 + delay, curve: Curves.easeOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, 0.5 + delay, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: _isPressed ? 0.9 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.5),
                  ),
                  boxShadow: _isPressed
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.shadow.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    widget.item.asset,
                    width: 26,
                    height: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.item.label,
              style: TextStyle(
                fontSize: 12,
                color: _isPressed
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 页面指示器
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.current,
  });

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final bool active = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 18 : 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.textSecondary.withOpacity(0.6)
                : AppColors.textSecondary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

