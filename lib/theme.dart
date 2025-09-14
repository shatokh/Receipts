import 'package:flutter/material.dart';

class AppColors {
  // Biedronka brand colors per requirements
  static const primary = Color(0xFF2F6FED);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFF0F172A);
  static const textPrimary = Color(0xFF0B1220);
  static const textSecondary = Color(0xFF475569);
  static const divider = Color(0xFFE2E8F0);
  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
}

class AppTextStyles {
  static const titleLarge = TextStyle(
    fontSize: 24,
    height: 32/24,
    fontWeight: FontWeight.w700,
  );
  static const titleMedium = TextStyle(
    fontSize: 20,
    height: 28/20,
    fontWeight: FontWeight.w600,
  );
  static const bodyLarge = TextStyle(
    fontSize: 16,
    height: 24/16,
    fontWeight: FontWeight.w500,
  );
  static const bodyMedium = TextStyle(
    fontSize: 14,
    height: 20/14,
    fontWeight: FontWeight.w500,
  );
  static const labelSmall = TextStyle(
    fontSize: 12,
    height: 16/12,
    fontWeight: FontWeight.w600,
  );
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}


ThemeData get appTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    surface: AppColors.surface,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.error,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: AppColors.divider),
    ),
    color: AppColors.surface,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(88, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(88, 44),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
  ),
);

