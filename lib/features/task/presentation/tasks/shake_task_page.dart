import 'package:flutter/material.dart';

import '../../domain/entities/dismiss_task.dart';
import '../../domain/entities/task_result.dart';

/// Shake the phone [DismissTaskConfig.shakeCount] times to dismiss.
/// TODO: use sensors_plus accelerometer stream to count shakes and show a
/// progress indicator; pop success when the target count is reached.
class ShakeTaskPage extends StatelessWidget {
  const ShakeTaskPage({super.key, required this.config});

  final DismissTaskConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lắc máy để tắt')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('TODO: lắc ${config.shakeCount} lần'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, const TaskResult.success()),
              child: const Text('(tạm) Hoàn thành'),
            ),
          ],
        ),
      ),
    );
  }
}
