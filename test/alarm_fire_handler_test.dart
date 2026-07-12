// Mapping the fired scheduler int id back to the alarm row.

import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/core/platform/alarm_scheduler.dart';
import 'package:wakelock_prm393/features/alarm_management/data/models/alarm_model.dart';
import 'package:wakelock_prm393/features/alarm_ringing/data/alarm_fire_handler.dart';

void main() {
  const alarms = [
    AlarmModel(id: 'uuid-a', label: 'A', hour: 6, minute: 0),
    AlarmModel(id: 'uuid-b', label: 'B', hour: 7, minute: 30),
  ];

  test('findByFiredId resolves the alarm whose stableId matches', () {
    final fired = AlarmScheduler.stableId('uuid-b');
    expect(findByFiredId(alarms, fired)?.id, 'uuid-b');
  });

  test('findByFiredId returns null for an unknown id', () {
    expect(findByFiredId(alarms, 12345), isNull);
  });
}
