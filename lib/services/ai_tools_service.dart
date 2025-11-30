import 'dart:math' as math;
import 'package:zichat/services/image_gen_service.dart';

/// AI 工具服务 - 让 AI 可以调用各种工具
/// 
/// 支持的工具：
/// - image(描述) - 发送图片
/// - image_gen(描述) - AI 生成图片
/// - transfer(金额) - 发起转账
/// - emoji(名称) - 发送表情
class AiToolsService {
  static final _random = math.Random();
  
  /// 预设的分享图片场景
  static const List<ShareImageScene> _imageScenes = [
    ShareImageScene(
      trigger: ['吃', '饭', '美食', '好吃', '外卖', '奶茶', '咖啡'],
      images: ['assets/icon/discover/scan.jpeg', 'assets/icon/discover/shake.jpeg'],
      captions: ['刚点的', '今天的', '看看这个', '馋不馋'],
    ),
    ShareImageScene(
      trigger: ['猫', '狗', '宠物', '可爱'],
      images: ['assets/img-default.jpg'],
      captions: ['你看', '哈哈哈', '可爱吧'],
    ),
    ShareImageScene(
      trigger: ['风景', '天气', '出门', '外面', '散步'],
      images: ['assets/icon/discover/moments.jpeg', 'assets/icon/discover/channels.jpeg'],
      captions: ['今天天气不错', '刚拍的', '好看吗'],
    ),
  ];
  
  /// 解析 AI 回复中的工具调用
  /// 支持格式：tool_name(参数) 或 [旧格式:参数]
  static List<AiToolCall> parseToolCalls(String response) {
    final calls = <AiToolCall>[];
    
    // 新格式: image_gen(xxx)
    final genImagePattern = RegExp(r'image_gen\(([^)]+)\)');
    for (final match in genImagePattern.allMatches(response)) {
      final prompt = match.group(1)?.trim() ?? '';
      if (prompt.isNotEmpty && ImageGenService.isAvailable) {
        calls.add(AiToolCall(
          type: AiToolType.generateImage,
          params: {'prompt': prompt},
        ));
      }
    }
    
    // 旧格式兼容: [生成图片:xxx]
    final genImageOldPattern = RegExp(r'\[(?:生成图片|画|绘制)[：:]\s*([^\]]+)\]');
    for (final match in genImageOldPattern.allMatches(response)) {
      final prompt = match.group(1)?.trim() ?? '';
      if (prompt.isNotEmpty && ImageGenService.isAvailable) {
        calls.add(AiToolCall(
          type: AiToolType.generateImage,
          params: {'prompt': prompt},
        ));
      }
    }
    
    // 新格式: image(xxx)
    final imagePattern = RegExp(r'(?<!_)image\(([^)]+)\)');
    for (final match in imagePattern.allMatches(response)) {
      final description = match.group(1)?.trim() ?? '';
      if (description.isNotEmpty) {
        calls.add(AiToolCall(
          type: AiToolType.sendImage,
          params: {'description': description},
        ));
      }
    }
    
    // 旧格式兼容: [图片:xxx]
    final imageOldPattern = RegExp(r'\[(?:图片|发图|分享图片)[：:]\s*([^\]]+)\]');
    for (final match in imageOldPattern.allMatches(response)) {
      final description = match.group(1)?.trim() ?? '';
      if (description.isNotEmpty) {
        calls.add(AiToolCall(
          type: AiToolType.sendImage,
          params: {'description': description},
        ));
      }
    }
    
    // 新格式: transfer(金额)
    final transferPattern = RegExp(r'transfer\(([\d.]+)\)');
    for (final match in transferPattern.allMatches(response)) {
      final amount = double.tryParse(match.group(1) ?? '0') ?? 0;
      if (amount > 0) {
        calls.add(AiToolCall(
          type: AiToolType.sendTransfer,
          params: {'amount': amount},
        ));
      }
    }
    
    // 旧格式兼容: [转账:金额]
    final transferOldPattern = RegExp(r'\[(?:转账|发红包)[：:]\s*([\d.]+)\]');
    for (final match in transferOldPattern.allMatches(response)) {
      final amount = double.tryParse(match.group(1) ?? '0') ?? 0;
      if (amount > 0) {
        calls.add(AiToolCall(
          type: AiToolType.sendTransfer,
          params: {'amount': amount},
        ));
      }
    }
    
    // 新格式: emoji(xxx)
    final emojiPattern = RegExp(r'emoji\(([^)]+)\)');
    for (final match in emojiPattern.allMatches(response)) {
      final emoji = match.group(1)?.trim() ?? '';
      if (emoji.isNotEmpty) {
        calls.add(AiToolCall(
          type: AiToolType.sendEmoji,
          params: {'emoji': emoji},
        ));
      }
    }
    
    // 旧格式兼容: [表情:xxx]
    final emojiOldPattern = RegExp(r'\[表情[：:]\s*([^\]]+)\]');
    for (final match in emojiOldPattern.allMatches(response)) {
      final emoji = match.group(1)?.trim() ?? '';
      if (emoji.isNotEmpty) {
        calls.add(AiToolCall(
          type: AiToolType.sendEmoji,
          params: {'emoji': emoji},
        ));
      }
    }
    
    return calls;
  }
  
