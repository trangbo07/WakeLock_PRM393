import 'package:flutter/material.dart';

/// Curated icon + color choices for habits — `Habit.icon` stores the catalog
/// key (not an emoji), `Habit.color` stores the chosen palette color as ARGB.
/// Both fields already existed in the schema, so this is a rendering-layer
/// change only (no DB migration): an unknown/legacy key just falls back to
/// [defaultIcon] instead of crashing.
class HabitIconCatalog {
  HabitIconCatalog._();

  static const String defaultKey = 'check';

  static const Map<String, IconData> icons = {
    'check': Icons.check_circle_rounded,
    'book': Icons.menu_book_rounded,
    'run': Icons.directions_run_rounded,
    'water': Icons.water_drop_rounded,
    'meditate': Icons.self_improvement_rounded,
    'sleep': Icons.nightlight_rounded,
    'journal': Icons.edit_note_rounded,
    'gym': Icons.fitness_center_rounded,
    'food': Icons.restaurant_rounded,
    'music': Icons.music_note_rounded,
    'code': Icons.code_rounded,
    'save': Icons.savings_rounded,
    'language': Icons.translate_rounded,
    'art': Icons.brush_rounded,
    'plant': Icons.eco_rounded,
    'study': Icons.school_rounded,
    'clean': Icons.cleaning_services_rounded,
    'heart': Icons.favorite_rounded,
  };

  /// Brand-consistent palette (amber/indigo from `AppColors`, plus a few
  /// accent hues) so habit cards stay varied without clashing with the rest
  /// of the app.
  static const List<int> palette = [
    0xFFF59E0B, // amber
    0xFF6366F1, // indigo
    0xFF16A34A, // green
    0xFF0EA5E9, // sky
    0xFFEC4899, // pink
    0xFFEF4444, // red
    0xFF8B5CF6, // violet
    0xFF14B8A6, // teal
  ];

  static IconData iconFor(String key) => icons[key] ?? icons[defaultKey]!;

  static Color colorFor(int? argb) => Color(argb ?? palette.first);
}

/// A rounded, colored square with an icon inside — the recurring "badge"
/// visual used across habit list/detail/nav cards.
class HabitIconBadge extends StatelessWidget {
  const HabitIconBadge({
    super.key,
    required this.iconKey,
    required this.color,
    this.size = 44,
  });

  final String iconKey;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Icon(HabitIconCatalog.iconFor(iconKey), color: color, size: size * 0.52),
    );
  }
}
