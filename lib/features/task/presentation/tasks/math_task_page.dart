import 'package:flutter/material.dart';

import '../../domain/entities/dismiss_task.dart';
import '../../domain/entities/task_result.dart';

/// Solve [DismissTaskConfig.difficulty] math problems to dismiss the alarm.
/// TODO: generate problems, validate answers, count correct before success.
class MathTaskPage extends StatelessWidget {
  const MathTaskPage({super.key, required this.config});

  final DismissTaskConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giải toán để tắt')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('TODO: ${config.difficulty} phép toán'),
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
