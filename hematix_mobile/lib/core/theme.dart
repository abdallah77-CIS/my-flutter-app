import 'package:flutter/material.dart';

/// Mirrors the web design system in css/style.css so the mobile app reads as
/// the same product: same palette, same radii, same warm clinical identity.
class AppColors {
  static const primary = Color(0xFFA10D26);
  static const primaryDark = Color(0xFF74071A);
  static const primaryLight = Color(0xFFF3C7CC);
  static const primaryTint = Color(0xFFFBEBEC);

  static const ink = Color(0xFF0F1B2D);
  static const inkSoft = Color(0xFF3B4A63);
  static const inkFaint = Color(0xFF6B7B93);

  static const paper = Color(0xFFF6F8FB);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E9F1);
  static const borderSoft = Color(0xFFEEF1F6);

  static const success = Color(0xFF189E6C);
  static const successBg = Color(0xFFE4F8EF);
  static const warning = Color(0xFFEE9E1F);
  static const warningBg = Color(0xFFFDF1DC);
  static const danger = Color(0xFFA10D26);
  static const dangerBg = Color(0xFFFDECEC);
  static const info = Color(0xFF2C6ECB);
  static const infoBg = Color(0xFFE9F1FD);

  static const navy900 = Color(0xFF2A0509);
}

class AppRadius {
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
}

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.primaryDark,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.inkSoft,
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      labelStyle: const TextStyle(color: AppColors.inkFaint),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryTint,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.inkFaint,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.inkFaint,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderSoft),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
