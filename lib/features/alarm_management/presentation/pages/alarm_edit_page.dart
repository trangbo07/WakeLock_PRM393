import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/platform/exact_alarm_permission.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../ringtone/presentation/providers/ringtone_providers.dart';
import '../../../routine/domain/entities/routine.dart';
import '../../../routine/presentation/providers/routine_providers.dart';
import '../../domain/entities/alarm.dart';
import '../providers/alarm_providers.dart';
import '../widgets/dismiss_task_selector.dart';
import '../widgets/weekday_selector.dart';

/// Create / edit a single alarm. Pops with `true` after a successful save or
/// delete so the list page knows to refresh.
class AlarmEditPage extends ConsumerStatefulWidget {
  const AlarmEditPage({super.key, this.existing});

  final Alarm? existing;

  @override
  ConsumerState<AlarmEditPage> createState() => _AlarmEditPageState();
}

class _AlarmEditPageState extends ConsumerState<AlarmEditPage> {
  late Alarm _draft;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _draft = widget.existing ??
        Alarm(
          id: const Uuid().v4(),
          label: '',
          hour: now.hour,
          minute: now.minute,
        );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _draft.hour, minute: _draft.minute),
    );
    if (picked != null) {
      setState(
        () => _draft = _draft.copyWith(hour: picked.hour, minute: picked.minute),
      );
    }
  }

  // Distinguishes "explicitly chose Không chọn" from "dismissed the sheet
  // without picking anything" (both would otherwise surface as null).
  static const _noRoutineSentinel = '__none__';

  Future<void> _pickRoutine() async {
    final routines = await ref.read(routineListProvider.future);
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Không chọn'),
              onTap: () => Navigator.pop(ctx, _noRoutineSentinel),
            ),
            for (final r in routines)
              ListTile(
                title: Text(r.name.isEmpty ? 'Routine (${r.steps.length} bước)' : r.name),
                subtitle: Text('${r.steps.length} bước'),
                onTap: () => Navigator.pop(ctx, r.id),
              ),
          ],
        ),
      ),
    );
    if (!mounted || picked == null) return; // dismissed without choosing
    setState(() => _draft = _draft.copyWith(
          routineId: picked == _noRoutineSentinel ? null : picked,
          clearRoutineId: picked == _noRoutineSentinel,
        ));
  }

  Future<void> _pickRingtone() async {
    final picked = await Navigator.pushNamed(
      context,
      AppRouter.ringtonePicker,
      arguments: _draft.ringtoneId,
    );
    if (picked is String) {
      setState(() => _draft = _draft.copyWith(ringtoneId: picked));
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    // Without exact-alarm permission Android silently degrades to inexact
    // timing — pointless for an alarm clock, so block the save.
    final allowed = await ensureExactAlarmPermission();
    if (!mounted) return;
    if (!allowed) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cần cấp quyền "Báo thức và lời nhắc" để đặt báo thức'),
        ),
      );
      return;
    }
    // Resolve the 'default' sentinel to a concrete system-alarm URI so the
    // ringing notification can play it directly (it can't play 'default').
    if (_draft.ringtoneId.isEmpty || _draft.ringtoneId == 'default') {
      final uri = await ref.read(systemRingtoneChannelProvider).defaultAlarmUri();
      if (uri.isNotEmpty) _draft = _draft.copyWith(ringtoneId: uri);
    }
    await ref.read(alarmRepositoryProvider).upsertAlarm(_draft);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa báo thức?'),
        content: Text(_draft.label.isEmpty ? 'Báo thức này sẽ bị xóa.' : '"${_draft.label}" sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(alarmRepositoryProvider).deleteAlarm(_draft.id);
    if (mounted) Navigator.pop(context, true);
  }

  /// Display name of the currently selected routine, if any.
  String _routineName() {
    final id = _draft.routineId;
    if (id == null) return 'Không chọn';
    final routines = ref.watch(routineListProvider).value ?? const <MorningRoutine>[];
    for (final r in routines) {
      if (r.id == id) return r.name.isEmpty ? 'Routine (${r.steps.length} bước)' : r.name;
    }
    return 'Đã xóa';
  }

  /// Display name of the currently selected ringtone. Falls back to a friendly
  /// label for the default sentinel while the catalog is still loading.
  String _ringtoneName() {
    final ringtones = ref.watch(ringtoneListProvider).value ?? const [];
    for (final r in ringtones) {
      if (r.uri == _draft.ringtoneId) return r.name;
    }
    return _draft.ringtoneId == 'default'
        ? 'Mặc định hệ thống'
        : _draft.ringtoneId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Báo thức mới' : 'Sửa báo thức'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa báo thức',
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  DateTimeUtils.formatHm(_draft.hour, _draft.minute),
                  style: theme.textTheme.displayLarge,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _draft.label,
            decoration: const InputDecoration(labelText: 'Tên báo thức'),
            onChanged: (s) => _draft = _draft.copyWith(label: s),
          ),
          const SizedBox(height: 24),
          Text('Lặp lại', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          WeekdaySelector(
            selected: _draft.repeatDays,
            onChanged: (days) =>
                setState(() => _draft = _draft.copyWith(repeatDays: days)),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.music_note),
            title: const Text('Nhạc chuông'),
            subtitle: Text(_ringtoneName()),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickRingtone,
          ),
          const SizedBox(height: 16),
          Text('Nhiệm vụ tắt báo thức', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          DismissTaskSelector(
            value: _draft.dismissTask,
            onChanged: (config) =>
                setState(() => _draft = _draft.copyWith(dismissTask: config)),
          ),
          const SizedBox(height: 24),
          Text('Báo lại (snooze)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Số phút mỗi lần báo lại: ${_draft.snoozeMinutes}',
              style: theme.textTheme.bodyMedium),
          Slider(
            value: _draft.snoozeMinutes.toDouble().clamp(1, 15),
            min: 1,
            max: 15,
            divisions: 14,
            label: '${_draft.snoozeMinutes} phút',
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(snoozeMinutes: v.round())),
          ),
          Text(
            _draft.maxSnoozeCount == 0
                ? 'Số lần báo lại tối đa: Tắt'
                : 'Số lần báo lại tối đa: ${_draft.maxSnoozeCount}',
            style: theme.textTheme.bodyMedium,
          ),
          Slider(
            value: _draft.maxSnoozeCount.toDouble().clamp(0, 5),
            min: 0,
            max: 5,
            divisions: 5,
            label: _draft.maxSnoozeCount == 0 ? 'Tắt' : '${_draft.maxSnoozeCount} lần',
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(maxSnoozeCount: v.round())),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.checklist_rtl),
            title: const Text('Routine sau khi thức dậy'),
            subtitle: Text(_routineName()),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickRoutine,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rung'),
            value: _draft.vibrate,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(vibrate: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Chặn giảm âm lượng'),
            subtitle: const Text('Không thể vặn nhỏ khi đang reo'),
            value: _draft.volumeLock,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(volumeLock: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tăng dần âm lượng'),
            value: _draft.escalateVolume,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(escalateVolume: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Đèn flash nhấp nháy'),
            subtitle: const Text('Chớp đèn flash + màn hình khi reo'),
            value: _draft.flashlight,
            onChanged: (v) =>
                setState(() => _draft = _draft.copyWith(flashlight: v)),
          ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: 'Lưu báo thức',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
