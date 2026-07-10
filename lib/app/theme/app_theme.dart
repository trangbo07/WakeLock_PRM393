import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Builds the app's [ThemeData]. Dark-only ("Alarm & World Clock" palette).
///
/// Uses Inter (via google_fonts) with tabular figures so clock digits don't
/// jitter, radius 16 on cards/buttons, and hairline borders per the design
/// system. See docs/design-guidelines.md.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      tertiary: AppColors.accent,
      onTertiary: AppColors.onAccent,
      surface: AppColors.surface,
      onSurface: AppColors.foreground,
      surfaceContainerHighest: AppColors.surfaceMuted,
      onSurfaceVariant: AppColors.mutedForeground,
      outline: AppColors.border,
      error: AppColors.destructive,
      onError: AppColors.onDestructive,
    );

    // Inter everywhere; tabular figures keep numeric layouts stable.
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: AppColors.foreground,
      displayColor: AppColors.foreground,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52), // ≥44pt touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
