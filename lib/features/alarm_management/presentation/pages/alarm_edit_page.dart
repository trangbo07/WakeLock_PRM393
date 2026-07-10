import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/alarm.dart';

/// Create / edit a single alarm.
///
/// TODO (kickoff scaffold):
///   - TimePicker for [Alarm.hour]/[Alarm.minute]
///   - WeekdaySelector for [Alarm.repeatDays]
///   - Label text field
///   - Ringtone picker (open RingtonePickerPage)
///   - Dismiss-task selector (math / shake / QR / photo)
///   - Volume-lock & escalate toggles
///   - Save -> alarmRepositoryProvider.upsertAlarm + schedule
class AlarmEditPage extends ConsumerStatefulWidget {
  const AlarmEditPage({super.key, this.existing});

  final Alarm? existing;

  @override
  ConsumerState<AlarmEditPage> createState() => _AlarmEditPageState();
}

class _AlarmEditPageState extends ConsumerState<AlarmEditPage> {
  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'Báo thức mới' : 'Sửa báo thức')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'TODO: form đặt giờ, ngày lặp, tên, nhạc chuông, nhiệm vụ tắt.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
