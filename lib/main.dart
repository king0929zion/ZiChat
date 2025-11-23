import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zichat/pages/chats_page.dart';
import 'package:zichat/pages/contacts_page.dart';
import 'package:zichat/pages/discover_page.dart';
import 'package:zichat/pages/me_page.dart';
import 'package:zichat/pages/add_contacts_page.dart';
import 'package:zichat/pages/code_scanner_page.dart';
import 'package:zichat/pages/money_qrcode_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('chat_messages');
  runApp(const MyApp());
}

void _showChatsQuickActions(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (sheetContext) {
      Widget buildItem({
        required String label,
        required String icon,
        VoidCallback? onTap,
      }) {
        Widget leading;
        if (icon.endsWith('.svg')) {
          leading = SvgPicture.asset(
            icon,
            width: 22,
            height: 22,
          );
        } else {
          leading = Image.asset(
            icon,
            width: 22,
            height: 22,
            fit: BoxFit.cover,
          );
        }
        return ListTile(
          leading: leading,
          title: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          onTap: () {
            Navigator.of(sheetContext).pop();
            if (onTap != null) {
              onTap();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label 功能暂未开放')),
              );
            }
          },
        );
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildItem(
              label: '发起群聊',
              icon: 'assets/icon/common/plus.svg',
            ),
            buildItem(
              label: '加入群聊',
              icon: 'assets/icon/common/plus.svg',
            ),
            buildItem(
              label: '添加朋友',
              icon: 'assets/icon/add-friend.svg',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddContactsPage()),
                );
              },
            ),
            buildItem(
              label: '扫一扫',
              icon: 'assets/icon/discover/scan-v2.jpeg',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CodeScannerPage()),
                );
              },
            ),
            buildItem(
              label: '收付款',
              icon: 'assets/icon/discover/qrcode.svg',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MoneyQrcodePage()),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZiChat',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF07C160),
          secondary: Color(0xFF07C160),
          surface: Color(0xFFF2F2F2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F7F7),
          foregroundColor: Color(0xFF1D2129),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D2129),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFF7F7F7),
          selectedItemColor: Color(0xFF07C160),
          unselectedItemColor: Color(0xFF86909C),
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
      home: const MyHomePage(title: 'ZiChat'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const ChatsPage();
      case 1:
        return const ContactsPage();
      case 2:
        return const DiscoverPage();
      case 3:
        return const MePage();
      default:
        return const ChatsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        top: true,
        bottom: true,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            color: Colors.white,
            child: Column(
              children: [
                _HomeHeader(currentIndex: _currentIndex),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOutCubic,
                      );
                      return FadeTransition(
                        opacity: curved,
                        child: child,
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentIndex),
                      child: _buildBody(),
                    ),
                  ),
                ),
                _HomeTabBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
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
    if (route.settings.name == Navigator.defaultRouteName) {
      return child;
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    final fade = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(curved);

    return FadeTransition(
      opacity: fade,
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
      action = IconButton(
        onPressed: () {
          _showChatsQuickActions(context);
        },
        icon: SvgPicture.asset(
          'assets/icon/circle-plus.svg',
          width: 22,
          height: 22,
        ),
      );
    } else if (currentIndex == 1) {
      title = '通讯录';
      action = IconButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddContactsPage()),
          );
        },
        icon: SvgPicture.asset(
          'assets/icon/add-friend.svg',
          width: 22,
          height: 22,
        ),
      );
    } else {
      title = '发现';
      action = IconButton(
        onPressed: () {},
        icon: SvgPicture.asset(
          'assets/icon/common/search.svg',
          width: 22,
          height: 22,
        ),
      );
    }

    return Container(
      height: 52,
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const SizedBox(width: 36, height: 36),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D2129),
                ),
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
        color: Color(0xFFF7F7F7),
        border: Border(
          top: BorderSide(color: Color(0xFFE5E6EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          _HomeTabItem(
            index: 0,
            currentIndex: currentIndex,
            label: '微信',
            iconAsset: 'assets/icon/tabs/chats.svg',
            iconActiveAsset: 'assets/icon/tabs/chats-active.svg',
            onTap: onTap,
          ),
          _HomeTabItem(
            index: 1,
            currentIndex: currentIndex,
            label: '通讯录',
            iconAsset: 'assets/icon/tabs/contacts.svg',
            iconActiveAsset: 'assets/icon/tabs/contacts-active.svg',
            onTap: onTap,
          ),
          _HomeTabItem(
            index: 2,
            currentIndex: currentIndex,
            label: '发现',
            iconAsset: 'assets/icon/tabs/discover.svg',
            iconActiveAsset: 'assets/icon/tabs/discover-active.svg',
            onTap: onTap,
          ),
          _HomeTabItem(
            index: 3,
            currentIndex: currentIndex,
            label: '我',
            iconAsset: 'assets/icon/tabs/me.svg',
            iconActiveAsset: 'assets/icon/tabs/me-active.svg',
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _HomeTabItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool active = index == currentIndex;
    const Color activeColor = Color(0xFF07C160);
    const Color inactiveColor = Color(0xFF86909C);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: SvgPicture.asset(
                active ? iconActiveAsset : iconAsset,
                width: 26,
                height: 26,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
