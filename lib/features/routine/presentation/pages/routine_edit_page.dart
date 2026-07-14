import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/widgets/app_primary_button.dart';
import '../../domain/entities/routine.dart';
import '../providers/routine_providers.dart';

/// Create / edit a morning routine: name + reorderable step list. Pops with
/// `true` after a successful save or delete.
class RoutineEditPage extends ConsumerStatefulWidget {
  const RoutineEditPage({super.key, this.existing});

  final MorningRoutine? existing;

  @override
  ConsumerState<RoutineEditPage> createState() => _RoutineEditPageState();
}

class _RoutineEditPageState extends ConsumerState<RoutineEditPage> {
  late MorningRoutine _draft;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    _draft = widget.existing ??
        MorningRoutine(id: const Uuid().v4(), createdAt: DateTime.now());
  }

  void _addStep(RoutineStepType type) {
    setState(() {
      _draft = _draft.copyWith(steps: [
        ..._draft.steps,
        RoutineStep(id: const Uuid().v4(), type: type, position: _draft.steps.length),
      ]);
    });
  }

  void _removeStep(String stepId) {
    setState(() {
      _draft = _draft.copyWith(
        steps: _draft.steps.where((s) => s.id != stepId).toList(),
      );
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final steps = [..._draft.steps];
      if (newIndex > oldIndex) newIndex -= 1;
      final moved = steps.removeAt(oldIndex);
      steps.insert(newIndex, moved);
      _draft = _draft.copyWith(
        steps: [for (var i = 0; i < steps.length; i++) steps[i].copyWith(position: i)],
      );
    });
  }

  void _updateDuration(String stepId, int seconds) {
    setState(() {
      _draft = _draft.copyWith(
        steps: [
          for (final s in _draft.steps)
            if (s.id == stepId) s.copyWith(durationSeconds: seconds) else s,
        ],
      );
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(routineRepositoryProvider).upsertRoutine(_draft);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa routine?'),
        content: Text(_draft.name.isEmpty ? 'Routine này sẽ bị xóa.' : '"${_draft.name}" sẽ bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(routineRepositoryProvider).deleteRoutine(_draft.id);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _pickStepType() async {
    final type = await showModalBottomSheet<RoutineStepType>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in RoutineStepType.values)
              ListTile(title: Text(t.label), onTap: () => Navigator.pop(ctx, t)),
          ],
        ),
      ),
    );
    if (type != null) _addStep(type);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Routine mới' : 'Sửa routine'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa routine',
              onPressed: _delete,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              initialValue: _draft.name,
              decoration: const InputDecoration(labelText: 'Tên routine'),
              onChanged: (s) => _draft = _draft.copyWith(name: s),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Các bước', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickStepType,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm bước'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _draft.steps.isEmpty
                ? Center(
                    child: Text('Chưa có bước nào',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _draft.steps.length,
                    onReorder: _reorder,
                    itemBuilder: (_, i) {
                      final step = _draft.steps[i];
                      return Card(
                        key: ValueKey(step.id),
                        child: ListTile(
                          leading: const Icon(Icons.drag_indicator),
                          title: Text(step.type.label),
                          subtitle: Slider(
                            value: step.durationSeconds.clamp(0, 600).toDouble(),
                            min: 0,
                            max: 600,
                            divisions: 20,
                            label: step.durationSeconds == 0
                                ? 'Không hẹn giờ'
                                : '${step.durationSeconds}s',
                            onChanged: (v) => _updateDuration(step.id, v.round()),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeStep(step.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppPrimaryButton(
              label: 'Lưu routine',
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}
