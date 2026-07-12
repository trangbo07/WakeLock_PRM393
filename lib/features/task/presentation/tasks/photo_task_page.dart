import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/dismiss_task.dart';
import '../../domain/entities/task_result.dart';

/// Take a photo of a target (e.g. a plant) to dismiss. Taking any photo counts
/// as success — the target [DismissTaskConfig.photoTag] is a hint to the user;
/// on-device object recognition is a possible future enhancement.
class PhotoTaskPage extends StatefulWidget {
  const PhotoTaskPage({super.key, required this.config});

  final DismissTaskConfig config;

  @override
  State<PhotoTaskPage> createState() => _PhotoTaskPageState();
}

class _PhotoTaskPageState extends State<PhotoTaskPage> {
  final ImagePicker _picker = ImagePicker();
  bool _capturing = false;

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
      );
      if (!mounted) return;
      if (photo != null) {
        Navigator.pop(context, const TaskResult.success());
        return;
      }
    } catch (_) {
      // Camera unavailable / cancelled — fall through to let the user retry.
    }
    if (mounted) setState(() => _capturing = false);
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.config.photoTag?.isNotEmpty ?? false
        ? widget.config.photoTag!
        : 'mục tiêu đã hẹn';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chụp ảnh để tắt'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 96),
            const SizedBox(height: 24),
            Text(
              'Chụp ảnh: $target',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _capturing ? null : _capture,
              icon: const Icon(Icons.camera),
              label: const Text('Mở camera'),
            ),
          ],
        ),
      ),
    );
  }
}
