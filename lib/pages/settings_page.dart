import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/pages/settings_general_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFF4),
      body: SafeArea(
        top: true,
        bottom: true,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            color: const Color(0xFFEFEFF4),
            child: Column(
              children: [
                _buildHeader(context),
                const Expanded(
                  child: _SettingsBody(),
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
      color: const Color(0xFFEFEFF4),
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
                '设置',
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
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _SettingsItem(label: '个人资料'),
        const _SettingsItem(label: '账号安全'),
        const _SettingsDivider(),
        const _SettingsItem(label: '未成年人模式'),
        const _SettingsItem(label: '关怀模式'),
        const _SettingsDivider(),
        const _SettingsItem(label: '通知'),
        const _SettingsItem(label: '聊天'),
        _SettingsItem(
          label: '通用',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SettingsGeneralPage(),
              ),
            );
          },
        ),
        const _SettingsDivider(),
        const _SettingsSectionTitle(label: '隐私'),
        const _SettingsItem(label: '朋友权限'),
        const _SettingsItem(label: '个人信息与权限'),
        const _SettingsDivider(),
        const _SettingsItem(label: '关于微信'),
        const _SettingsItem(label: '帮助与反馈'),
        const _SettingsDivider(),
        const _SwitchAccountButton(),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE5E6EB),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                color: Color(0xFF1D2129),
              ),
            ),
            SvgPicture.asset(
              'assets/icon/common/arrow-right.svg',
              width: 12,
              height: 12,
              colorFilter: const ColorFilter.mode(
                Colors.black26,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      color: const Color(0xFFEDEDED),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      color: const Color(0xFFEDEDED),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF86909C),
        ),
      ),
    );
  }
}

class _SwitchAccountButton extends StatelessWidget {
  const _SwitchAccountButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          padding: EdgeInsets.zero,
          minimumSize: const Size.fromHeight(56),
        ),
        child: const Text(
          '切换账号',
          style: TextStyle(
            fontSize: 17,
            color: Color(0xFF1D2129),
          ),
        ),
      ),
    );
  }
}
