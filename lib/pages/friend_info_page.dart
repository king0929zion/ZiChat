import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/widgets/weui/weui.dart';

class FriendInfoPage extends StatelessWidget {
  const FriendInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: SvgPicture.asset(
            AppAssets.iconGoBack,
            width: 12,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
        title: const Text('好友资料'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          WeuiCellGroup(
            inset: true,
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(12),
            children: const [
              _FriendProfileCard(),
            ],
          ),
          const SizedBox(height: 8),
          WeuiCellGroup(
            inset: true,
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  children: [
                    WeuiButton(
                      label: '通过验证',
                      onPressed: () => WeuiToast.show(context, message: '已通过验证'),
                      type: WeuiButtonType.primary,
                    ),
                    const SizedBox(height: 10),
                    WeuiButton(
                      label: '设置备注和标签',
                      onPressed: () => WeuiToast.show(context, message: '备注功能暂未开放'),
                      type: WeuiButtonType.defaultType,
                    ),
                    const SizedBox(height: 10),
                    WeuiButton(
                      label: '拒绝',
                      onPressed: () => WeuiToast.show(context, message: '已拒绝该好友'),
                      type: WeuiButtonType.warn,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendProfileCard extends StatelessWidget {
  const _FriendProfileCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/bella.jpeg',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ZION.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x26FF9B57),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '等待验证',
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
                  '微信号：Zion_mu',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '个性签名：Hi I want to add u',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

