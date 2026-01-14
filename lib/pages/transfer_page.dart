import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/utils/cupertino_toast.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  String _amount = '';
  final TextEditingController _amountController = TextEditingController();

  double get _amountValue => double.tryParse(_amount) ?? 0;

  void _syncAmountText() {
    _amountController
      ..text = _amount
      ..selection = TextSelection.collapsed(offset: _amount.length);
  }

  @override
  void initState() {
    super.initState();
    _syncAmountText();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _append(String value) {
    setState(() {
      if (value == '.') {
        if (_amount.contains('.')) return;
        if (_amount.isEmpty) {
          _amount = '0.';
          return;
        }
      } else {
        if (_amount.contains('.')) {
          final parts = _amount.split('.');
          final decimals = parts.length > 1 ? parts[1] : '';
          if (decimals.length >= 2) return;
        }
        if (_amount.length >= 10) return;
        if (_amount == '0') {
          _amount = value;
          return;
        }
      }
      _amount += value;
    });
    _syncAmountText();
  }

  void _delete() {
    if (_amount.isEmpty) return;
    setState(() {
      _amount = _amount.substring(0, _amount.length - 1);
    });
    _syncAmountText();
  }

  Future<void> _submit() async {
    if (_amountValue <= 0) {
      CupertinoToast.show(context, '请输入转账金额');
      return;
    }

    final bool? ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PayConfirmDialog(amount: _amountValue),
    );

    if (ok != true) return;

    // 将金额返回给上一个页面，由聊天页面负责插入转账消息
    if (mounted) {
      Navigator.of(context).pop(_amountValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFEFEFEF);

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
                _buildTopBar(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Column(
                      children: [
                        const _ReceiverRow(),
                        const SizedBox(height: 4),
                        _buildAmountPanel(),
                        const Spacer(),
                        _buildKeyboard(),
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

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.of(context).pop(),
        icon: SvgPicture.asset(
          'assets/icon/common/go-back.svg',
          width: 14,
          height: 24,
          colorFilter: const ColorFilter.mode(
            Color(0xFF1D2129),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            offset: Offset(0, -1),
            blurRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '转账金额',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2B2B2B),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE6E6E6),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '¥',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: TextField(
                      controller: _amountController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      cursorColor: Color(0xFF07C160),
                      cursorWidth: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              CupertinoToast.show(context, '添加说明功能暂未开放');
            },
            child: const Text(
              '添加转账说明',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF3B5B8A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    const double rowHeight = 60;
    const double vGap = 8;
    const double keyboardHeight = rowHeight * 4 + vGap * 3;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      color: const Color(0xFFF6F6F6),
      child: SizedBox(
        height: keyboardHeight,
        child: Row(
          children: [
            // 左侧数字网格 4 行 x 3 列
            Expanded(
              child: Column(
                children: [
                  _buildNumberRow(const ['1', '2', '3'], rowHeight),
                  const SizedBox(height: vGap),
                  _buildNumberRow(const ['4', '5', '6'], rowHeight),
                  const SizedBox(height: vGap),
                  _buildNumberRow(const ['7', '8', '9'], rowHeight),
                  const SizedBox(height: vGap),
                  _buildLastRow(rowHeight),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 右侧删除 + 转账列
            SizedBox(
              width: 96,
              child: SizedBox(
                height: keyboardHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: rowHeight,
                      child: _buildDeleteButton(),
                    ),
                    const SizedBox(height: vGap),
                    Expanded(
                      child: _buildPayButton(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberRow(List<String> values, double rowHeight) {
    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          for (int i = 0; i < values.length; i++) ...[
            Expanded(
              child: values[i].isEmpty
                  ? const SizedBox.shrink()
                  : _buildKeyButton(values[i]),
            ),
            if (i != values.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildLastRow(double rowHeight) {
    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildKeyButton('0'),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: _buildKeyButton('.'),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyButton(String value) {
    final bool isBlank = value.isEmpty;
    if (isBlank) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _append(value),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: const Border.fromBorderSide(
              BorderSide(color: Color(0xFFEDEDED)),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF000000),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _delete,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: const Border.fromBorderSide(
              BorderSide(color: Color(0xFFEDEDED)),
            ),
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icon/common/close.svg',
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              Color(0xA6000000),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          _submit();
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2EAF61),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Text(
            '转账',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _PayConfirmDialog extends StatefulWidget {
  const _PayConfirmDialog({
    required this.amount,
  });

  final double amount;

  @override
  State<_PayConfirmDialog> createState() => _PayConfirmDialogState();
}

class _PayConfirmDialogState extends State<_PayConfirmDialog> {
  String _password = '';

  void _appendNumber(String value) {
    if (_password.length >= 6) return;
    setState(() {
      _password += value;
    });
    if (_password.length == 6) {
      _onComplete();
    }
  }

  void _delete() {
    if (_password.isEmpty) return;
    setState(() {
      _password = _password.substring(0, _password.length - 1);
    });
  }

  void _onComplete() {
    Future.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      if (_password == '123456') {
        Navigator.of(context).pop(true);
      } else {
        CupertinoToast.show(context, '支付密码错误');
        setState(() {
          _password = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCloseButton(context),
                _buildHeader(),
                _buildDivider(),
                _buildPaymentMethodRow(),
                const SizedBox(height: 4),
                _buildPasswordBoxes(),
                const SizedBox(height: 12),
                _buildPasswordKeyboard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        iconSize: 24,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        onPressed: () => Navigator.of(context).pop(false),
        icon: const Icon(
          Icons.close,
          color: Color(0xFF4E5969),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '向 ZION. 转账',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF1D2129),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¥${widget.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D2129),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: const Color(0xFFEDEDED),
    );
  }

  Widget _buildPaymentMethodRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '支付方式',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF86909C),
            ),
          ),
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFF6C94A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '零钱',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF86909C),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_right,
                size: 16,
                color: Color(0xFF86909C),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordBoxes() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          final bool filled = index < _password.length;
          return Container(
            width: 48,
            height: 48,
            margin: EdgeInsets.only(right: index == 5 ? 0 : 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFFE5E6EB),
                width: 1,
              ),
            ),
            child: Center(
              child: filled
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1D2129),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPasswordKeyboard() {
    const double keyHeight = 52;
    const double gap = 0.5;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEDEDED),
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildKeyboardRow(const ['1', '2', '3'], keyHeight),
          const SizedBox(height: gap),
          _buildKeyboardRow(const ['4', '5', '6'], keyHeight),
          const SizedBox(height: gap),
          _buildKeyboardRow(const ['7', '8', '9'], keyHeight),
          const SizedBox(height: gap),
          _buildKeyboardRow(const ['', '0', 'del'], keyHeight),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> values, double keyHeight) {
    return SizedBox(
      height: keyHeight,
      child: Row(
        children: [
          for (int i = 0; i < values.length; i++) ...[
            Expanded(
              child: _buildKey(values[i]),
            ),
            if (i != values.length - 1)
              const SizedBox(
                width: 0.5,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildKey(String value) {
    if (value.isEmpty) {
      return Container(color: Colors.transparent);
    }

    final bool isDelete = value == 'del';

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: isDelete ? _delete : () => _appendNumber(value),
        child: Center(
          child: isDelete
              ? const Icon(
                  Icons.backspace_outlined,
                  size: 24,
                  color: Color(0xFF999999),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xFF000000),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ReceiverRow extends StatelessWidget {
  const _ReceiverRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '转账给 ZION.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ID: Zion_mu',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B6F7B),
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/bella.jpeg',
              width: 52,
              height: 52,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
