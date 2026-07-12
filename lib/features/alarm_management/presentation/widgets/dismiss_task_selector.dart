import 'package:flutter/material.dart';

import '../../../task/domain/entities/dismiss_task.dart';

/// Picks the task the user must complete to silence the alarm, plus the
/// parameters relevant to the chosen type (difficulty, shake count, ...).
class DismissTaskSelector extends StatelessWidget {
  const DismissTaskSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DismissTaskConfig value;
  final ValueChanged<DismissTaskConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          children: [
            for (final type in DismissTaskType.values)
              ChoiceChip(
                label: Text(type.label),
                selected: value.type == type,
                onSelected: (_) => onChanged(value.copyWith(type: type)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildParams(context),
      ],
    );
  }

  /// Parameter editor for the selected type. Text fields get a per-type key so
  /// switching types resets their internal state.
  Widget _buildParams(BuildContext context) {
    switch (value.type) {
      case DismissTaskType.none:
        return const SizedBox.shrink();
      case DismissTaskType.math:
        return _LabeledSlider(
          label: 'Số câu toán: ${value.difficulty}',
          value: value.difficulty.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: (v) => onChanged(value.copyWith(difficulty: v.round())),
        );
      case DismissTaskType.shake:
        return _LabeledSlider(
          label: 'Số lần lắc: ${value.shakeCount}',
          value: value.shakeCount.toDouble(),
          min: 10,
          max: 100,
          divisions: 9,
          onChanged: (v) => onChanged(value.copyWith(shakeCount: v.round())),
        );
      case DismissTaskType.qrScan:
        return TextFormField(
          key: const ValueKey('qr_payload'),
          initialValue: value.qrPayload,
          decoration: const InputDecoration(
            labelText: 'Nội dung mã QR',
            helperText: 'In mã QR và dán ở nơi bạn buộc phải đi tới (nhà tắm...)',
          ),
          onChanged: (s) => onChanged(value.copyWith(qrPayload: s)),
        );
      case DismissTaskType.photo:
        return TextFormField(
          key: const ValueKey('photo_tag'),
          initialValue: value.photoTag,
          decoration: const InputDecoration(
            labelText: 'Vật thể cần chụp',
            helperText: 'Ví dụ: bồn rửa mặt, cây trước nhà...',
          ),
          onChanged: (s) => onChanged(value.copyWith(photoTag: s)),
        );
    }
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
