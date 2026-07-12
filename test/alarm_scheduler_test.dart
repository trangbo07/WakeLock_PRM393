// stableId must be deterministic across runs — it is the only handle for
// cancelling/rescheduling an alarm that was registered in a previous session.

import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/core/platform/alarm_scheduler.dart';

void main() {
  test('stableId is deterministic for the same UUID', () {
    const uuid = '9b2d7c1e-4f3a-4b8c-9d6e-0f1a2b3c4d5e';
    expect(AlarmScheduler.stableId(uuid), AlarmScheduler.stableId(uuid));
  });

  test('stableId is a positive 31-bit int', () {
    const samples = [
      '9b2d7c1e-4f3a-4b8c-9d6e-0f1a2b3c4d5e',
      '00000000-0000-0000-0000-000000000000',
      'ffffffff-ffff-ffff-ffff-ffffffffffff',
      'a',
    ];
    for (final s in samples) {
      final id = AlarmScheduler.stableId(s);
      expect(id, greaterThanOrEqualTo(0), reason: s);
      expect(id, lessThanOrEqualTo(0x7FFFFFFF), reason: s);
    }
  });

  test('stableId differs for different UUIDs', () {
    final ids = {
      AlarmScheduler.stableId('9b2d7c1e-4f3a-4b8c-9d6e-0f1a2b3c4d5e'),
      AlarmScheduler.stableId('1c8e6f2a-7d5b-4a9c-8e0f-1a2b3c4d5e6f'),
      AlarmScheduler.stableId('5e4d3c2b-1a0f-4e9d-8c7b-6a5f4e3d2c1b'),
    };
    expect(ids, hasLength(3));
  });
}
