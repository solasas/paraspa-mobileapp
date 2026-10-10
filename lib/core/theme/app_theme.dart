import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// Layout constants from the design spec (logical points on a 390-wide frame).
class AppSpacing {
  AppSpacing._();

  static const screenX = 20.0;
  static const authX = 24.0;

  /// Bottom padding for scroll content so it clears the floating nav / bar.
  static const scrollBottom = 120.0;
}

class AppRadius {
  AppRadius._();

  static const heroCard = 28.0;
  static const sectionCard = 26.0;
  static const listCard = 24.0;
  static const row = 20.0;
  static const sheetTop = 32.0;
  static const headerBottom = 36.0;
  static const buttonPrimary = 18.0;
  static const buttonSecondary = 16.0;
  static const buttonInline = 14.0;
  static const input = 14.0;
  static const inputLarge = 18.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.ink,
      onPrimary: AppColors.paper,
      primaryContainer: AppColors.accent,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.accent,
      onSecondary: AppColors.ink,
      secondaryContainer: AppColors.lilac,
      onSecondaryContainer: AppColors.ink,
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: AppColors.statusDeclinedBg,
      onErrorContainer: AppColors.statusDeclinedText,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.trackBg,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.inputBorder,
      outlineVariant: AppColors.cardBorder,
    );

    final textTheme = TextTheme(
      displaySmall: AppText.h1(),
      headlineSmall: AppText.detailTitle(),
      titleLarge: AppText.h2(),
      titleMedium: AppText.cardHeading(),
      titleSmall: AppText.overline(),
      bodyLarge: AppText.bodyText(),
      bodyMedium: AppText.bodyText(),
      bodySmall: AppText.meta(),
      labelLarge: AppText.button(color: AppColors.textPrimary),
      labelMedium: AppText.buttonSmall(),
      labelSmall: AppText.badge(),
    );

    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      fontFamily: 'DMSans',
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.h2(),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hoverColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(AppColors.inputBorder),
        enabledBorder: border(AppColors.inputBorder),
        focusedBorder: border(AppColors.ink),
        errorBorder: border(AppColors.danger),
        focusedErrorBorder: border(AppColors.danger),
        labelStyle: AppText.body(14, weight: FontWeight.w500, color: AppColors.textSecondary),
        floatingLabelStyle: AppText.body(13, weight: FontWeight.w700, color: AppColors.ink),
        hintStyle: AppText.body(15, color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.listCard),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          minimumSize: const Size.fromHeight(58),
          textStyle: AppText.button(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.buttonPrimary),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.chipBorder, width: 1.5),
          textStyle: AppText.buttonSmall(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.buttonSecondary),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: AppText.buttonSmall(),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.body(14, weight: FontWeight.w500, color: AppColors.paper),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.ink),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.ink : AppColors.trackBg,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.accent : Colors.white,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sectionCard)),
        titleTextStyle: AppText.h2(),
        contentTextStyle: AppText.bodyText(),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheetTop)),
        ),
      ),
    );
  }
}
