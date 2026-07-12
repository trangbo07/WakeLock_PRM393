import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/ringtone.dart';
import '../providers/ringtone_providers.dart';

/// Lets the user pick an alarm ringtone from the device's system alarm sounds
/// or a file they add themselves, with a per-item preview. Pops with the
/// selected ringtone uri (used as the stable id on an alarm).
///
/// Pass the currently-selected uri as the route argument to show a check mark.
class RingtonePickerPage extends ConsumerStatefulWidget {
  const RingtonePickerPage({super.key, this.selectedId});

  final String? selectedId;

  @override
  ConsumerState<RingtonePickerPage> createState() => _RingtonePickerPageState();
}

class _RingtonePickerPageState extends ConsumerState<RingtonePickerPage> {
  // Captured so dispose() can stop preview without touching `ref` during
  // widget-tree finalization (Riverpod forbids that).
  late final _channel = ref.read(systemRingtoneChannelProvider);
  String? _playingUri;
  bool _adding = false;

  @override
  void dispose() {
    // Best-effort stop; the channel call is fire-and-forget on teardown.
    _channel.stopPreview();
    super.dispose();
  }

  Future<void> _togglePreview(Ringtone r) async {
    final channel = _channel;
    if (_playingUri == r.uri) {
      await _stop();
      return;
    }
    setState(() => _playingUri = r.uri);
    try {
      await channel.preview(r.uri);
    } catch (e) {
      AppLogger.w('Ringtone preview failed: $e');
      if (mounted) setState(() => _playingUri = null);
    }
  }

  Future<void> _stop() async {
    try {
      await _channel.stopPreview();
    } catch (_) {}
    if (mounted) setState(() => _playingUri = null);
  }

  Future<void> _select(String uri) async {
    await _stop();
    if (mounted) Navigator.pop(context, uri);
  }

  Future<void> _addCustom() async {
    setState(() => _adding = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      final path = result?.files.single.path;
      if (path != null) {
        await ref.read(ringtoneRepositoryProvider).addCustom(path);
        ref.invalidate(ringtoneListProvider);
      }
    } catch (e) {
      AppLogger.w('Add custom ringtone failed: $e');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _removeCustom(Ringtone r) async {
    if (_playingUri == r.uri) await _stop();
    await ref.read(ringtoneRepositoryProvider).removeCustom(r.uri);
    ref.invalidate(ringtoneListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final ringtones = ref.watch(ringtoneListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho nhạc chuông'),
        actions: [
          IconButton(
            icon: _adding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.library_add),
            tooltip: 'Thêm nhạc của bạn',
            onPressed: _adding ? null : _addCustom,
          ),
        ],
      ),
      body: ringtones.when(
        data: (list) => ListView(
          children: [
            for (final r in list)
              ListTile(
                leading: Icon(r.isCustom ? Icons.library_music : Icons.music_note),
                title: Text(r.name),
                subtitle: r.isCustom ? const Text('Nhạc của bạn') : null,
                onTap: () => _select(r.uri),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _playingUri == r.uri
                            ? Icons.stop_circle
                            : Icons.play_circle_outline,
                      ),
                      tooltip: _playingUri == r.uri ? 'Dừng' : 'Nghe thử',
                      onPressed: () => _togglePreview(r),
                    ),
                    if (r.isCustom)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Xóa',
                        onPressed: () => _removeCustom(r),
                      )
                    else if (widget.selectedId == r.uri)
                      Icon(Icons.check, color: theme.colorScheme.primary),
                  ],
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}
