// Round-trip (de)serialization between AlarmModel and its SQLite row shape.

import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/features/alarm_management/data/models/alarm_model.dart';
import 'package:wakelock_prm393/features/alarm_management/domain/entities/weekday.dart';
import 'package:wakelock_prm393/features/task/domain/entities/dismiss_task.dart';

void main() {
  AlarmModel roundTrip(AlarmModel original) =>
      AlarmModel.fromDbRow(original.toDbRow());

  test('round-trips a repeating math alarm', () {
    const alarm = AlarmModel(
      id: 'a1',
      label: 'Dậy đi học',
      hour: 6,
      minute: 30,
      repeatDays: {Weekday.monday, Weekday.friday},
      ringtoneId: 'siren',
      dismissTask: DismissTaskConfig(type: DismissTaskType.math, difficulty: 5),
    );
    expect(roundTrip(alarm), alarm);
  });

  test('round-trips a disabled one-shot photo alarm with null-able fields', () {
    const alarm = AlarmModel(
      id: 'a2',
      label: '',
      hour: 23,
      minute: 59,
      isEnabled: false,
      vibrate: false,
      volumeLock: false,
      escalateVolume: false,
      dismissTask: DismissTaskConfig(
        type: DismissTaskType.photo,
        photoTag: 'bồn rửa mặt',
      ),
    );
    final decoded = roundTrip(alarm);
    expect(decoded, alarm);
    expect(decoded.dismissTask.photoTag, 'bồn rửa mặt');
    expect(decoded.repeatDays, isEmpty);
  });

  test('booleans map to INTEGER 0/1 and collections to JSON TEXT', () {
    const alarm = AlarmModel(
      id: 'a3',
      label: 'x',
      hour: 7,
      minute: 0,
      repeatDays: {Weekday.sunday},
      isEnabled: false,
    );
    final row = alarm.toDbRow();
    expect(row['is_enabled'], 0);
    expect(row['vibrate'], 1);
    expect(row['repeat_days'], '[7]');
    expect(row['dismiss_task'], isA<String>());
  });
}
