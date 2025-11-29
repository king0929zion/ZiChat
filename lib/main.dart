import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/pages/chats_page.dart';
import 'package:zichat/pages/contacts_page.dart';
import 'package:zichat/pages/discover_page.dart';
import 'package:zichat/pages/me_page.dart';
import 'package:zichat/pages/add_contacts_page.dart';
import 'package:zichat/pages/code_scanner_page.dart';
import 'package:zichat/pages/money_qrcode_page.dart';
import 'package:zichat/services/ai_soul_engine.dart';
import 'package:zichat/services/svg_precache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置系统 UI 样式
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // 初始化 Hive
  await Hive.initFlutter();
  await Hive.openBox('chat_messages');
  await Hive.openBox('ai_config');
  
  // 初始化 AI 灵魂引擎
  await AiSoulEngine.init();
  
  runApp(const MyApp());
}

void _showChatsQuickActions(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _QuickActionsSheet(parentContext: context);
    },
  );
}

/// 快速操作底部弹窗
class _QuickActionsSheet extends StatefulWidget {
  const _QuickActionsSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  State<_QuickActionsSheet> createState() => _QuickActionsSheetState();
}

class _QuickActionsSheetState extends State<_QuickActionsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppStyles.animationNormal,
    );
    _slideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildItem({
    required String label,
    required String icon,
    VoidCallback? onTap,
    int index = 0,
  }) {
    Widget leading;
    if (icon.endsWith('.svg')) {
      leading = SvgPicture.asset(icon, width: 22, height: 22);
    } else {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(icon, width: 22, height: 22, fit: BoxFit.cover),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: _QuickActionItem(
        label: label,
        leading: leading,
        onTap: () {
          Navigator.of(context).pop();
          if (onTap != null) {
            onTap();
          } else {
            ScaffoldMessenger.of(widget.parentContext).showSnackBar(
              SnackBar(
                content: Text('$label 功能暂未开放'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
          boxShadow: AppStyles.shadowMedium,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              _buildItem(
                index: 0,
                label: '发起群聊',
                icon: AppAssets.iconPlus,
              ),
              _buildItem(
                index: 1,
                label: '加入群聊',
                icon: AppAssets.iconPlus,
              ),
              _buildItem(
                index: 2,
                label: '添加朋友',
                icon: AppAssets.iconAddFriend,
                onTap: () {
                  Navigator.of(widget.parentContext).push(
                    MaterialPageRoute(builder: (_) => const AddContactsPage()),
                  );
                },
              ),
              _buildItem(
                index: 3,
                label: '扫一扫',
                icon: 'assets/icon/discover/scan-v2.jpeg',
                onTap: () {
                  Navigator.of(widget.parentContext).push(
                    MaterialPageRoute(builder: (_) => const CodeScannerPage()),
                  );
                },
              ),
              _buildItem(
                index: 4,
                label: '收付款',
                icon: 'assets/icon/discover/qrcode.svg',
                onTap: () {
                  Navigator.of(widget.parentContext).push(
                    MaterialPageRoute(builder: (_) => const MoneyQrcodePage()),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// 快速操作项组件
class _QuickActionItem extends StatefulWidget {
  const _QuickActionItem({
    required this.label,
    required this.leading,
    required this.onTap,
  });

  final String label;
  final Widget leading;
  final VoidCallback onTap;

  @override
  State<_QuickActionItem> createState() => _QuickActionItemState();
}

class _QuickActionItemState extends State<_QuickActionItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: AppStyles.animationFast,
        color: _isPressed ? AppColors.background : AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              widget.leading,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: AppStyles.titleSmall,
                ),
              ),
              SvgPicture.asset(
                AppAssets.iconArrowRight,
                width: 12,
                height: 12,
                colorFilter: const ColorFilter.mode(
                  AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZiChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primary,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppStyles.titleLarge,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: TextStyle(fontSize: 12),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _SmoothPageTransitionsBuilder(),
            TargetPlatform.iOS: _SmoothPageTransitionsBuilder(),
            TargetPlatform.windows: _SmoothPageTransitionsBuilder(),
            TargetPlatform.macOS: _SmoothPageTransitionsBuilder(),
            TargetPlatform.linux: _SmoothPageTransitionsBuilder(),
          },
        ),
        useMaterial3: true,
      ),
      home: const _SplashScreen(),
    );
  }
}

/// 启动画面 - 预加载资源
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _loadResources();
  }

  Future<void> _loadResources() async {
    // 预加载 SVG 资源
    await SvgPrecacheService.precacheAll(context);
    
    // 模拟最小加载时间
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isLoading = false);
      // 等待动画完成后导航
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return const MyHomePage(title: 'ZiChat');
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/app_icon/xehelper.png',
                    width: 60,
                    height: 60,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ZiChat',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textWhite.withOpacity(0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            color: AppColors.surface,
            child: Column(
              children: [
                _HomeHeader(currentIndex: _currentIndex),
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
                _HomeTabBar(
                  currentIndex: _currentIndex,
                  onTap: _onTabChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.currentIndex,
  });

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
      action = _HeaderIconButton(
        asset: AppAssets.iconCirclePlus,
        onTap: () => _showChatsQuickActions(context),
      );
    } else if (currentIndex == 1) {
      title = '通讯录';
      action = _HeaderIconButton(
        asset: AppAssets.iconAddFriend,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddContactsPage()),
          );
        },
      );
    } else {
      title = '发现';
      action = _HeaderIconButton(
        asset: AppAssets.iconSearch,
        onTap: () {},
      );
    }

    return Container(
      height: 52,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const SizedBox(width: 36, height: 36),
          Expanded(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: AppStyles.animationFast,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.9 + 0.1 * value,
                      child: child,
                    ),
                  );
                },
                key: ValueKey(title),
                child: Text(title, style: AppStyles.titleLarge),
              ),
            ),
          ),
          SizedBox(
            width: 36,
            height: 36,
            child: action,
          ),
        ],
      ),
    );
  }
}

/// Header 图标按钮
class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({
    required this.asset,
    required this.onTap,
  });

  final String asset;
  final VoidCallback onTap;

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton>
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
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
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
          width: 22,
          height: 22,
        ),
      ),
    );
  }
}

class _HomeTabBar extends StatelessWidget {
  const _HomeTabBar({
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
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          _HomeTabItem(
            index: 0,
            currentIndex: currentIndex,
            label: '微信',
            iconAsset: AppAssets.tabChats,
            iconActiveAsset: AppAssets.tabChatsActive,
            onTap: onTap,
          ),
          _HomeTabItem(
            index: 1,
            currentIndex: currentIndex,
            label: '通讯录',
            iconAsset: AppAssets.tabContacts,
            iconActiveAsset: AppAssets.tabContactsActive,
            onTap: onTap,
          ),
          _HomeTabItem(
            index: 2,
            currentIndex: currentIndex,
            label: '发现',
            iconAsset: AppAssets.tabDiscover,
            iconActiveAsset: AppAssets.tabDiscoverActive,
            onTap: onTap,
          ),
          _HomeTabItem(
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

class _HomeTabItem extends StatefulWidget {
  const _HomeTabItem({
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
  State<_HomeTabItem> createState() => _HomeTabItemState();
}

class _HomeTabItemState extends State<_HomeTabItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_HomeTabItem oldWidget) {
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
