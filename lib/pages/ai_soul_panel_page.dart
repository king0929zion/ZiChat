import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/services/ai_soul_engine.dart';
import 'package:zichat/widgets/weui/weui.dart';

/// AI 灵魂控制面板
/// 
/// 显示 AI 当前的各种状态，包括：
/// - 精力/心情/压力数值
/// - 当前活动和事件
/// - 今日事件列表
/// - 短期记忆
/// - 亲密度等级
class AiSoulPanelPage extends StatefulWidget {
  const AiSoulPanelPage({super.key, required this.chatId});
  
  final String chatId;

  @override
  State<AiSoulPanelPage> createState() => _AiSoulPanelPageState();
}

class _AiSoulPanelPageState extends State<AiSoulPanelPage> {
  AiSoulState? _state;
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _loadState();
    // 每10秒刷新一次
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadState();
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  void _loadState() {
    setState(() {
      _state = AiSoulEngine.instance.getCurrentState();
    });
  }
  
  Future<void> _triggerEvent() async {
    HapticFeedback.mediumImpact();
    
    // 尝试AI生成事件
    final aiEvent = await AiSoulEngine.instance.generateAiEvent();
    if (aiEvent != null) {
      if (!mounted) return;
      WeuiToast.show(context, message: '发生了：${aiEvent.description}');
    } else {
      // 使用预设事件
      AiSoulEngine.instance.triggerRandomEvent();
    }
    
    _loadState();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundChat,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundChat,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AiSoulEngine.profile.name),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(state),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                state?.currentActivity ?? '加载中',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadState,
          ),
        ],
      ),
      body: state == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基本信息卡片
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  
                  // 状态数值
                  _buildStatusCard(state),
                  const SizedBox(height: 16),
                  
                  // 时间感知
                  _buildTimeCard(state),
                  const SizedBox(height: 16),
                  
                  // 亲密度
                  _buildIntimacyCard(state),
                  const SizedBox(height: 16),
                  
                  // 当前事件
                  if (state.currentEvent != null) ...[
                    _buildCurrentEventCard(state.currentEvent!),
                    const SizedBox(height: 16),
                  ],
                  
                  // 今日事件
                  _buildTodayEventsCard(state),
                  const SizedBox(height: 16),
                  
                  // 短期记忆
                  _buildMemoryCard(state),
                  const SizedBox(height: 16),
                  
                  // 触发事件按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _triggerEvent,
                      icon: const Icon(Icons.casino),
                      label: const Text('触发随机事件'),
                      style: const ButtonStyle(
                        padding: MaterialStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
  
  Widget _buildProfileCard() {
    final profile = AiSoulEngine.profile;
    return _Card(
      title: '基本信息',
      icon: Icons.person,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('名字', profile.name),
          _InfoRow('身份', profile.role),
          _InfoRow('MBTI', profile.mbti),
          _InfoRow('生日', profile.birthDate),
          _InfoRow('核心价值观', profile.coreValues.join('、')),
        ],
      ),
    );
  }
  
  Widget _buildStatusCard(AiSoulState state) {
    return _Card(
      title: '状态数值',
      icon: Icons.favorite,
      child: Column(
        children: [
          _StatusBar(
            label: '精力',
            value: state.energy,
            maxValue: 100,
            color: _getEnergyColor(state.energy),
            icon: Icons.bolt,
          ),
          const SizedBox(height: 12),
          _StatusBar(
            label: '心情',
            value: state.mood + 50, // 转换为0-100
            maxValue: 100,
            color: _getMoodColor(state.mood),
            icon: Icons.mood,
            showSign: true,
            actualValue: state.mood,
          ),
          const SizedBox(height: 12),
          _StatusBar(
            label: '压力',
            value: state.stress,
            maxValue: 100,
            color: _getStressColor(state.stress),
            icon: Icons.psychology,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeCard(AiSoulState state) {
    final time = state.timeAwareness;
    return _Card(
      title: '时空感知',
      icon: Icons.access_time,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('时段', '${time.period}${time.isWeekend ? " (周末)" : ""}'),
          _InfoRow('状态', time.sleepState),
          _InfoRow('精力修正', '${time.energyModifier >= 0 ? "+" : ""}${time.energyModifier.toInt()}'),
          _InfoRow('心情修正', '${time.moodModifier >= 0 ? "+" : ""}${time.moodModifier.toInt()}'),
          _InfoRow('上次互动', _formatTime(state.lastInteraction)),
        ],
      ),
    );
  }
  
  Widget _buildIntimacyCard(AiSoulState state) {
    final intimacy = AiSoulEngine.instance.getIntimacy(widget.chatId);
    final level = AiSoulEngine.instance.getIntimacyLevel(widget.chatId);
    
    return _Card(
      title: '亲密度',
      icon: Icons.favorite_border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getIntimacyLevelName(level),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getIntimacyColor(level),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getIntimacyDescription(level),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getIntimacyColor(level).withValues(alpha: 0.1),
                  border: Border.all(
                    color: _getIntimacyColor(level),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${intimacy.toInt()}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getIntimacyColor(level),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: intimacy / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(_getIntimacyColor(level)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCurrentEventCard(LifeEvent event) {
    return _Card(
      title: '当前事件',
      icon: Icons.event,
      color: Colors.orange[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.description,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ChangeChip('精力', event.energyChange),
              const SizedBox(width: 8),
              _ChangeChip('心情', event.moodChange),
              const SizedBox(width: 8),
              _ChangeChip('压力', event.stressChange),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTodayEventsCard(AiSoulState state) {
    return _Card(
      title: '今日事件 (${state.todayEvents.length})',
      icon: Icons.list_alt,
      child: state.todayEvents.isEmpty
          ? Text('今天还没发生什么事', style: TextStyle(color: AppColors.textSecondary))
          : Column(
              children: state.todayEvents.reversed.take(5).map((event) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        event.moodChange > 0 ? Icons.sentiment_satisfied : 
                        event.moodChange < 0 ? Icons.sentiment_dissatisfied :
                        Icons.sentiment_neutral,
                        size: 20,
                        color: event.moodChange > 0 ? Colors.green : 
                               event.moodChange < 0 ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
  
  Widget _buildMemoryCard(AiSoulState state) {
    return _Card(
      title: '短期记忆 (${state.shortTermMemory.length})',
      icon: Icons.memory,
      child: state.shortTermMemory.isEmpty
          ? Text('暂无记忆', style: TextStyle(color: AppColors.textSecondary))
          : Column(
              children: state.shortTermMemory.reversed.take(5).map((memory) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTimeShort(memory.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          memory.content,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
  
  // ==================== 辅助方法 ====================
  
  Color _getStatusColor(AiSoulState? state) {
    if (state == null) return Colors.grey;
    if (state.isAsleep) return Colors.indigo;
    if (state.energy < 30) return Colors.orange;
    if (state.mood < -20) return Colors.red;
    if (state.mood > 20) return Colors.green;
    return AppColors.primary;
  }
  
  Color _getEnergyColor(double energy) {
    if (energy >= 70) return Colors.green;
    if (energy >= 40) return Colors.orange;
    return Colors.red;
  }
  
  Color _getMoodColor(double mood) {
    if (mood >= 20) return Colors.green;
    if (mood >= -20) return Colors.blue;
    return Colors.red;
  }
  
  Color _getStressColor(double stress) {
    if (stress <= 30) return Colors.green;
    if (stress <= 60) return Colors.orange;
    return Colors.red;
  }
  
  Color _getIntimacyColor(IntimacyLevel level) {
    switch (level) {
      case IntimacyLevel.stranger: return Colors.grey;
      case IntimacyLevel.acquaintance: return Colors.blue;
      case IntimacyLevel.friend: return Colors.green;
      case IntimacyLevel.bestFriend: return Colors.pink;
    }
  }
  
  String _getIntimacyLevelName(IntimacyLevel level) {
    switch (level) {
      case IntimacyLevel.stranger: return '陌生人';
      case IntimacyLevel.acquaintance: return '普通朋友';
      case IntimacyLevel.friend: return '好朋友';
      case IntimacyLevel.bestFriend: return '死党';
    }
  }
  
  String _getIntimacyDescription(IntimacyLevel level) {
    switch (level) {
      case IntimacyLevel.stranger: return '保持礼貌距离，说话比较正式';
      case IntimacyLevel.acquaintance: return '偶尔开玩笑，相对随意';
      case IntimacyLevel.friend: return '很亲近，会主动分享';
      case IntimacyLevel.bestFriend: return '无话不说，可能会毒舌';
    }
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
  
  String _formatTimeShort(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// ==================== 组件 ====================

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.icon,
    required this.child,
    this.color,
  });
  
  final String title;
  final IconData icon;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: AppStyles.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.icon,
    this.showSign = false,
    this.actualValue,
  });
  
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final IconData icon;
  final bool showSign;
  final double? actualValue;

  @override
  Widget build(BuildContext context) {
    final displayValue = showSign && actualValue != null
        ? '${actualValue! >= 0 ? "+" : ""}${actualValue!.toInt()}'
        : '${value.toInt()}';
    
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / maxValue,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            displayValue,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChangeChip extends StatelessWidget {
  const _ChangeChip(this.label, this.value);
  
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final isPositive = value > 0;
    final isNegative = value < 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green[50] : 
               isNegative ? Colors.red[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label ${isPositive ? "+" : ""}${value.toInt()}',
        style: TextStyle(
          fontSize: 12,
          color: isPositive ? Colors.green[700] : 
                 isNegative ? Colors.red[700] : Colors.grey[600],
        ),
      ),
    );
  }
}

