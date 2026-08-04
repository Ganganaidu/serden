import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Manrope-based text styles matching the design mockups.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Manrope';

  // Headline on onboarding slides (28/800)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // List screen header title (26/800)
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.5,
  );

  // Sheet / page titles (22-24/800)
  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.4,
  );

  // Form nav titles (16/800)
  static const TextStyle headingSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );

  // Row titles (15/700)
  static const TextStyle rowTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  // Amounts in list rows (15.5/800)
  static const TextStyle rowAmount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.5,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: -0.15,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.55,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.inkSoft,
  );

  // Row metadata (12.5/500 faint)
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.inkFaint,
  );

  // Uppercase section labels (12.5/700 + tracking)
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: AppColors.inkSoft,
    letterSpacing: 0.75,
  );

  // Status chips (11/700)
  static const TextStyle chip = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  // Orange CTA button (16/700)
  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  // On-header (green800) variants
  static const TextStyle headerTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textOnPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.onHeaderDim,
  );

  // Legacy aliases kept for compatibility
  static const TextStyle headingLargeOnPrimary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textOnPrimary,
  );

  static const TextStyle bodyOnPrimary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textOnPrimary,
  );
}
