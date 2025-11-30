import 'dart:math' as math;
import 'package:zichat/services/image_gen_service.dart';

/// AI 工具服务
/// 
/// 支持的工具：
/// - image_gen(prompt) - AI 生成图片
/// - transfer(amount) - 发起转账
/// - emoji(name) - 发送表情
/// 
/// 调用格式：<tool>工具名(参数)</tool>
class AiToolsService {
  static final _random = math.Random();
  
  /// 解析 AI 回复中的工具调用
  /// 格式: <tool>tool_name(param)</tool>
  static List<AiToolCall> parseToolCalls(String response) {
    final calls = <AiToolCall>[];
    
    // 匹配 <tool>xxx</tool> 格式
    final toolPattern = RegExp(r'<tool>(\w+)\(([^)]*)\)</tool>');
    
    for (final match in toolPattern.allMatches(response)) {
      final toolName = match.group(1)?.toLowerCase() ?? '';
      final param = match.group(2)?.trim() ?? '';
      
      switch (toolName) {
        case 'image_gen':
          if (param.isNotEmpty && ImageGenService.isAvailable) {
            calls.add(AiToolCall(
              type: AiToolType.generateImage,
              params: {'prompt': param},
            ));
          }
          break;
          
        case 'transfer':
          final amount = double.tryParse(param) ?? 0;
          if (amount > 0) {
            calls.add(AiToolCall(
              type: AiToolType.sendTransfer,
              params: {'amount': amount},
            ));
          }
          break;
          
        case 'emoji':
          if (param.isNotEmpty) {
            calls.add(AiToolCall(
              type: AiToolType.sendEmoji,
              params: {'emoji': param},
            ));
          }
          break;
      }
    }
    
    // 兼容旧格式 (无 <tool> 标签)
    _parseOldFormat(response, calls);
    
    return calls;
  }
  
  /// 解析旧格式工具调用（兼容）
  static void _parseOldFormat(String response, List<AiToolCall> calls) {
    // image_gen(xxx) 无标签格式
    final genPattern = RegExp(r'(?<!</tool>)image_gen\(([^)]+)\)(?!</tool>)');
    for (final match in genPattern.allMatches(response)) {
      final prompt = match.group(1)?.trim() ?? '';
      if (prompt.isNotEmpty && ImageGenService.isAvailable) {
        // 检查是否已添加
        final exists = calls.any((c) => 
          c.type == AiToolType.generateImage && c.params['prompt'] == prompt);
        if (!exists) {
          calls.add(AiToolCall(
            type: AiToolType.generateImage,
            params: {'prompt': prompt},
          ));
        }
      }
    }
    
    // transfer(xxx)
    final transferPattern = RegExp(r'(?<!</tool>)transfer\(([\d.]+)\)(?!</tool>)');
    for (final match in transferPattern.allMatches(response)) {
      final amount = double.tryParse(match.group(1) ?? '0') ?? 0;
      if (amount > 0) {
        final exists = calls.any((c) => 
          c.type == AiToolType.sendTransfer && c.params['amount'] == amount);
        if (!exists) {
          calls.add(AiToolCall(
            type: AiToolType.sendTransfer,
            params: {'amount': amount},
          ));
        }
      }
    }
    
    // emoji(xxx)
    final emojiPattern = RegExp(r'(?<!</tool>)emoji\(([^)]+)\)(?!</tool>)');
    for (final match in emojiPattern.allMatches(response)) {
      final emoji = match.group(1)?.trim() ?? '';
      if (emoji.isNotEmpty) {
        final exists = calls.any((c) => 
          c.type == AiToolType.sendEmoji && c.params['emoji'] == emoji);
        if (!exists) {
          calls.add(AiToolCall(
            type: AiToolType.sendEmoji,
            params: {'emoji': emoji},
          ));
        }
      }
    }
  }
  
  /// 移除回复中的工具调用标记
  static String removeToolMarkers(String response) {
    return response
        // 新格式 <tool>xxx</tool>
        .replaceAll(RegExp(r'<tool>\w+\([^)]*\)</tool>'), '')
        // 旧格式
        .replaceAll(RegExp(r'image_gen\([^)]*\)'), '')
        .replaceAll(RegExp(r'transfer\([^)]*\)'), '')
        .replaceAll(RegExp(r'emoji\([^)]*\)'), '')
        .trim();
  }
  
  /// 根据情绪判断是否应该发红包/转账
  static TransferResult? shouldSendTransfer(String userMessage, double mood) {
    if (mood < 30) return null;
    if (_random.nextDouble() > 0.1) return null;
    
    final triggers = ['生日', '恭喜', '开心', '庆祝', '红包', '请客'];
    final hasTriger = triggers.any((t) => userMessage.contains(t));
    if (!hasTriger) return null;
    
    final amounts = [0.01, 0.66, 1.88, 6.66, 8.88];
    final amount = amounts[_random.nextInt(amounts.length)];
    final notes = ['小红包', '开心一下', '请你喝水', '小意思'];
    final note = notes[_random.nextInt(notes.length)];
    
    return TransferResult(amount: amount, note: note);
  }
  
  /// 生成工具使用的系统提示（已整合到主提示词）
  static String generateToolPrompt() {
    return '';
  }
}

/// AI 工具调用
class AiToolCall {
  final AiToolType type;
  final Map<String, dynamic> params;
  
  AiToolCall({required this.type, required this.params});
}

/// 工具类型
enum AiToolType {
  generateImage,  // AI 生成图片
  sendTransfer,   // 发送转账
  sendEmoji,      // 发送表情
  sendImage,      // 发送预设图片（已废弃，保留兼容）
  sendVoice,      // 发送语音（暂未实现）
}

/// 转账结果
class TransferResult {
  final double amount;
  final String note;
  
  TransferResult({required this.amount, required this.note});
}
