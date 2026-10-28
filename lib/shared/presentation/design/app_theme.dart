import 'package:flutter/material.dart';

import 'app_colors.dart';

// Tema claro con Inter. Escala tipográfica del informe: Display 28, H1 24, H2 20, Title 16, Body 16/14, Caption 12.
class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.primaryDark,
      surface: Colors.white,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.neutralSurface,
      outline: AppColors.neutralBorder,
      error: AppColors.error,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Inter');

    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w800),
        headlineSmall: const TextStyle(fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w700),
        titleLarge: const TextStyle(fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w700),
        titleMedium: const TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600),
        titleSmall: const TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 16, height: 24 / 16),
        bodyMedium: const TextStyle(fontSize: 14, height: 20 / 14),
        bodySmall: const TextStyle(fontSize: 12, height: 16 / 12),
        labelLarge: const TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500),
        labelMedium: const TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500),
      ).apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.neutralBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: AppColors.neutralBorder),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.neutralBorder),
        ),
      ),
    );
  }
}
