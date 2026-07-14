import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/features/gamification/domain/achievement.dart';
import 'package:wakelock_prm393/features/gamification/domain/level_progress.dart';
import 'package:wakelock_prm393/features/profile/domain/entities/user_profile.dart';

void main() {
  group('LevelProgress.fromXp', () {
    test('derives level + progress from XP (500 per level)', () {
      final p = LevelProgress.fromXp(2450);
      expect(p.level, 5);
      expect(p.xpIntoLevel, 450);
      expect(p.xpToNext, 50);
      expect(p.fraction, closeTo(0.9, 0.001));
    });

    test('level 1 at zero XP', () {
      final p = LevelProgress.fromXp(0);
      expect(p.level, 1);
      expect(p.xpIntoLevel, 0);
    });
  });

  group('Achievement.unlockedBy', () {
    const p = UserProfile(
      uid: 'u1',
      longestStreak: 21,
      xp: 2450,
      photosShared: 42,
    );

    Achievement byId(String id) =>
        kAchievements.firstWhere((a) => a.id == id);

    test('unlocks by reached thresholds', () {
      expect(byId('streak_7').unlockedBy(p), isTrue);
      expect(byId('xp_1500').unlockedBy(p), isTrue);
      expect(byId('photos_10').unlockedBy(p), isTrue);
    });

    test('stays locked below thresholds', () {
      expect(byId('streak_30').unlockedBy(p), isFalse);
      expect(byId('xp_3000').unlockedBy(p), isFalse);
      expect(byId('photos_50').unlockedBy(p), isFalse);
    });
  });
}
