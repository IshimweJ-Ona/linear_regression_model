import 'package:flutter/material.dart';

/// Strict 5-color institutional light palette for SkillBridge analytics & prediction.
///
/// The five core colors across the entire UI and every chart are:
/// 1. Paper White (`#FFFFFF`) – card surfaces and chart plot canvases
/// 2. Slate Ink (`#0F172A`) – typography, axes, borders, baseline bars (plus paper-ink neutral tints)
/// 3. Institutional Navy (`#1E3A8A`) – primary actions, winning model, primary data series, +1.0 corr
/// 4. Pine Teal (`#0F766E`) – OLS fit, Test MSE, Female/TVET & prediction benchmark highlight
/// 5. Editorial Crimson (`#B91C1C`) – validation alerts and -1.0 negative correlation
abstract final class AppColors {
  static const Color paper = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0F172A);
  static const Color navy = Color(0xFF1E3A8A);
  static const Color teal = Color(0xFF0F766E);
  static const Color crimson = Color(0xFFB91C1C);

  // Neutral steps blended strictly between Paper (#FFFFFF) and Ink (#0F172A)
  static const Color canvas = Color(0xFFF8FAFC);
  static const Color subtleFill = Color(0xFFF1F5F9);
  static const Color hairline = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);

  // Soft Paper-blended tints of the 3 accent colors
  static const Color navyTint = Color(0xFFEEF2FA);
  static const Color tealTint = Color(0xFFECF6F5);
  static const Color crimsonTint = Color(0xFFFEF2F2);
}

ThemeData buildSkillBridgeTheme() {
  return ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: const ColorScheme.light(
      primary: AppColors.navy,
      secondary: AppColors.teal,
      surface: AppColors.paper,
      error: AppColors.crimson,
      onPrimary: AppColors.paper,
      onSecondary: AppColors.paper,
      onSurface: AppColors.ink,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(4),
      radius: const Radius.circular(4),
      thumbColor: WidgetStatePropertyAll(AppColors.ink.withValues(alpha: 0.22)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.paper,
      isDense: true,
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      helperStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderStrong, width: 1.1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.navy, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.crimson, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.crimson, width: 1.6),
      ),
    ),
  );
}
