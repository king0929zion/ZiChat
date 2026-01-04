import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/pages/moments_page.dart';
import 'package:zichat/pages/code_scanner_page.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFEDEDED);
    const Color arrowColor = Color(0x4D000000); // HTML: opacity: 0.3

    Widget buildItem(_DiscoverCard item) {
      return InkWell(
        onTap: item.onTap,
        child: SizedBox(
          height: 56,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    item.image,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Color(0xFF1D2129),
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icon/common/arrow-right.svg',
                  width: 8,
                  height: 14,
                  colorFilter:
                      const ColorFilter.mode(arrowColor, BlendMode.srcIn),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildDivider() => Container(height: 8, color: bg);

    final List<_DiscoverCard> items = [
      _DiscoverCard(
        title: '朋友圈', // HTML: 朋友圈
        image: 'assets/icon/discover/moments.jpeg',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MomentsPage(),
            ),
          );
        },
        dividerAfter: true,
      ),
      _DiscoverCard(
        title: '视频号', // HTML: 视频号
        image: 'assets/icon/discover/channels.jpeg',
      ),
      _DiscoverCard(
        title: '直播', // HTML: 直播
        image: 'assets/icon/discover/live.jpeg',
        dividerAfter: true,
      ),
      _DiscoverCard(
        title: '扫一扫', // HTML: 扫一扫
        image: 'assets/icon/discover/scan-v2.jpeg',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CodeScannerPage(),
            ),
          );
        },
      ),
      _DiscoverCard(
        title: '摇一摇', // HTML: 摇一摇
        image: 'assets/icon/discover/shake.jpeg',
        dividerAfter: true,
      ),
      _DiscoverCard(
        title: '看一看', // HTML: 看一看
        image: 'assets/icon/discover/top-stories.jpeg',
      ),
      _DiscoverCard(
        title: '搜一搜', // HTML: 搜一搜
        image: 'assets/icon/discover/search.jpeg',
        dividerAfter: true,
      ),
      _DiscoverCard(
        title: '附近', // HTML: 附近
        image: 'assets/icon/discover/nearby.jpeg',
        dividerAfter: true,
      ),
      _DiscoverCard(
        title: '游戏', // HTML: 游戏
        image: 'assets/icon/discover/games.jpeg',
        dividerAfter: true,
      ),
      _DiscoverCard(
        title: '小程序', // HTML: 小程序
        image: 'assets/icon/discover/mini-programs.jpeg',
      ),
    ];

    return SizedBox.expand(
      child: Container(
        color: bg,
        child: ListView.builder(
        itemCount: items.length * 2 + 1,
        itemBuilder: (context, index) {
          if (index == 0) return buildDivider();
          if (index.isOdd) {
            final card = items[(index - 1) ~/ 2];
            return buildItem(card);
          }
          final prev = items[(index - 2) ~/ 2];
          return prev.dividerAfter ? buildDivider() : const SizedBox.shrink();
        },
      ),
      ),
    );
  }
}

class _DiscoverCard {
  const _DiscoverCard({
    required this.title,
    required this.image,
    this.dividerAfter = false,
    this.onTap,
  });

  final String title;
  final String image;
  final bool dividerAfter;
  final VoidCallback? onTap;
}
