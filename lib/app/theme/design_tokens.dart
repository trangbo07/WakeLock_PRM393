import 'package:flutter/animation.dart';

/// Spacing scale (4/8 rhythm). Use these instead of magic numbers.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radius scale. Cards/buttons default to [lg] (16) per design system.
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

/// Motion tokens. Micro-interactions 150–300ms; exits shorter than enters.
/// Easing curve Bezier(0.16, 1, 0.3, 1) — the "expo out" feel from the spec.
class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve easeOutExpo = Cubic(0.16, 1, 0.3, 1);
  static const double pressScale = 0.97; // scale-down on press
}
