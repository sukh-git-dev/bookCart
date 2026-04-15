import 'package:flutter/material.dart';
import 'package:bookcart/core/theme/app_color_palette.dart';

class AppColors {
  static AppColorPalette _palette = AppThemePalettes.forest;

  static AppColorPalette get palette => _palette;

  static void applyPalette(AppColorPalette palette) {
    _palette = palette;
  }

  static Color get primary => _palette.primary;
  static Color get secondary => _palette.secondary;
  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get dark => _palette.dark;
  static Color get muted => _palette.muted;
  static Color get border => _palette.border;
  static const white = Colors.white;

  const AppColors._();
}
