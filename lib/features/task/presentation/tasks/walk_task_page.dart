import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../domain/entities/dismiss_task.dart';
import '../../domain/entities/task_result.dart';
import '../../domain/walk_detector.dart';

/// Walk [DismissTaskConfig.walkMeters] meters to dismiss. Distance is estimated
/// from real step motion (accelerometer), so you must actually get up and move.
/// Progress is shown live; success pops automatically when the target is met.
class WalkTaskPage extends StatefulWidget {
  const WalkTaskPage({super.key, required this.config});

  final DismissTaskConfig config;

  @override
  State<WalkTaskPage> createState() => _WalkTaskPageState();
}

class _WalkTaskPageState extends State<WalkTaskPage> {
  final WalkDetector _detector = WalkDetector();
  StreamSubscription<AccelerometerEvent>? _sub;
  double _meters = 0;

  @override
  void initState() {
    super.initState();
    _sub = accelerometerEventStream().listen(_onEvent, onError: (_) {});
  }

  void _onEvent(AccelerometerEvent e) {
    if (_detector.onSample(e.x, e.y, e.z)) {
      setState(() => _meters = _detector.meters);
      if (_meters >= widget.config.walkMeters) {
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
    final target = widget.config.walkMeters;
    final done = _meters.clamp(0, target.toDouble());
    final progress = target == 0 ? 1.0 : (done / target).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đi bộ để tắt'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_walk, size: 96),
            const SizedBox(height: 24),
            Text(
              '${done.round()} / $target m',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: LinearProgressIndicator(value: progress),
            ),
            const SizedBox(height: 16),
            const Text('Đứng dậy và đi cho tới khi đủ số mét!'),
          ],
        ),
      ),
    );
  }
}
