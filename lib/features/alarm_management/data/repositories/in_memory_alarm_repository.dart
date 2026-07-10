import '../../../task/domain/entities/dismiss_task.dart';
import '../../domain/entities/alarm.dart';
import '../../domain/entities/weekday.dart';
import '../../domain/repositories/alarm_repository.dart';

/// In-memory repository seeded with demo alarms.
///
/// Used when Supabase is not configured (offline UI/dev mode) so the interface
/// is fully viewable without a backend. Not persisted — resets on restart.
class InMemoryAlarmRepository implements AlarmRepository {
  InMemoryAlarmRepository(this._alarms);

  final List<Alarm> _alarms;

  factory InMemoryAlarmRepository.demo() => InMemoryAlarmRepository([
        const Alarm(
          id: '1',
          label: 'Dậy đi học',
          hour: 6,
          minute: 30,
          repeatDays: {
            Weekday.monday,
            Weekday.tuesday,
            Weekday.wednesday,
            Weekday.thursday,
            Weekday.friday,
          },
          ringtoneId: 'siren',
          dismissTask: DismissTaskConfig(
            type: DismissTaskType.math,
            difficulty: 3,
          ),
        ),
        const Alarm(
          id: '2',
          label: 'Uống nước',
          hour: 9,
          minute: 0,
          isEnabled: false,
          dismissTask: DismissTaskConfig(
            type: DismissTaskType.shake,
            shakeCount: 50,
          ),
        ),
        const Alarm(
          id: '3',
          label: 'Ngủ trưa dậy',
          hour: 13,
          minute: 15,
          repeatDays: {Weekday.saturday, Weekday.sunday},
          ringtoneId: 'nuclear',
          dismissTask: DismissTaskConfig(
            type: DismissTaskType.qrScan,
            qrPayload: 'bathroom',
          ),
        ),
      ]);

  @override
  Future<List<Alarm>> getAlarms() async => List.unmodifiable(_alarms);

  @override
  Future<Alarm?> getAlarmById(String id) async {
    for (final a in _alarms) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  Future<void> upsertAlarm(Alarm alarm) async {
    final i = _alarms.indexWhere((a) => a.id == alarm.id);
    if (i >= 0) {
      _alarms[i] = alarm;
    } else {
      _alarms.add(alarm);
    }
  }

  @override
  Future<void> deleteAlarm(String id) async {
    _alarms.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> setEnabled(String id, {required bool enabled}) async {
    final i = _alarms.indexWhere((a) => a.id == id);
    if (i >= 0) _alarms[i] = _alarms[i].copyWith(isEnabled: enabled);
  }
}
