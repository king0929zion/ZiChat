import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/pages/my_qrcode_page.dart';
import 'package:zichat/services/user_data_manager.dart';
import 'package:zichat/services/avatar_utils.dart';
import 'package:zichat/pages/me/edit_text_page.dart';
import 'package:zichat/pages/me/edit_gender_page.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> with WidgetsBindingObserver {
  late UserProfile _profile;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    WidgetsBinding.instance.addObserver(this);
    UserDataManager.instance.addListener(_onUserDataChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    UserDataManager.instance.removeListener(_onUserDataChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadProfile();
    }
  }

  void _onUserDataChanged() {
    if (mounted) {
      _loadProfile();
    }
  }

  void _loadProfile() {
    setState(() {
      _profile = UserDataManager.instance.profile;
    });
  }

  Future<void> _updateAvatar() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAvatarActionSheet(),
    );
  }

  Widget _buildAvatarActionSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEFEFF4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionItem('从手机相册选择', onTap: () {
              Navigator.pop(context);
              _pickImage();
            }),
            const Divider(height: 0.5, color: Color(0xFFE0E0E0)),
            _buildActionItem('查看上一张头像', onTap: () {
              Navigator.pop(context);
              // TODO: implement view previous avatar
            }),
            const Divider(height: 0.5, color: Color(0xFFE0E0E0)),
            _buildActionItem('保存到手机', onTap: () {
              Navigator.pop(context);
              // TODO: implement save to gallery
            }),
            const SizedBox(height: 8),
            _buildActionItem('取消', onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(String title, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          width: double.infinity,
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // 保存图片到应用目录
        final savedPath = await AvatarUtils.saveImageToAppDir(
          File(image.path),
          AvatarUtils.generateAvatarFileName(),
        );
        // 更新头像（会自动触发 UI 刷新）
        await UserDataManager.instance.updateAvatar(savedPath);
      }
    } catch (e) {
      debugPrint('选择头像失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('选择头像失败')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _editName() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTextPage(
          title: '更改名字',
          initialValue: _profile.name,
          maxLength: 20,
          description: '好名字可以让你的朋友更容易记住你。',
        ),
      ),
    );
    if (result != null && result is String) {
      await UserDataManager.instance.updateName(result);
    }
  }

  void _editGender() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditGenderPage(initialGender: _profile.gender),
      ),
    );
    if (result != null && result is String) {
      await UserDataManager.instance.updateGender(result);
    }
  }

  void _editSignature() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTextPage(
          title: '个性签名',
          initialValue: _profile.signature,
          maxLength: 30,
          description: '',
        ),
      ),
    );
    if (result != null && result is String) {
      await UserDataManager.instance.updateSignature(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context, true), // Return true to refresh parent
        ),
        title: const Text('个人信息', style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSection([
             _ProfileItem(
              label: '头像',
              isLast: false,
              trailing: _buildAvatar(),
              onTap: _updateAvatar,
              height: 70,
            ),
            _ProfileItem(
              label: '名字',
              isLast: false,
              trailingText: _profile.name,
              onTap: _editName,
            ),
            _ProfileItem(
              label: '性别',
              isLast: false,
              trailingText: _profile.gender,
              onTap: _editGender,
            ),
             _ProfileItem(
              label: '地区',
              isLast: true,
              trailingText: _profile.region,
              onTap: () {}, // TODO
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection([
             const _ProfileItem(
              label: '手机号',
              isLast: false,
              trailingText: '+86 138****0000', // Mock
              onTap: null, // Usually read only navigation
            ),
             _ProfileItem(
              label: 'ID',
              isLast: false,
              trailingText: _profile.wechatId, // Usually read only or limited edit
              onTap: null,
            ),
             _ProfileItem(
              label: '我的二维码',
              isLast: false,
              trailing: SvgPicture.asset('assets/icon/qr-code.svg', width: 18),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyQrcodePage())),
            ),
             _ProfileItem(
              label: '拍一拍',
              isLast: false,
              trailing: const Icon(Icons.star_rate_rounded, color: Color(0xFFEEAA4D), size: 18), // Mock icon
              onTap: () {},
            ),
             _ProfileItem(
              label: '签名',
              isLast: true,
              trailingText: _profile.signature.isEmpty ? '未填写' : _profile.signature,
              onTap: _editSignature,
            ),
          ]),
          const SizedBox(height: 12),
           _buildSection([
            const _ProfileItem(
              label: '来电铃声',
              isLast: true,
              trailing: null,
              onTap: null,
            ),
           ]),
           const SizedBox(height: 12),
           _buildSection([
            const _ProfileItem(
              label: '我的地址',
              isLast: true,
              trailing: null,
              onTap: null,
            ),
           ]),
            const SizedBox(height: 12),
           _buildSection([
            const _ProfileItem(
              label: '我的发票抬头',
              isLast: true,
              trailing: null,
              onTap: null,
            ),
           ]),
           const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return AvatarUtils.buildAvatarWidget(
      _profile.avatar,
      size: 48,
      borderRadius: 6,
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16),
      child: Column(children: children),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.label,
    required this.isLast,
    this.trailing,
    this.trailingText,
    this.onTap,
    this.height = 56,
  });

  final String label;
  final bool isLast;
  final Widget? trailing;
  final String? trailingText;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5)),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 16, color: Colors.black)),
            const Spacer(),
            if (trailingText != null)
              Text(
                trailingText!,
                style: const TextStyle(fontSize: 16, color: Color(0xFF7F7F7F)),
              ),
            if (trailing != null) trailing!,
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/icon/common/arrow-right.svg',
              width: 8,
              height: 14,
              colorFilter: const ColorFilter.mode(Color(0xFFC7C7CC), BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }
}
