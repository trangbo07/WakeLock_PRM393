// Integration test: LocalAlarmRepository against a real in-memory SQLite DB
// (sqflite ffi) with a fake scheduler, exercising persist ↔ schedule sync.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wakelock_prm393/core/database/app_database.dart';
import 'package:wakelock_prm393/core/platform/alarm_scheduler.dart';
import 'package:wakelock_prm393/features/alarm_management/data/datasources/alarm_local_datasource.dart';
import 'package:wakelock_prm393/features/alarm_management/data/repositories/local_alarm_repository.dart';
import 'package:wakelock_prm393/features/alarm_management/domain/entities/alarm.dart';
import 'package:wakelock_prm393/features/alarm_management/domain/entities/weekday.dart';

/// Records scheduler calls instead of hitting AndroidAlarmManager.
class _FakeScheduler extends AlarmScheduler {
  final scheduled = <int>[];
  final cancelled = <int>[];

  @override
  Future<bool> scheduleOneShot(int id, DateTime when,
      {required void Function(int) callback}) async {
    scheduled.add(id);
    return true;
  }

  @override
  Future<bool> cancel(int id) async {
    cancelled.add(id);
    return true;
  }
}

void main() {
  sqfliteFfiInit();

  late Database db;
  late _FakeScheduler scheduler;
  late LocalAlarmRepository repo;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => AppDatabase.createSchema(db),
      ),
    );
    scheduler = _FakeScheduler();
    repo = LocalAlarmRepository(
      AlarmLocalDataSource(AppDatabase.withDatabase(db)),
      scheduler,
    );
  });

  tearDown(() => db.close());

  const alarm = Alarm(
    id: 'uuid-1',
    label: 'Dậy',
    hour: 6,
    minute: 30,
    repeatDays: {Weekday.monday, Weekday.tuesday},
  );

  test('upsert persists the alarm and schedules it when enabled', () async {
    await repo.upsertAlarm(alarm);

    final all = await repo.getAlarms();
    expect(all, hasLength(1));
    expect(all.single.label, 'Dậy');
    expect(all.single.repeatDays, {Weekday.monday, Weekday.tuesday});
    expect(scheduler.scheduled, [AlarmScheduler.stableId('uuid-1')]);
  });

  test('disabling cancels the OS alarm but keeps the row', () async {
    await repo.upsertAlarm(alarm);
    await repo.setEnabled('uuid-1', enabled: false);

    final stored = await repo.getAlarmById('uuid-1');
    expect(stored, isNotNull);
    expect(stored!.isEnabled, isFalse);
    expect(scheduler.cancelled, contains(AlarmScheduler.stableId('uuid-1')));
  });

  test('re-enabling schedules again', () async {
    await repo.upsertAlarm(alarm);
    await repo.setEnabled('uuid-1', enabled: false);
    scheduler.scheduled.clear();

    await repo.setEnabled('uuid-1', enabled: true);
    expect(scheduler.scheduled, [AlarmScheduler.stableId('uuid-1')]);
  });

  test('delete removes the row and cancels the OS alarm', () async {
    await repo.upsertAlarm(alarm);
    await repo.deleteAlarm('uuid-1');

    expect(await repo.getAlarms(), isEmpty);
    expect(scheduler.cancelled, contains(AlarmScheduler.stableId('uuid-1')));
  });

  test('upsert twice updates in place (no duplicate row)', () async {
    await repo.upsertAlarm(alarm);
    await repo.upsertAlarm(alarm.copyWith(label: 'Dậy sớm'));

    final all = await repo.getAlarms();
    expect(all, hasLength(1));
    expect(all.single.label, 'Dậy sớm');
  });
}
