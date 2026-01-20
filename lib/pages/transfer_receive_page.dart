import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/widgets/weui/weui.dart';

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
    final bg = AppColors.surface;
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
                  color: AppColors.textPrimary,
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
                  color: AppColors.textPrimary,
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
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            const Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.divider,
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
          AppAssets.iconGoBack,
          width: 12,
          height: 20,
          colorFilter: const ColorFilter.mode(
            AppColors.textPrimary,
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
            color: AppColors.primary,
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
              color: AppColors.link,
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.access_time,
            size: 32,
            color: AppColors.link,
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
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
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
          WeuiButton(
            label: '收款',
            onPressed: _onReceivePressed,
            type: WeuiButtonType.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            '1天内未确认，将退还给对方。退还',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
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
    WeuiToast.show(context, message: '已确认收款');
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
