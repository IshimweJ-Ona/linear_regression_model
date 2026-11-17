import 'package:flutter/material.dart';

/// Dark-navy analytics and prediction palette matching the SkillBridge mobile UI.
abstract final class AppColors {
  static const Color bgTop = Color(0xFF090E1A);
  static const Color bgBottom = Color(0xFF0F172A);
  static const Color cardBg = Color(0xFF131D33);
  static const Color cardBorder = Color(0xFF24324F);
  static const Color inputFill = Color(0xFF0C1426);

  static const Color cyan = Color(0xFF38BDF8);
  static const Color indigo = Color(0xFF6366F1);
  static const Color purple = Color(0xFFA855F7);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color coral = Color(0xFFF43F5E);
  static const Color heatNeg = Color(0xFFF97316);
  static const Color heatPos = Color(0xFF3B82F6);
  static const Color heatZero = Color(0xFF1E293B);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color emeraldTint = Color(0xFF0D2824);
  static const Color coralTint = Color(0xFF2B1220);
}

ThemeData buildSkillBridgeTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bgTop,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.cyan,
      secondary: AppColors.purple,
      surface: AppColors.cardBg,
      error: AppColors.coral,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFill,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      helperStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cyan, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.coral, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.coral, width: 1.6),
      ),
    ),
  );
}
