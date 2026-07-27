import 'package:flutter/material.dart';

/// Low-vision-safe theme for elderly caregivers with cataracts:
/// off-white bg + dark text (NOT pure black/white), large type, generous spacing.
final ThemeData careTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2C5D80),
    surface: const Color(0xFFF5F5F5),
    onSurface: const Color(0xFF222222),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 24, height: 1.6, color: Color(0xFF222222)),
    bodyMedium: TextStyle(fontSize: 20, height: 1.6, color: Color(0xFF222222)),
    titleLarge: TextStyle(fontSize: 28, height: 1.5, color: Color(0xFF222222)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(88, 56), // ≥48px touch target, comfortable for elderly
      textStyle: const TextStyle(fontSize: 22),
    ),
  ),
);
