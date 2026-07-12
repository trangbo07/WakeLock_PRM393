import 'package:flutter/material.dart';

import '../domain/entities/dismiss_task.dart';
import '../domain/entities/task_result.dart';
import 'tasks/math_task_page.dart';
import 'tasks/photo_task_page.dart';
import 'tasks/shake_task_page.dart';

/// Dispatches to the correct dismiss-task screen based on [config].
/// Each task page pops with a [TaskResult] when finished.
class TaskRunnerPage extends StatelessWidget {
  const TaskRunnerPage({super.key, required this.config});

  final DismissTaskConfig config;

  @override
  Widget build(BuildContext context) {
    switch (config.type) {
      case DismissTaskType.math:
        return MathTaskPage(config: config);
      case DismissTaskType.shake:
        return ShakeTaskPage(config: config);
      case DismissTaskType.photo:
        return PhotoTaskPage(config: config);
      case DismissTaskType.none:
        return Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () =>
                  Navigator.pop(context, const TaskResult.success()),
              child: const Text('Tắt báo thức'),
            ),
          ),
        );
    }
  }
}
