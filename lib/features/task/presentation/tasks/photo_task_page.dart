import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/dismiss_task.dart';
import '../../domain/entities/task_result.dart';
import '../providers/task_providers.dart';

/// Take a photo of the target ([DismissTaskConfig.photoTag]) to dismiss.
/// Gemini checks the photo actually shows that object; if there's no target
/// or Gemini is unavailable, any photo is accepted.
class PhotoTaskPage extends ConsumerStatefulWidget {
  const PhotoTaskPage({super.key, required this.config});

  final DismissTaskConfig config;

  @override
  ConsumerState<PhotoTaskPage> createState() => _PhotoTaskPageState();
}

class _PhotoTaskPageState extends ConsumerState<PhotoTaskPage> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;
  String? _rejected; // set when Gemini says the target isn't in the photo

  String get _target => widget.config.photoTag?.isNotEmpty ?? false
      ? widget.config.photoTag!
      : 'mục tiêu đã hẹn';

  Future<void> _capture() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _rejected = null;
    });
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
      );
      if (!mounted || photo == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      // No target to verify → accept any photo.
      final hasTarget = widget.config.photoTag?.isNotEmpty ?? false;
      var ok = true;
      if (hasTarget) {
        final bytes = await photo.readAsBytes();
        ok = await ref
            .read(geminiVisionServiceProvider)
            .matchesLabel(bytes, widget.config.photoTag!);
      }
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, const TaskResult.success());
        return;
      }
      setState(() {
        _busy = false;
        _rejected = _target;
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chụp ảnh để tắt'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 96),
              const SizedBox(height: 24),
              Text(
                'Chụp ảnh: $_target',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (_rejected != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Chưa thấy "$_rejected" trong ảnh — chụp lại nhé',
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Đang kiểm tra ảnh...'),
                    ],
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: _capture,
                  icon: const Icon(Icons.camera),
                  label: const Text('Mở camera'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
