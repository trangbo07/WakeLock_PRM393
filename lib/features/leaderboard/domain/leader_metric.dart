import '../../profile/domain/entities/user_profile.dart';

/// The metric friends are ranked by on the leaderboard.
enum LeaderMetric {
  streak('Chuỗi ngày'),
  wakeRate('Tỉ lệ dậy'),
  xp('XP');

  const LeaderMetric(this.label);
  final String label;

  /// Comparable value (higher ranks first).
  num value(UserProfile p) => switch (this) {
        LeaderMetric.streak => p.currentStreak,
        LeaderMetric.wakeRate => p.wakeRate,
        LeaderMetric.xp => p.xp,
      };

  /// Human-readable value for display.
  String display(UserProfile p) => switch (this) {
        LeaderMetric.streak => '${p.currentStreak} ngày',
        LeaderMetric.wakeRate => '${(p.wakeRate * 100).round()}%',
        LeaderMetric.xp => '${p.xp} XP',
      };
}