  /// 移除回复中的工具调用标记
  static String removeToolMarkers(String response) {
    return response
        // 新格式
        .replaceAll(RegExp(r'image_gen\([^)]*\)'), '')
        .replaceAll(RegExp(r'(?<!_)image\([^)]*\)'), '')
        .replaceAll(RegExp(r'transfer\([^)]*\)'), '')
        .replaceAll(RegExp(r'emoji\([^)]*\)'), '')
        // 旧格式
        .replaceAll(RegExp(r'\[(?:生成图片|画|绘制)[：:][^\]]*\]'), '')
        .replaceAll(RegExp(r'\[(?:图片|发图|分享图片)[：:][^\]]*\]'), '')
        .replaceAll(RegExp(r'\[(?:转账|发红包)[：:][^\]]*\]'), '')
        .replaceAll(RegExp(r'\[表情[：:][^\]]*\]'), '')
        .trim();
  }
  
  /// 根据对话上下文，判断是否应该发送图片
  static ShareImageResult? shouldShareImage(String userMessage, String aiResponse) {
    if (_random.nextDouble() > 0.15) return null;
    
    final lowerUser = userMessage.toLowerCase();
    final lowerAi = aiResponse.toLowerCase();
    
    for (final scene in _imageScenes) {
      for (final trigger in scene.trigger) {
        if (lowerUser.contains(trigger) || lowerAi.contains(trigger)) {
          final image = scene.images[_random.nextInt(scene.images.length)];
          final caption = scene.captions[_random.nextInt(scene.captions.length)];
          return ShareImageResult(imagePath: image, caption: caption);
        }
      }
    }
    
    return null;
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
  
  /// 生成工具使用的系统提示（已整合到主提示词，这里返回空）
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
  sendImage,      // 发送预设图片
  generateImage,  // AI 生成图片
  sendTransfer,   // 发送转账
  sendEmoji,      // 发送表情
  sendVoice,      // 发送语音（暂未实现）
}

/// 分享图片场景
class ShareImageScene {
  final List<String> trigger;
  final List<String> images;
  final List<String> captions;
  
  const ShareImageScene({
    required this.trigger,
    required this.images,
    required this.captions,
  });
}

/// 分享图片结果
class ShareImageResult {
  final String imagePath;
  final String caption;
  
  ShareImageResult({required this.imagePath, required this.caption});
}

/// 转账结果
class TransferResult {
  final double amount;
  final String note;
  
  TransferResult({required this.amount, required this.note});
}
