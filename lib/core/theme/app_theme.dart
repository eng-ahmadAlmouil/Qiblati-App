import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.green,
          onPrimary: AppColors.white,
          surface: AppColors.sand,
          onSurface: AppColors.ink,
          secondary: AppColors.gold,
          onSecondary: AppColors.white,
        );

    final textTheme = GoogleFonts.cairoTextTheme(
      const TextTheme(
        displaySmall: TextStyle(
          color: AppColors.ink,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          color: AppColors.ink,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: AppColors.ink, fontSize: 16, height: 1.6),
        bodyMedium: TextStyle(
          color: AppColors.muted,
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.sand,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.glass,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.ink.withValues(alpha: 0.12),
        indicatorColor: AppColors.mint,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.greenDark,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x55FFFFFF),
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.sand.withValues(alpha: 0.72),
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.greenDark),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        hintStyle: GoogleFonts.cairo(color: AppColors.muted),
      ),
    );
  }
}
