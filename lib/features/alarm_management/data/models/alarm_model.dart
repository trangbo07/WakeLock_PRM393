import 'dart:convert';

import '../../../task/domain/entities/dismiss_task.dart';
import '../../domain/entities/alarm.dart';
import '../../domain/entities/weekday.dart';

/// Data-layer representation of [Alarm] with (de)serialization for SQLite
/// rows. Column names use snake_case; booleans map to INTEGER 0/1 and
/// list/object fields to JSON TEXT (see core/database/app_database.dart).
class AlarmModel extends Alarm {
  const AlarmModel({
    required super.id,
    required super.label,
    required super.hour,
    required super.minute,
    super.repeatDays,
    super.isEnabled,
    super.ringtoneId,
    super.vibrate,
    super.volumeLock,
    super.escalateVolume,
    super.flashlight,
    super.dismissTask,
  });

  factory AlarmModel.fromEntity(Alarm a) => AlarmModel(
        id: a.id,
        label: a.label,
        hour: a.hour,
        minute: a.minute,
        repeatDays: a.repeatDays,
        isEnabled: a.isEnabled,
        ringtoneId: a.ringtoneId,
        vibrate: a.vibrate,
        volumeLock: a.volumeLock,
        escalateVolume: a.escalateVolume,
        flashlight: a.flashlight,
        dismissTask: a.dismissTask,
      );

  factory AlarmModel.fromDbRow(Map<String, dynamic> row) => AlarmModel(
        id: row['id'] as String,
        label: (row['label'] as String?) ?? '',
        hour: (row['hour'] as num).toInt(),
        minute: (row['minute'] as num).toInt(),
        repeatDays:
            (jsonDecode((row['repeat_days'] as String?) ?? '[]') as List)
                .map((e) => Weekday.fromValue((e as num).toInt()))
                .toSet(),
        isEnabled: ((row['is_enabled'] as num?) ?? 1) != 0,
        ringtoneId: (row['ringtone_id'] as String?) ?? 'default',
        vibrate: ((row['vibrate'] as num?) ?? 1) != 0,
        volumeLock: ((row['volume_lock'] as num?) ?? 1) != 0,
        escalateVolume: ((row['escalate_volume'] as num?) ?? 1) != 0,
        flashlight: ((row['flashlight'] as num?) ?? 1) != 0,
        dismissTask: _taskFromJson(row['dismiss_task'] as String?),
      );

  Map<String, Object?> toDbRow() => {
        'id': id,
        'label': label,
        'hour': hour,
        'minute': minute,
        'repeat_days': jsonEncode(repeatDays.map((w) => w.value).toList()),
        'is_enabled': isEnabled ? 1 : 0,
        'ringtone_id': ringtoneId,
        'vibrate': vibrate ? 1 : 0,
        'volume_lock': volumeLock ? 1 : 0,
        'escalate_volume': escalateVolume ? 1 : 0,
        'flashlight': flashlight ? 1 : 0,
        'dismiss_task': jsonEncode(_taskToJson(dismissTask)),
      };

  static DismissTaskConfig _taskFromJson(String? raw) {
    if (raw == null || raw.isEmpty) return const DismissTaskConfig();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return DismissTaskConfig(
      type: DismissTaskType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DismissTaskType.math,
      ),
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 3,
      shakeCount: (json['shake_count'] as num?)?.toInt() ?? 50,
      walkMeters: (json['walk_meters'] as num?)?.toInt() ?? 30,
      photoTag: json['photo_tag'] as String?,
    );
  }

  static Map<String, dynamic> _taskToJson(DismissTaskConfig c) => {
        'type': c.type.name,
        'difficulty': c.difficulty,
        'shake_count': c.shakeCount,
        'walk_meters': c.walkMeters,
        'photo_tag': c.photoTag,
      };
}
