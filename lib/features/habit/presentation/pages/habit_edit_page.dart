import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/widgets/app_primary_button.dart';
import '../../../alarm_management/presentation/widgets/weekday_selector.dart';
import '../../data/notification_scheduler.dart';
import '../../domain/entities/habit.dart';
import '../providers/habit_providers.dart';
import '../widgets/habit_icon_catalog.dart';

/// Create / edit a habit: icon/color, frequency, and an optional daily
/// reminder time. Pops with `true` after a successful save or delete.
class HabitEditPage extends ConsumerStatefulWidget {
  const HabitEditPage({super.key, this.existing});

  final Habit? existing;

  @override
  ConsumerState<HabitEditPage> createState() => _HabitEditPageState();
}

class _HabitEditPageState extends ConsumerState<HabitEditPage> {
  late Habit _draft;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    _draft = widget.existing ??
        Habit(
          id: const Uuid().v4(),
          createdAt: DateTime.now(),
          color: HabitIconCatalog.palette.first,
        );
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _draft.reminderHour ?? 7, minute: _draft.reminderMinute ?? 0),
    );
    if (picked != null) {
      setState(
        () => _draft = _draft.copyWith(reminderHour: picked.hour, reminderMinute: picked.minute),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(habitRepositoryProvider).upsertHabit(_draft);
    await HabitNotificationScheduler.instance.scheduleReminder(_draft);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa thói quen?'),
        content: Text(_draft.name.isEmpty ? 'Thói quen này sẽ bị xóa.' : '"${_draft.name}" sẽ bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(habitRepositoryProvider).deleteHabit(_draft.id);
    await HabitNotificationScheduler.instance.cancelReminder(_draft.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = HabitIconCatalog.colorFor(_draft.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Thói quen mới' : 'Sửa thói quen'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa thói quen',
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: HabitIconBadge(iconKey: _draft.icon, color: selectedColor, size: 72),
          ),
          const SizedBox(height: 20),
          TextFormField(
            initialValue: _draft.name,
            decoration: const InputDecoration(labelText: 'Tên thói quen'),
            onChanged: (s) => setState(() => _draft = _draft.copyWith(name: s)),
          ),
          const SizedBox(height: 24),
          _SectionLabel(icon: Icons.emoji_objects_outlined, text: 'Biểu tượng'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final key in HabitIconCatalog.icons.keys)
                _SelectableBadge(
                  selected: _draft.icon == key,
                  color: selectedColor,
                  child: HabitIconBadge(iconKey: key, color: selectedColor, size: 44),
                  onTap: () => setState(() => _draft = _draft.copyWith(icon: key)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionLabel(icon: Icons.palette_outlined, text: 'Màu sắc'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final argb in HabitIconCatalog.palette)
                GestureDetector(
                  onTap: () => setState(() => _draft = _draft.copyWith(color: argb)),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(argb),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _draft.color == argb
                            ? theme.colorScheme.onSurface
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: _draft.color == argb
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(icon: Icons.event_repeat_outlined, text: 'Tần suất'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final f in HabitFrequencyType.values)
                ChoiceChip(
                  label: Text(f.label),
                  selected: _draft.frequencyType == f,
                  onSelected: (_) => setState(() => _draft = _draft.copyWith(frequencyType: f)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_draft.frequencyType == HabitFrequencyType.weekdays)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: WeekdaySelector(
                selected: _draft.frequencyDays,
                onChanged: (days) => setState(() => _draft = _draft.copyWith(frequencyDays: days)),
              ),
            ),
          if (_draft.frequencyType == HabitFrequencyType.weeklyCount) ...[
            Text('Số lần mỗi tuần: ${_draft.weeklyTargetCount ?? 3}',
                style: theme.textTheme.bodyMedium),
            Slider(
              value: (_draft.weeklyTargetCount ?? 3).toDouble().clamp(1, 7),
              min: 1,
              max: 7,
              divisions: 6,
              label: '${_draft.weeklyTargetCount ?? 3} lần',
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(weeklyTargetCount: v.round())),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Nhắc giờ'),
                  subtitle: Text(
                    _draft.hasReminder
                        ? '${_draft.reminderHour!.toString().padLeft(2, '0')}:'
                            '${_draft.reminderMinute!.toString().padLeft(2, '0')}'
                        : 'Tắt',
                  ),
                  value: _draft.hasReminder,
                  onChanged: (v) {
                    if (v) {
                      _pickReminderTime();
                    } else {
                      setState(() => _draft = _draft.copyWith(clearReminder: true));
                    }
                  },
                ),
                if (_draft.hasReminder)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextButton(onPressed: _pickReminderTime, child: const Text('Đổi giờ nhắc')),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: 'Lưu thói quen',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _SelectableBadge extends StatelessWidget {
  const _SelectableBadge({
    required this.selected,
    required this.color,
    required this.child,
    required this.onTap,
  });

  final bool selected;
  final Color color;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : Colors.transparent, width: 2),
        ),
        child: child,
      ),
    );
  }
}
