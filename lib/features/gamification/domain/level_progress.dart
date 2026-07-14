/// Derives a level and progress bar from total XP. Each level costs a flat
/// [perLevel] XP, so the model stays self-consistent (level derived from XP).
class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.xpIntoLevel,
    required this.xpPerLevel,
    required this.totalXp,
  });

  factory LevelProgress.fromXp(int xp, {int perLevel = 500}) {
    final safe = xp < 0 ? 0 : xp;
    return LevelProgress(
      level: safe ~/ perLevel + 1,
      xpIntoLevel: safe % perLevel,
      xpPerLevel: perLevel,
      totalXp: safe,
    );
  }

  final int level;
  final int xpIntoLevel;
  final int xpPerLevel;
  final int totalXp;

  int get xpToNext => xpPerLevel - xpIntoLevel;
  double get fraction => xpPerLevel == 0 ? 0 : xpIntoLevel / xpPerLevel;
}
