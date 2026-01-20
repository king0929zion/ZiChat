import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/widgets/weui/weui.dart';

class AddContactsSearchPage extends StatefulWidget {
  const AddContactsSearchPage({super.key});

  @override
  State<AddContactsSearchPage> createState() => _AddContactsSearchPageState();
}

class _AddContactsSearchPageState extends State<AddContactsSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_SearchUser> _mock = const [
    _SearchUser(name: 'ZION.', wechatId: 'Zion_mu', avatar: 'assets/bella.jpeg'),
    _SearchUser(name: 'Bella', wechatId: 'bella_chen', avatar: 'assets/avatar.png'),
  ];

  List<_SearchUser> _results = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final val = _controller.text.trim();
    if (val.isEmpty) {
      setState(() {
        _results = const [];
      });
      return;
    }
    final lower = val.toLowerCase();
    setState(() {
      _results = _mock
          .where((u) =>
              u.name.toLowerCase().contains(lower) ||
              u.wechatId.toLowerCase().contains(lower))
          .toList();
    });
  }

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
        title: const Text('添加朋友', style: AppStyles.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchInput(),
                  const SizedBox(height: 10),
                  const Text('可搜索：手机号、微信号', style: AppStyles.caption),
                  const SizedBox(height: 12),
                  Expanded(child: _buildResultList()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SvgPicture.asset(
            AppAssets.iconSearch,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              AppColors.textHint,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => HapticFeedback.selectionClick(),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '微信号/手机号',
                hintStyle: AppStyles.hint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    final hasInput = _controller.text.trim().isNotEmpty;

    if (!hasInput) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
          border: Border.all(color: AppColors.border),
        ),
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              '输入手机号或微信号进行搜索',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
          border: Border.all(color: AppColors.border),
        ),
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              '未找到相关用户',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        itemCount: _results.length,
        separatorBuilder: (context, index) => const Divider(
          height: 0,
          color: AppColors.divider,
        ),
        itemBuilder: (context, index) {
          final user = _results[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                  child: Image.asset(
                    user.avatar,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '微信号：${user.wechatId}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    WeuiToast.show(context, message: '已发送好友验证申请');
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '添加',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SearchUser {
  const _SearchUser({
    required this.name,
    required this.wechatId,
    required this.avatar,
  });

  final String name;
  final String wechatId;
  final String avatar;
}
