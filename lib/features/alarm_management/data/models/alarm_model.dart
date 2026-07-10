import '../../../task/domain/entities/dismiss_task.dart';
import '../../domain/entities/alarm.dart';
import '../../domain/entities/weekday.dart';

/// Data-layer representation of [Alarm] with JSON (de)serialization for
/// Supabase rows and the local cache. Column names use snake_case to match a
/// typical Postgres schema.
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
        dismissTask: a.dismissTask,
      );

  factory AlarmModel.fromJson(Map<String, dynamic> json) => AlarmModel(
        id: json['id'] as String,
        label: (json['label'] as String?) ?? '',
        hour: (json['hour'] as num).toInt(),
        minute: (json['minute'] as num).toInt(),
        repeatDays: ((json['repeat_days'] as List?) ?? const [])
            .map((e) => Weekday.fromValue((e as num).toInt()))
            .toSet(),
        isEnabled: (json['is_enabled'] as bool?) ?? true,
        ringtoneId: (json['ringtone_id'] as String?) ?? 'default',
        vibrate: (json['vibrate'] as bool?) ?? true,
        volumeLock: (json['volume_lock'] as bool?) ?? true,
        escalateVolume: (json['escalate_volume'] as bool?) ?? true,
        dismissTask:
            _taskFromJson(json['dismiss_task'] as Map<String, dynamic>?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'hour': hour,
        'minute': minute,
        'repeat_days': repeatDays.map((w) => w.value).toList(),
        'is_enabled': isEnabled,
        'ringtone_id': ringtoneId,
        'vibrate': vibrate,
        'volume_lock': volumeLock,
        'escalate_volume': escalateVolume,
        'dismiss_task': _taskToJson(dismissTask),
      };

  static DismissTaskConfig _taskFromJson(Map<String, dynamic>? json) {
    if (json == null) return const DismissTaskConfig();
    return DismissTaskConfig(
      type: DismissTaskType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DismissTaskType.math,
      ),
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 3,
      shakeCount: (json['shake_count'] as num?)?.toInt() ?? 50,
      qrPayload: json['qr_payload'] as String?,
      photoTag: json['photo_tag'] as String?,
    );
  }

  static Map<String, dynamic> _taskToJson(DismissTaskConfig c) => {
        'type': c.type.name,
        'difficulty': c.difficulty,
        'shake_count': c.shakeCount,
        'qr_payload': c.qrPayload,
        'photo_tag': c.photoTag,
      };
}
