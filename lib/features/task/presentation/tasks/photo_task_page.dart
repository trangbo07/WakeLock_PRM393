import 'package:flutter/material.dart';

import '../../domain/entities/dismiss_task.dart';
import '../../domain/entities/task_result.dart';

/// Take a photo of a target (e.g. a plant) to dismiss.
/// TODO: use image_picker/camera to capture; optionally verify against
/// [DismissTaskConfig.photoTag] with an on-device classifier; pop success.
class PhotoTaskPage extends StatelessWidget {
  const PhotoTaskPage({super.key, required this.config});

  final DismissTaskConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chụp ảnh để tắt')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('TODO: chụp "${config.photoTag ?? 'mục tiêu'}"'),
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
