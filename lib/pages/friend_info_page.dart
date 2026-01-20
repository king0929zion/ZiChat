import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/widgets/weui/weui.dart';

class FriendInfoPage extends StatelessWidget {
  const FriendInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF2F2F2);

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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildProfileCard(),
                        const SizedBox(height: 12),
                        _buildActionCard(context),
                      ],
                    ),
                  ),
                ),
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
      color: const Color(0xFFF2F2F2),
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
                '好友资料',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D2129),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 36,
            height: 36,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
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
              children: const [
                _NameRow(),
                SizedBox(height: 4),
                Text(
                  '微信号：Zion_mu',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8A8F99),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '个性签名：Hi I want to add u',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1D1F23),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          SizedBox(
              height: 46,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                WeuiToast.show(context, message: '已通过验证');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF07C160),
                  foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '通过验证',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
              height: 46,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                WeuiToast.show(context, message: '备注功能暂未开放');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDCDCDC)),
                  foregroundColor: const Color(0xFF1D1F23),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '设置备注和标签',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
              height: 46,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                WeuiToast.show(context, message: '已拒绝该好友');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF4D4F)),
                  foregroundColor: const Color(0xFFFF4D4F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '拒绝',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'ZION.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D1F23),
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
    );
  }
}
