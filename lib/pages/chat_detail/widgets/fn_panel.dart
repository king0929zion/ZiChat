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
    this.enabled = true,
  });

  final String label;
  final String asset;
  final bool enabled;
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

class _FnPanelState extends State<FnPanel> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int chunkSize = 8;
    final List<List<FnItem>> pages = [];
    for (int i = 0; i < widget.items.length; i += chunkSize) {
      pages.add(widget.items.sublist(i, min(i + chunkSize, widget.items.length)));
    }

    return Container(
      color: AppColors.backgroundChat,
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const ClampingScrollPhysics(),
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

class _FnCellState extends State<_FnCell> {
  bool _isPressed = false;

  void _handleTap(bool enabled) {
    if (enabled) {
      HapticFeedback.lightImpact();
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.item.enabled;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleTap(enabled),
            onHighlightChanged:
                enabled ? (value) => setState(() => _isPressed = value) : null,
            borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
            splashColor: Colors.transparent,
            highlightColor: enabled ? AppColors.disabledBg : Colors.transparent,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: enabled ? AppColors.surface : const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
                border: Border.all(
                  color: enabled
                      ? (_isPressed ? AppColors.textDisabled : AppColors.border)
                      : AppColors.border,
                ),
                boxShadow: (enabled && !_isPressed)
                    ? [
                        BoxShadow(
                          color: AppColors.shadow.withValues(alpha: 0.06),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: SvgPicture.asset(
                  widget.item.asset,
                  width: 26,
                  height: 26,
                  colorFilter: enabled
                      ? null
                      : const ColorFilter.mode(
                          AppColors.textDisabled,
                          BlendMode.srcIn,
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.item.label,
          style: TextStyle(
            fontSize: 12,
            color: enabled
                ? (_isPressed ? AppColors.primary : AppColors.textPrimary)
                : AppColors.textDisabled,
          ),
        ),
      ],
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
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 18 : 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.textSecondary.withValues(alpha: 0.6)
                : AppColors.textSecondary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

