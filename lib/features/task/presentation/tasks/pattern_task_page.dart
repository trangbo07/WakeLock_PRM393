import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/dismiss_task.dart';
import '../../domain/entities/task_result.dart';

enum _Phase { showing, input }

/// Simon-Says style: watch a flashed sequence of [DismissTaskConfig.patternLength]
/// tiles, then repeat it by tapping in order. A wrong tap never fails the
/// alarm — it just restarts with a fresh sequence.
class PatternTaskPage extends StatefulWidget {
  const PatternTaskPage({super.key, required this.config});

  final DismissTaskConfig config;

  @override
  State<PatternTaskPage> createState() => _PatternTaskPageState();
}

class _PatternTaskPageState extends State<PatternTaskPage> {
  static const _tileCount = 9;

  late List<int> _sequence;
  _Phase _phase = _Phase.showing;
  int _showIndex = -1;
  int _inputIndex = 0;
  bool _wrongFlash = false;

  @override
  void initState() {
    super.initState();
    _generateAndPlay();
  }

  void _generateAndPlay() {
    final length = widget.config.patternLength.clamp(2, 15);
    final rnd = Random();
    _sequence = List.generate(length, (_) => rnd.nextInt(_tileCount));
    _inputIndex = 0;
    setState(() => _phase = _Phase.showing);
    _playSequence();
  }

  Future<void> _playSequence() async {
    for (final tile in _sequence) {
      if (!mounted) return;
      setState(() => _showIndex = tile);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _showIndex = -1);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (mounted) setState(() => _phase = _Phase.input);
  }

  void _tapTile(int index) {
    if (_phase != _Phase.input) return;
    if (index == _sequence[_inputIndex]) {
      setState(() {
        _showIndex = index;
        _inputIndex += 1;
      });
      Timer(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _showIndex = -1);
      });
      if (_inputIndex >= _sequence.length) {
        Timer(const Duration(milliseconds: 300), () {
          if (mounted) Navigator.pop(context, const TaskResult.success());
        });
      }
    } else {
      setState(() => _wrongFlash = true);
      Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() => _wrongFlash = false);
        _generateAndPlay();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Nối hình'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              _phase == _Phase.showing
                  ? 'Ghi nhớ thứ tự...'
                  : 'Chạm theo đúng thứ tự ($_inputIndex/${_sequence.length})',
              style: theme.textTheme.titleMedium,
            ),
            if (_wrongFlash) ...[
              const SizedBox(height: 8),
              Text('Sai rồi, thử lại!', style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _tileCount,
                itemBuilder: (_, i) {
                  final active = _showIndex == i;
                  final color = _wrongFlash
                      ? theme.colorScheme.errorContainer
                      : active
                          ? AppColors.primary
                          : theme.colorScheme.surfaceContainerHighest;
                  return GestureDetector(
                    onTap: () => _tapTile(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
