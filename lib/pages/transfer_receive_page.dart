import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/utils/cupertino_toast.dart';

class TransferReceivePage extends StatefulWidget {
  const TransferReceivePage({
    super.key,
    this.amount = '0.01',
    this.messageId,
    this.isAlreadyReceived = false,
  });

  final String amount;
  final String? messageId;
  final bool isAlreadyReceived;

  @override
  State<TransferReceivePage> createState() => _TransferReceivePageState();
}

class _TransferReceivePageState extends State<TransferReceivePage> {
  late final DateTime _transferTime;
  DateTime? _receiveTime;
  late bool _received;

  @override
  void initState() {
    super.initState();
    _transferTime = DateTime.now();
    _received = widget.isAlreadyReceived;
    if (_received) {
      _receiveTime = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Colors.white;
    final bool isReceived = _received;
    final String title =
        isReceived ? '你已收款，资金已存入零钱' : '待你收款';

    final List<Widget> children = [
      _buildHeader(context),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 56),
            _buildStatusIcon(isReceived),
            const SizedBox(height: 24),
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1D2129),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '¥${widget.amount}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
            ),
            if (isReceived) ...[
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '零钱余额',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF07C160),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Divider(
              height: 1,
              thickness: 0.5,
              color: Color(0xFFE5E5E5),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    '转账时间',
                    _formatCnDateTime(_transferTime),
                  ),
                  if (isReceived && _receiveTime != null)
                    _buildInfoRow(
                      '收款时间',
                      _formatCnDateTime(_receiveTime!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];

    if (!isReceived) {
      children.add(_buildPendingBottom(context));
    }

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: IconButton(
        padding: const EdgeInsets.all(8),
        onPressed: () => Navigator.of(context).pop(),
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
    );
  }

  Widget _buildStatusIcon(bool isReceived) {
    if (isReceived) {
      return Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFF07C160),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 32,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF2BA3FF),
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.access_time,
            size: 32,
            color: Color(0xFF2BA3FF),
          ),
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8A8F99),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1D1F23),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBottom(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07C160),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: _onReceivePressed,
              child: const Text(
                '收款',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '1天内未确认，将退还给对方。退还',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  void _onReceivePressed() {
    setState(() {
      _received = true;
      _receiveTime = DateTime.now();
    });
    CupertinoToast.show(context, '已确认收款');
    // 返回收款成功状态和消息ID
    Navigator.of(context).pop({
      'received': true,
      'messageId': widget.messageId,
    });
  }

  String _formatCnDateTime(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}年${two(time.month)}月${two(time.day)}日 '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}
