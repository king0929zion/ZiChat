import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用全局样式常量
class AppStyles {
  AppStyles._();

  // 标题样式
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // 正文样式
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  // 辅助文字
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle hint = TextStyle(
    fontSize: 14,
    color: AppColors.textHint,
  );

  // 按钮文字
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textWhite,
  );

  // 时间戳样式
  static const TextStyle timestamp = TextStyle(
    fontSize: 12,
    color: AppColors.textHint,
  );

  // 消息文字
  static const TextStyle messageText = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // 圆角
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 14.0;
  static const double radiusXLarge = 20.0;

  // 动画时长（加快速度）
  static const Duration animationFast = Duration(milliseconds: 80);
  static const Duration animationNormal = Duration(milliseconds: 150);
  static const Duration animationSlow = Duration(milliseconds: 200);

  // 动画曲线
  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.elasticOut;
  static const Curve curveBounce = Curves.bounceOut;

  // 间距
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 24.0;

  // 边框
  static final BorderSide borderDefault = BorderSide(
    color: AppColors.border,
    width: 0.5,
  );

  // 阴影
  static final List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}

