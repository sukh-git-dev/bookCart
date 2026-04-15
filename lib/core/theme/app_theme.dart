import 'package:bookcart/core/constants/app_colors.dart';
import 'package:bookcart/core/theme/app_color_palette.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light([AppColorPalette? palette]) {
    final colors = palette ?? AppColors.palette;

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        primary: colors.primary,
        secondary: colors.secondary,
        surface: colors.surface,
      ),
      scaffoldBackgroundColor: colors.background,
      useMaterial3: true,
      fontFamily: 'Roboto',
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(
          color: colors.muted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: colors.primary,
        suffixIconColor: colors.muted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.primary,
        selectionColor: colors.secondary,
        selectionHandleColor: colors.primary,
      ),
    );
  }

  const AppTheme._();
}
