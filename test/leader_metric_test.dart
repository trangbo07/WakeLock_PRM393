import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/features/leaderboard/domain/leader_metric.dart';
import 'package:wakelock_prm393/features/profile/domain/entities/user_profile.dart';

void main() {
  const p = UserProfile(
    uid: 'u1',
    displayName: 'Test',
    currentStreak: 12,
    wakeRate: 0.834,
    xp: 540,
  );

  group('LeaderMetric.value', () {
    test('extracts the ranking value per metric', () {
      expect(LeaderMetric.streak.value(p), 12);
      expect(LeaderMetric.wakeRate.value(p), 0.834);
      expect(LeaderMetric.xp.value(p), 540);
    });
  });

  group('LeaderMetric.display', () {
    test('formats each metric for display', () {
      expect(LeaderMetric.streak.display(p), '12 ngày');
      expect(LeaderMetric.wakeRate.display(p), '83%'); // rounded from 0.834
      expect(LeaderMetric.xp.display(p), '540 XP');
    });
  });
}
