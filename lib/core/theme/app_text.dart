import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typographic roles from the spec. Bricolage Grotesque for display/headings,
/// DM Sans for body and UI. Letter-spacing values are logical pixels.
class AppText {
  AppText._();

  static const _display = 'Bricolage';
  static const _body = 'DMSans';

  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w800,
    double spacing = 0,
    double? height,
    Color color = AppColors.textPrimary,
  }) =>
      TextStyle(
        fontFamily: _display,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: spacing,
        height: height,
        color: color,
      );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    double spacing = 0,
    double? height,
    Color color = AppColors.textBody,
  }) =>
      TextStyle(
        fontFamily: _body,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: spacing,
        height: height,
        color: color,
      );

  // Display roles
  static TextStyle welcomeHero({Color color = AppColors.onDarkPrimary}) =>
      display(44, spacing: -1.6, height: 1.12, color: color);
  static TextStyle sessionTime({Color color = AppColors.onDarkPrimary}) =>
      display(68, spacing: -3, height: 0.9, color: color);
  static TextStyle loginHeading({Color color = AppColors.onDarkPrimary}) =>
      display(38, spacing: -1.3, height: 1.02, color: color);
  static TextStyle h1({Color color = AppColors.textPrimary}) =>
      display(34, spacing: -1, color: color);
  static TextStyle detailTitle({Color color = AppColors.textPrimary}) =>
      display(30, spacing: -0.8, height: 1.05, color: color);
  static TextStyle sheetTitle({Color color = AppColors.textPrimary}) =>
      display(28, spacing: -0.8, color: color);
  static TextStyle ratingAverage({Color color = AppColors.textPrimary}) =>
      display(44, spacing: -1.5, height: 1, color: color);
  static TextStyle h2({Color color = AppColors.textPrimary}) =>
      display(20, weight: FontWeight.w700, spacing: -0.4, color: color);
  static TextStyle cardHeading({Color color = AppColors.textPrimary}) =>
      display(18, weight: FontWeight.w700, color: color);
  static TextStyle stat({Color color = AppColors.textPrimary}) =>
      display(24, color: color);

  // Body roles
  static TextStyle personName({Color color = AppColors.textPrimary}) =>
      body(16, weight: FontWeight.w700, color: color);
  static TextStyle bodyText({Color color = AppColors.textBody}) =>
      body(15, height: 1.45, color: color);
  static TextStyle meta({Color color = AppColors.textSecondary}) =>
      body(13, weight: FontWeight.w500, color: color);
  static TextStyle overline({Color color = AppColors.textSecondary}) =>
      body(11.5, weight: FontWeight.w700, spacing: 0.5, color: color);
  static TextStyle fieldLabel({Color color = AppColors.textPrimary}) =>
      body(12, weight: FontWeight.w700, spacing: 0.5, color: color);
  static TextStyle button({Color color = AppColors.paper}) =>
      body(16, weight: FontWeight.w700, color: color);
  static TextStyle buttonSmall({Color color = AppColors.textPrimary}) =>
      body(14.5, weight: FontWeight.w700, color: color);
  static TextStyle badge({Color color = AppColors.textPrimary}) =>
      body(11, weight: FontWeight.w700, spacing: 0.4, color: color);
  static TextStyle navLabel({Color color = AppColors.ink}) =>
      body(14, weight: FontWeight.w700, color: color);
}
