import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/features/challenge/domain/entities/challenge.dart';

void main() {
  group('Challenge status', () {
    test('active when endAt is in the future', () {
      final c = Challenge(
        id: '1',
        endAt: DateTime.now().add(const Duration(days: 3)),
      );
      expect(c.isActive, isTrue);
      expect(c.daysLeft, 3);
    });

    test('ended when endAt is in the past', () {
      final c = Challenge(
        id: '2',
        endAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(c.isActive, isFalse);
      expect(c.daysLeft, 0);
    });

    test('active with no endAt (falls back to days)', () {
      const c = Challenge(id: '3', days: 7);
      expect(c.isActive, isTrue);
      expect(c.daysLeft, 7);
    });

    test('participantCount reflects the uid list', () {
      const c = Challenge(id: '4', participantUids: ['a', 'b', 'c']);
      expect(c.participantCount, 3);
    });
  });

  group('ChallengeParticipant.checkedInOn', () {
    test('true when last check-in is today', () {
      final p = ChallengeParticipant(uid: 'a', lastCheckIn: DateTime.now());
      expect(p.checkedInOn(), isTrue);
    });

    test('false when last check-in was a previous day', () {
      final p = ChallengeParticipant(
        uid: 'a',
        lastCheckIn: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(p.checkedInOn(), isFalse);
    });

    test('false when never checked in', () {
      const p = ChallengeParticipant(uid: 'a');
      expect(p.checkedInOn(), isFalse);
    });
  });
}
