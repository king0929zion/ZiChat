import 'package:flutter/material.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/pages/moments_page.dart';
import 'package:zichat/pages/code_scanner_page.dart';
import 'package:zichat/widgets/weui/weui.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    void showTodo() => WeuiToast.show(context, message: '功能开发中');

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

    final groups = <List<_DiscoverCard>>[];
    var currentGroup = <_DiscoverCard>[];
    for (final item in items) {
      currentGroup.add(item);
      if (item.dividerAfter) {
        groups.add(currentGroup);
        currentGroup = <_DiscoverCard>[];
      }
    }
    if (currentGroup.isNotEmpty) {
      groups.add(currentGroup);
    }

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          for (final group in groups)
            WeuiCellGroup(
              children: [
                for (final item in group)
                  WeuiCell(
                    title: item.title,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        item.image,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                      ),
                    ),
                    onTap: item.onTap ?? showTodo,
                  ),
              ],
            ),
        ],
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
