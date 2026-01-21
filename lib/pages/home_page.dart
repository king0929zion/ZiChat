import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/pages/add_contacts_page.dart';
import 'package:zichat/pages/chats_page.dart';
import 'package:zichat/pages/contacts_page.dart';
import 'package:zichat/pages/discover_page.dart';
import 'package:zichat/pages/me_page.dart';
import 'package:zichat/utils/responsive.dart';
import 'package:zichat/widgets/quick_actions_sheet.dart';

/// 主页面 - 包含底部导航栏
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _tabAnimationController;
  late Animation<double> _tabFadeAnimation;

  // 缓存页面实例
  final List<Widget> _pages = const [
    ChatsPage(),
    ContactsPage(),
    DiscoverPage(),
    MePage(),
  ];

  @override
  void initState() {
    super.initState();
    _tabAnimationController = AnimationController(
      vsync: this,
      duration: AppStyles.animationFast,
    );
    _tabFadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _tabAnimationController, curve: Curves.easeOut),
    );
    _tabAnimationController.forward();
  }

  @override
  void dispose() {
    _tabAnimationController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      _tabAnimationController.reset();
      setState(() => _currentIndex = index);
      _tabAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 设置状态栏和导航栏颜色
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return ResponsiveBuilder(
      builder: (context, info) {
        // 桌面端使用侧边栏布局
        if (info.isDesktop) {
          return _buildDesktopLayout(info);
        }
        // 移动端/平板使用底部导航栏
        return _buildMobileLayout(info);
      },
    );
  }

  Widget _buildMobileLayout(ResponsiveInfo info) {
    final topRegionColor =
        _currentIndex == 3 ? AppColors.surface : AppColors.backgroundChat;
    return Scaffold(
      backgroundColor: topRegionColor,
      body: SafeArea(
        top: true,
        bottom: true,
        child: ResponsiveContainer(
          maxWidth: info.maxContentWidth,
          backgroundColor: topRegionColor,
          child: Column(
            children: [
              HomeHeader(currentIndex: _currentIndex),
              Expanded(
                child: AnimatedBuilder(
                  animation: _tabFadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _tabFadeAnimation.value,
                      child: child,
                    );
                  },
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _pages,
                  ),
                ),
              ),
              HomeTabBar(
                currentIndex: _currentIndex,
                onTap: _onTabChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ResponsiveInfo info) {
    final topRegionColor =
        _currentIndex == 3 ? AppColors.surface : AppColors.backgroundChat;
    return Scaffold(
      backgroundColor: topRegionColor,
      body: SafeArea(
        child: Row(
          children: [
            // 侧边导航栏
            Container(
              width: 80,
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  right: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // 头像
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: const DecorationImage(
                        image: AssetImage('assets/avatar.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 导航项
                  _DesktopNavItem(
                    icon: AppAssets.tabChats,
                    activeIcon: AppAssets.tabChatsActive,
                    label: '微信',
                    isActive: _currentIndex == 0,
                    onTap: () => _onTabChanged(0),
                  ),
                  _DesktopNavItem(
                    icon: AppAssets.tabContacts,
                    activeIcon: AppAssets.tabContactsActive,
                    label: '通讯录',
                    isActive: _currentIndex == 1,
                    onTap: () => _onTabChanged(1),
                  ),
                  _DesktopNavItem(
                    icon: AppAssets.tabDiscover,
                    activeIcon: AppAssets.tabDiscoverActive,
                    label: '发现',
                    isActive: _currentIndex == 2,
                    onTap: () => _onTabChanged(2),
                  ),
                  const Spacer(),
                  _DesktopNavItem(
                    icon: AppAssets.tabMe,
                    activeIcon: AppAssets.tabMeActive,
                    label: '我',
                    isActive: _currentIndex == 3,
                    onTap: () => _onTabChanged(3),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // 主内容区
            Expanded(
              child: Container(
                color: topRegionColor,
                constraints: BoxConstraints(maxWidth: info.maxContentWidth),
                child: Column(
                  children: [
                    HomeHeader(currentIndex: _currentIndex),
                    Expanded(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: _pages,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 桌面端导航项
class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String icon;
  final String activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 60,
          height: 60,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color.fromRGBO(7, 193, 96, 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                isActive ? activeIcon : icon,
                width: 24,
                height: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header 组件
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    if (currentIndex == 3) {
      return const SizedBox.shrink();
    }

    String title;
    Widget? action;

    if (currentIndex == 0) {
      title = '微信';
      action = HeaderIconButton(
        asset: AppAssets.iconCirclePlus,
        onTap: () => showQuickActionsSheet(context),
      );
    } else if (currentIndex == 1) {
      title = '通讯录';
      action = HeaderIconButton(
        asset: AppAssets.iconAddFriend,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddContactsPage()),
          );
        },
      );
    } else {
      title = '发现';
      action = HeaderIconButton(
        asset: AppAssets.iconSearch,
        onTap: () {},
      );
    }

    return Container(
      height: 52,
      color: AppColors.backgroundChat,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const SizedBox(width: 36),
          Expanded(
            child: Center(
              child: Text(title, style: AppStyles.titleLarge),
            ),
          ),
          action,
        ],
      ),
    );
  }
}

/// Header 图标按钮
class HeaderIconButton extends StatefulWidget {
  const HeaderIconButton({
    super.key,
    required this.asset,
    required this.onTap,
  });

  final String asset;
  final VoidCallback onTap;

  @override
  State<HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<HeaderIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: SvgPicture.asset(
              widget.asset,
              width: 20,
              height: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部导航栏
class HomeTabBar extends StatelessWidget {
  const HomeTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          HomeTabItem(
            index: 0,
            currentIndex: currentIndex,
            label: '微信',
            iconAsset: AppAssets.tabChats,
            iconActiveAsset: AppAssets.tabChatsActive,
            onTap: onTap,
          ),
          HomeTabItem(
            index: 1,
            currentIndex: currentIndex,
            label: '通讯录',
            iconAsset: AppAssets.tabContacts,
            iconActiveAsset: AppAssets.tabContactsActive,
            onTap: onTap,
          ),
          HomeTabItem(
            index: 2,
            currentIndex: currentIndex,
            label: '发现',
            iconAsset: AppAssets.tabDiscover,
            iconActiveAsset: AppAssets.tabDiscoverActive,
            onTap: onTap,
          ),
          HomeTabItem(
            index: 3,
            currentIndex: currentIndex,
            label: '我',
            iconAsset: AppAssets.tabMe,
            iconActiveAsset: AppAssets.tabMeActive,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// 底部导航项
class HomeTabItem extends StatefulWidget {
  const HomeTabItem({
    super.key,
    required this.index,
    required this.currentIndex,
    required this.label,
    required this.iconAsset,
    required this.iconActiveAsset,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final String label;
  final String iconAsset;
  final String iconActiveAsset;
  final ValueChanged<int> onTap;

  @override
  State<HomeTabItem> createState() => _HomeTabItemState();
}

class _HomeTabItemState extends State<HomeTabItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.96), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HomeTabItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == widget.currentIndex &&
        oldWidget.currentIndex != widget.currentIndex) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool active = widget.index == widget.currentIndex;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTap(widget.index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: active ? _scaleAnimation.value : 1.0,
                  child: child,
                );
              },
              child: SizedBox(
                width: 26,
                height: 26,
                child: AnimatedSwitcher(
                  duration: AppStyles.animationFast,
                  child: SvgPicture.asset(
                    active ? widget.iconActiveAsset : widget.iconAsset,
                    key: ValueKey(active),
                    width: 26,
                    height: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: AppStyles.animationFast,
              style: TextStyle(
                fontSize: 12,
                color: active ? AppColors.primary : AppColors.textSecondary,
                fontWeight: active ? FontWeight.w500 : FontWeight.normal,
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}
