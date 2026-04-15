import 'package:flutter/material.dart';

class AppColorPalette {
  const AppColorPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.dark,
    required this.muted,
    required this.border,
  });

  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color dark;
  final Color muted;
  final Color border;
}

class AppThemePalettes {
  static const AppColorPalette forest = AppColorPalette(
    id: 'forest',
    name: 'Forest',
    primary: Color(0xFF0F766E),
    secondary: Color(0xFF14B8A6),
    background: Color(0xFFF2FBFA),
    surface: Color(0xFFDDF4F1),
    dark: Color(0xFF12312E),
    muted: Color(0xFF5C7C78),
    border: Color(0xFFBFE5DF),
  );

  static const AppColorPalette sunset = AppColorPalette(
    id: 'sunset',
    name: 'Sunset',
    primary: Color(0xFFDD6B20),
    secondary: Color(0xFFF59E0B),
    background: Color(0xFFFFF7ED),
    surface: Color(0xFFFEE6CE),
    dark: Color(0xFF4A2B12),
    muted: Color(0xFF8C6544),
    border: Color(0xFFF6CDA8),
  );

  static const AppColorPalette ocean = AppColorPalette(
    id: 'ocean',
    name: 'Ocean',
    primary: Color(0xFF2563EB),
    secondary: Color(0xFF38BDF8),
    background: Color(0xFFF1F7FF),
    surface: Color(0xFFDCEBFF),
    dark: Color(0xFF14294A),
    muted: Color(0xFF5C7393),
    border: Color(0xFFBCD6F8),
  );

  static const AppColorPalette berry = AppColorPalette(
    id: 'berry',
    name: 'Berry',
    primary: Color(0xFFBE185D),
    secondary: Color(0xFFF472B6),
    background: Color(0xFFFFF1F7),
    surface: Color(0xFFFAD7E7),
    dark: Color(0xFF43152A),
    muted: Color(0xFF8C5E73),
    border: Color(0xFFF2BDD3),
  );

  static const AppColorPalette violet = AppColorPalette(
    id: 'violet',
    name: 'Violet',
    primary: Color(0xFF7C3AED),
    secondary: Color(0xFFA78BFA),
    background: Color(0xFFF6F1FF),
    surface: Color(0xFFE6DBFF),
    dark: Color(0xFF2C1D53),
    muted: Color(0xFF6F63A0),
    border: Color(0xFFD2C3FA),
  );

  static const List<AppColorPalette> all = [
    forest,
    sunset,
    ocean,
    berry,
    violet,
  ];

  static AppColorPalette byId(String? id) {
    for (final palette in all) {
      if (palette.id == id) {
        return palette;
      }
    }

    return forest;
  }

  const AppThemePalettes._();
}
