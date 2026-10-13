import 'package:flutter/material.dart';

/// Palet warna utama aplikasi, diambil dari gaya header biru tua
/// pada referensi layout yang diberikan pengguna.
class AppColors {
  static const primary = Color(0xFF0C447C);
  static const navy = Color(0xFF0C447C);
  static const navyLight = Color(0xFF378ADD);
  static const navyPale = Color(0xFFE6F1FB);
  static const danger = Color(0xFFE24B4A);
  static const dangerBg = Color(0xFFFCEBEB);
  static const warning = Color(0xFFEF9F27);
  static const warningBg = Color(0xFFFAEEDA);
  static const success = Color(0xFF639922);
  static const successBg = Color(0xFFEAF3DE);
  static const secondaryBg = Color(0xFFF1F5F9);
  static const surface = Color(0xFFF7F7F5);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF1D1D1D);
  static const textSecondary = Color(0xFF5F5E5A);
  static const textMuted = Color(0xFF888780);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      elevation: 0,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x14000000)),
      ),
    ),
  );
}
