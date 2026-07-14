import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/logger.dart';
import '../../../alarm_management/domain/entities/alarm.dart';
import '../../domain/entities/morning_photo.dart';
import '../providers/morning_photo_providers.dart';

/// Camera → review (caption / mood / weather / privacy) → save. Pushed by
/// `alarm_ringing_page.dart` right after a successful dismiss (bonus step —
/// has a "Bỏ qua" escape hatch at every point, pops `true` only if a photo
/// was actually saved).
class MorningPhotoCapturePage extends ConsumerStatefulWidget {
  const MorningPhotoCapturePage({super.key, this.alarm});

  /// The alarm that triggered this capture, if opened from the wake chain.
  /// Null when opened manually (e.g. from the Morning Photo gallery tab).
  final Alarm? alarm;

  @override
  ConsumerState<MorningPhotoCapturePage> createState() => _MorningPhotoCapturePageState();
}

class _MorningPhotoCapturePageState extends ConsumerState<MorningPhotoCapturePage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  XFile? _photo;
  String? _mood;
  String? _weather;
  PhotoPrivacy _privacy = PhotoPrivacy.private;
  bool _saving = false;

  static const _moods = ['😴', '🙂', '😃', '😫'];
  static const _weathers = ['☀️', '☁️', '🌧️', '❄️'];

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1280);
      if (photo != null && mounted) setState(() => _photo = photo);
    } catch (e) {
      AppLogger.w('Morning photo capture failed: $e');
    }
  }

  Future<void> _save() async {
    final photo = _photo;
    if (photo == null) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final alarm = widget.alarm;
    final alarmTime =
        alarm == null ? null : DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
    final entity = MorningPhoto(
      id: const Uuid().v4(),
      path: photo.path,
      createdAt: now,
      caption: _captionController.text.trim(),
      mood: _mood,
      weather: _weather,
      wakeTime: now,
      alarmTime: alarmTime,
      privacy: _privacy,
    );
    try {
      await ref.read(morningPhotoRepositoryProvider).save(entity);
      ref.invalidate(morningPhotoListProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      AppLogger.w('Morning photo save failed: $e');
      if (mounted) setState(() => _saving = false);
    }
  }

  void _skip() => Navigator.pop(context, false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ảnh buổi sáng'),
        automaticallyImplyLeading: false,
        actions: [TextButton(onPressed: _skip, child: const Text('Bỏ qua'))],
      ),
      body: _photo == null ? _buildCameraPrompt(theme) : _buildReviewForm(theme),
    );
  }

  Widget _buildCameraPrompt(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 96),
            const SizedBox(height: 24),
            Text('Chụp một tấm ảnh buổi sáng nay?',
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _capture,
              icon: const Icon(Icons.camera),
              label: const Text('Mở camera'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(_photo!.path), height: 260, width: double.infinity, fit: BoxFit.cover),
        ),
        TextButton.icon(
          onPressed: _capture,
          icon: const Icon(Icons.refresh),
          label: const Text('Chụp lại'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _captionController,
          decoration: const InputDecoration(labelText: 'Chú thích'),
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        Text('Cảm xúc', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final m in _moods)
              ChoiceChip(
                label: Text(m, style: const TextStyle(fontSize: 20)),
                selected: _mood == m,
                onSelected: (_) => setState(() => _mood = _mood == m ? null : m),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Thời tiết', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final w in _weathers)
              ChoiceChip(
                label: Text(w, style: const TextStyle(fontSize: 20)),
                selected: _weather == w,
                onSelected: (_) => setState(() => _weather = _weather == w ? null : w),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Quyền riêng tư', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in PhotoPrivacy.values)
              ChoiceChip(
                label: Text(_privacyLabel(p)),
                selected: _privacy == p,
                onSelected: (_) => setState(() => _privacy = p),
              ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Đang lưu...' : 'Lưu ảnh'),
        ),
      ],
    );
  }

  String _privacyLabel(PhotoPrivacy p) => switch (p) {
        PhotoPrivacy.private => 'Riêng tư',
        PhotoPrivacy.close => 'Thân thiết',
        PhotoPrivacy.friends => 'Bạn bè',
        PhotoPrivacy.selected => 'Tùy chọn',
      };
}
