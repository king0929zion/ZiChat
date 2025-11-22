import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchInput(),
                        const SizedBox(height: 12),
                        const Text(
                          '可搜索：手机号、微信号',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8A8F99),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildResultList(),
                        ),
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
                '添加朋友',
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

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icon/common/search.svg',
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '微信号/手机号',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8A8F99),
                ),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              '输入手机号或微信号进行搜索',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF1D1F23),
              ),
            ),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              '未找到相关用户',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF1D1F23),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: ListView.separated(
        itemCount: _results.length,
        separatorBuilder: (_, __) => const Divider(
          height: 0,
          color: Color(0xFFF0F0F0),
        ),
        itemBuilder: (context, index) {
          final user = _results[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
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
                          color: Color(0xFF1D1F23),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '微信号：${user.wechatId}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8A8F99),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已发送好友验证申请')),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    side: const BorderSide(color: Color(0xFF07C160)),
                    foregroundColor: const Color(0xFF07C160),
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
