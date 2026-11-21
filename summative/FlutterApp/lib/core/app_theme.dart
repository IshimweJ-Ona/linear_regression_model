import 'package:flutter/material.dart';

/// Crisp Light Clinical Analytics palette for SkillBridge mobile UI
/// and interactive analytics charts.
abstract final class AppColors {
  // Core surfaces & borders
  static const Color canvas = Color(0xFFF4F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color subtleFill = Color(0xFFEEF3F8);
  static const Color hairline = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // Typography
  static const Color ink = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);

  // Brand & analytical accents
  static const Color navy = Color(0xFF2563EB); // Primary Cobalt Blue
  static const Color teal = Color(0xFF0D9488); // Clinical Teal accent
  static const Color emerald = Color(0xFF04875E); // Best model emerald
  static const Color amber = Color(0xFFD97706); // DecisionTree amber
  static const Color indigo = Color(0xFF4F46E5); // LinearReg indigo
  static const Color slateNavy = Color(0xFF475569); // Secondary comparison bar
  static const Color crimson = Color(0xFFE11D48); // Error & negative corr
  static const Color paper = Color(
    0xFFFFFFFF,
  ); // Pure white text on solid fills

  // Soft light tints
  static const Color navyTint = Color(0xFFEFF6FF);
  static const Color tealTint = Color(0xFFE6FAF5);
  static const Color crimsonTint = Color(0xFFFFF1F2);
  static const Color crimsonText = Color(0xFF9F1239);
  static const Color heatZero = Color(0xFFF1F5F9);
  static const Color cardShadow = Color(0x0F0F172A);
}

ThemeData buildSkillBridgeTheme() {
  return ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: const ColorScheme.light(
      primary: AppColors.navy,
      secondary: AppColors.teal,
      surface: AppColors.surface,
      error: AppColors.crimson,
      onPrimary: AppColors.paper,
      onSecondary: AppColors.paper,
      onSurface: AppColors.ink,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(4),
      radius: const Radius.circular(4),
      thumbColor: WidgetStatePropertyAll(
        AppColors.textSecondary.withValues(alpha: 0.35),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.canvas,
      isDense: true,
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.teal,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      helperStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      errorStyle: const TextStyle(
        color: AppColors.crimsonText,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderStrong, width: 1.1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.teal, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.crimson, width: 1.3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.crimson, width: 1.6),
      ),
    ),
  );
}
