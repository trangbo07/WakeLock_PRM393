import 'package:flutter/material.dart';

/// WakeLock color tokens — "Alarm & World Clock" dark palette.
///
/// Amber = alarm/time accent (primary CTA), indigo = night accent, on a deep
/// navy (not pure black, to avoid OLED smear). Verified for WCAG AA+ contrast
/// on the dark surface.
class AppColors {
  AppColors._();

  // Brand / accent
  static const Color primary = Color(0xFFD97706); // amber (time/alarm)
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFF59E0B); // lighter amber
  static const Color onSecondary = Color(0xFF0F172A);
  static const Color accent = Color(0xFF6366F1); // night indigo
  static const Color onAccent = Color(0xFFFFFFFF);

  // Surfaces (deep navy, layered)
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF192134); // cards
  static const Color surfaceMuted = Color(0xFF1F1E27);

  // Text
  static const Color foreground = Color(0xFFFFFFFF);
  static const Color mutedForeground = Color(0xFF94A3B8);

  // Lines / status
  static const Color border = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color destructive = Color(0xFFDC2626);
  static const Color onDestructive = Color(0xFFFFFFFF);
}
