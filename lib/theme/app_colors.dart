import 'package:flutter/material.dart' show Color;

abstract final class AppColors {
  // Backgrounds
  static const background = Color(0xFF0B1220);
  static const surface = Color(0xFF141D2E);
  static const surfaceHover = Color(0xFF1A2438);
  static const divider = Color(0xFF1F2A40);

  // Brand
  static const primary = Color(0xFF5B5AF7);
  static const primaryPressed = Color(0xFF4A49D6);
  static const primarySoft = Color(0xFF2A2C5F);

  // Status
  static const success = Color(0xFF2DD4BF);
  static const sync = Color(0xFF7C7CFF);
  static const warning = Color(0xFFFACC15);
  static const error = Color(0xFFEF4444);
  static const errorSurface = Color(0xFF7F2E33);

  // Text
  static const textPrimary = Color(0xFFE5E7EB);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textTertiary = Color(0xFF6B7280);
  static const textDisabled = Color(0xFF4B5563);
}
