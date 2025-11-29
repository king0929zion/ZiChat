import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/models/chat_message.dart';
import 'base_bubble.dart';

/// 语音消息气泡
class VoiceBubble extends StatefulWidget {
  const VoiceBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
    this.onTap,
  });

  final ChatMessage message;
  final bool isOutgoing;
  final VoidCallback? onTap;

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _playingController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _playingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _playingController.dispose();
    super.dispose();
  }

  int _parseDuration(String? source) {
    if (source == null || source.isEmpty) return 1;
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(source);
    if (match == null) return 1;
    final value = double.tryParse(match.group(0) ?? '1') ?? 1;
    final result = value.round();
    return result <= 0 ? 1 : result;
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _playingController.repeat();
    } else {
      _playingController.stop();
      _playingController.reset();
    }

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _parseDuration(widget.message.duration);
    final int width = duration < 6 ? 90 + duration * 8 : 200;
    final Color bgColor = widget.isOutgoing
        ? AppColors.bubbleOutgoing
        : AppColors.bubbleIncoming;

    return TappableBubble(
      onTap: _handleTap,
      child: SizedBox(
        width: width.toDouble(),
        child: BaseBubble(
          backgroundColor: bgColor,
          isOutgoing: widget.isOutgoing,
          child: Row(
            mainAxisAlignment: widget.isOutgoing
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!widget.isOutgoing) ...[
                _buildVoiceIcon(),
                const SizedBox(width: 8),
                Text(
                  '$duration"',
                  style: AppStyles.bodyMedium,
                ),
              ],
              if (widget.isOutgoing) ...[
                Text(
                  '$duration"',
                  style: AppStyles.bodyMedium,
                ),
                const SizedBox(width: 8),
                _buildVoiceIcon(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceIcon() {
    return AnimatedBuilder(
      animation: _playingController,
      builder: (context, child) {
        final opacity = _isPlaying
            ? 0.3 + 0.7 * (0.5 + 0.5 * math.sin(_playingController.value * 2 * math.pi).abs())
            : 1.0;
        return Opacity(
          opacity: opacity,
          child: SvgPicture.asset(
            AppAssets.iconVoiceRecord,
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcIn,
            ),
          ),
        );
      },
    );
  }
}
