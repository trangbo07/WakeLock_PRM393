import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../domain/entities/dismiss_task.dart';
import '../../domain/entities/task_result.dart';
import '../../domain/shake_detector.dart';

/// Shake the phone [DismissTaskConfig.shakeCount] times to dismiss. Progress is
/// shown live; success pops automatically when the target count is reached.
class ShakeTaskPage extends StatefulWidget {
  const ShakeTaskPage({super.key, required this.config});

  final DismissTaskConfig config;

  @override
  State<ShakeTaskPage> createState() => _ShakeTaskPageState();
}

class _ShakeTaskPageState extends State<ShakeTaskPage> {
  final ShakeDetector _detector = ShakeDetector();
  StreamSubscription<AccelerometerEvent>? _sub;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream().listen(_onEvent, onError: (_) {});
  }

  void _onEvent(AccelerometerEvent e) {
    if (_detector.onSample(e.x, e.y, e.z)) {
      setState(() => _count = _detector.count);
      if (_count >= widget.config.shakeCount) {
        _sub?.cancel();
        Navigator.pop(context, const TaskResult.success());
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.config.shakeCount;
    final progress = target == 0 ? 1.0 : (_count / target).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lắc máy để tắt'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.vibration, size: 96),
            const SizedBox(height: 24),
            Text(
              '$_count / $target',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: LinearProgressIndicator(value: progress),
            ),
            const SizedBox(height: 16),
            const Text('Lắc mạnh điện thoại!'),
          ],
        ),
      ),
    );
  }
}
