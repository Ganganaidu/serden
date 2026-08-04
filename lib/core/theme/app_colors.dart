import 'package:flutter/material.dart';

/// Serden design system palette.
///
/// Mirrors the CSS variables used across the design mockups
/// (SERDEN APP FINAL DESIGN).
class AppColors {
  AppColors._();

  // Brand greens
  static const Color green900 = Color(0xFF0F2D20);
  static const Color green800 = Color(0xFF153A2B); // headers, active nav
  static const Color green700 = Color(0xFF1E4A37);
  static const Color green600 = Color(0xFF2A5C46);
  static const Color greenDeep = Color(0xFF1E5C3F); // links, positive accents
  static const Color greenTint = Color(0xFFE4F0E9); // icon chips, success bg

  // Brand orange (primary CTA)
  static const Color orange500 = Color(0xFFE2793A);
  static const Color orange600 = Color(0xFFC96528); // pressed / hover
  static const Color orangeTint = Color(0xFFFDEBDD); // warning bg, viewed chip
  static const Color orangeDeep = Color(0xFF9C4A15); // text on orangeTint

  // Reds
  static const Color redTint = Color(0xFFFBE9E7);
  static const Color redDeep = Color(0xFFA33A2A);

  // Greys
  static const Color grayTint = Color(0xFFEEEFEE);
  static const Color grayDeep = Color(0xFF6A756E);

  // Surfaces
  static const Color page = Color(0xFFF7F7F5); // scaffold background
  static const Color card = Color(0xFFFFFFFF);
  static const Color sheetBg = Color(0xFFFAFAF8); // auth bottom sheet
  static const Color rowHover = Color(0xFFFCFCFB);

  // Ink (text)
  static const Color ink = Color(0xFF1B2B23);
  static const Color inkSoft = Color(0xFF5C6B62);
  static const Color inkFaint = Color(0xFF93A099);

  // Lines & fields
  static const Color line = Color(0xFFECEEEC);
  static const Color fieldBorder = Color(0xFFD8DDD9);
  static const Color switchTrackOff = Color(0xFFD8DDD9);
  static const Color grabber = Color(0xFFD5D9D6);

  // Star rating
  static const Color star = Color(0xFFEFA727);

  // Document (estimate/invoice paper) colors
  static const Color docInk = Color(0xFF1C1C1E);
  static const Color docSoft = Color(0xFF3A3A3C);
  static const Color docNavy = Color(0xFF2E3A55);
  static const Color docLine = Color(0xFFE5E5E3);
  static const Color docSectionBg = Color(0xFFEFEFED);

  // Header helpers (on green800)
  static const Color onHeaderDim = Color(0xADFFFFFF); // white 68%
  static const Color onHeaderFaint = Color(0x8CFFFFFF); // white 55%
  static const Color overdueOnHeader = Color(0xFFF5B09A);

  // Avatar palette (hash-picked per client name)
  static const List<Color> avatarColors = [
    Color(0xFF1E5C3F),
    Color(0xFFE2793A),
    Color(0xFF3E7FD9),
    Color(0xFF8259C4),
    Color(0xFFC24545),
    Color(0xFFB07C1F),
  ];

  // Semantic aliases used throughout the app
  static const Color primary = green800;
  static const Color primaryDark = green900;
  static const Color primaryLight = green700;
  static const Color accent = orange500;

  static const Color background = page;
  static const Color surface = card;
  static const Color surfaceVariant = grayTint;

  static const Color textPrimary = ink;
  static const Color textSecondary = inkSoft;
  static const Color textHint = inkFaint;
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color border = line;
  static const Color divider = line;

  static const Color error = redDeep;
  static const Color errorLight = redTint;
}
