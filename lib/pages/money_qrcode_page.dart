import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/widgets/weui/weui.dart';

class MoneyQrcodePage extends StatefulWidget {
  const MoneyQrcodePage({super.key});

  @override
  State<MoneyQrcodePage> createState() => _MoneyQrcodePageState();
}

class _MoneyQrcodePageState extends State<MoneyQrcodePage> {
  bool _isReceive = true; // true: 收款, false: 付款
  final TextEditingController _controller = TextEditingController();

  String get _hintText => _isReceive
      ? '对方扫码向你付款'
      : '你可扫码向商户付款';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAmountChanged(String raw) {
    String val = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = val.split('.');
    if (parts.length > 2) {
      val = '${parts[0]}.${parts.sublist(1).join('')}';
    }
    if (parts.length > 1 && parts[1].length > 2) {
      val = '${parts[0]}.${parts[1].substring(0, 2)}';
    }
    if (val != _controller.text) {
      final selectionIndex = val.length;
      _controller
        ..text = val
        ..selection = TextSelection.collapsed(offset: selectionIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('收付款'),
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
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                _buildToggle(),
                const SizedBox(height: 12),
                _buildCard(),
                const SizedBox(height: 12),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    Widget buildBtn(String text, bool active, VoidCallback onTap) {
      return Expanded(
        child: Material(
          color: active ? AppColors.surface : AppColors.background,
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            highlightColor: AppColors.disabledBg,
            splashColor: Colors.transparent,
            child: Container(
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: active ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildBtn('收款', _isReceive, () {
          setState(() => _isReceive = true);
        }),
        const SizedBox(width: 10),
        buildBtn('付款', !_isReceive, () {
          setState(() => _isReceive = false);
        }),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: AppStyles.shadowSmall,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
              color: AppColors.background,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/icon/discover/qrcode.svg',
              width: 160,
              height: 160,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '金额',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  const Text(
                    '¥',
                    style: TextStyle(
                      fontSize: 22,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _controller,
                      onChanged: _onAmountChanged,
                      textAlign: TextAlign.right,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: '0.00',
                      ),
                      style: const TextStyle(
                        fontSize: 26,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _hintText,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    void show(String text) {
      WeuiToast.show(context, message: text);
    }

    final labelSave = _isReceive ? '保存收款码' : '保存付款码';
    final labelShare = _isReceive ? '分享收款码' : '分享付款码';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WeuiButton(
          label: labelSave,
          onPressed: () => show('已模拟保存二维码'),
          type: WeuiButtonType.primary,
        ),
        const SizedBox(height: 10),
        WeuiButton(
          label: labelShare,
          onPressed: () => show('分享功能暂未开放'),
          type: WeuiButtonType.defaultType,
        ),
      ],
    );
  }
}
