import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/utils/cupertino_toast.dart';

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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildToggle(),
                        const SizedBox(height: 14),
                        _buildCard(),
                        const SizedBox(height: 14),
                        _buildActions(context),
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
                '收付款',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D2129),
                ),
              ),
            ),
          ),
          const SizedBox(width: 36, height: 36),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    Widget buildBtn(String text, bool active, VoidCallback onTap) {
      return TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: active ? Colors.white : const Color(0xFFF7F7F7),
          foregroundColor: active ? const Color(0xFF07C160) : const Color(0xFF1D1F23),
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: active ? const Color(0xFF07C160) : const Color(0xFFDCDCDC),
            ),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 15),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: buildBtn('收款', _isReceive, () {
            setState(() => _isReceive = true);
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: buildBtn('付款', !_isReceive, () {
            setState(() => _isReceive = false);
          }),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
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
              border: Border.all(color: const Color(0xFFE6E6E6)),
              color: const Color(0xFFFAFAFA),
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
                  color: Color(0xFF8A8F99),
                ),
              ),
              Row(
                children: [
                  const Text(
                    '¥',
                    style: TextStyle(
                      fontSize: 22,
                      color: Color(0xFF1D1F23),
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
                        color: Color(0xFF1D1F23),
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
              color: Color(0xFF8A8F99),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    void show(String text) {
      CupertinoToast.show(context, text);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 46,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF07C160),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => show('已模拟保存收款码'),
            child: const Text(
              '保存收款码',
              style: TextStyle(fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1D1F23),
              side: const BorderSide(color: Color(0xFFDCDCDC)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => show('分享收款码功能暂未开放'),
            child: const Text(
              '分享收款码',
              style: TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}
