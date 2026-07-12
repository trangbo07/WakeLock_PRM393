import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/ringtone.dart';
import '../providers/ringtone_providers.dart';

/// Lets the user pick an alarm ringtone, with a per-item preview button so they
/// can listen before choosing. Pops with the selected ringtone id.
///
/// Pass the currently-selected id as the route argument to show a check mark.
class RingtonePickerPage extends ConsumerStatefulWidget {
  const RingtonePickerPage({super.key, this.selectedId});

  final String? selectedId;

  @override
  ConsumerState<RingtonePickerPage> createState() => _RingtonePickerPageState();
}

class _RingtonePickerPageState extends ConsumerState<RingtonePickerPage> {
  final AudioPlayer _preview = AudioPlayer();
  String? _playingId;

  @override
  void initState() {
    super.initState();
    // Auto-stop the preview when it finishes so the play icon resets.
    _preview.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(Ringtone r) async {
    // Tapping the currently-playing item stops it.
    if (_playingId == r.id) {
      await _stop();
      return;
    }
    setState(() => _playingId = r.id);
    try {
      await _preview.stop();
      await _preview.setVolume(1.0);
      // AssetSource paths are relative to the assets/ root.
      await _preview.play(AssetSource(r.assetPath.replaceFirst('assets/', '')));
    } catch (e) {
      AppLogger.w('Ringtone preview failed: $e');
      if (mounted) setState(() => _playingId = null);
    }
  }

  Future<void> _stop() async {
    try {
      await _preview.stop();
    } catch (_) {}
    if (mounted) setState(() => _playingId = null);
  }

  Future<void> _select(String id) async {
    await _stop();
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final ringtones = ref.watch(ringtoneListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kho nhạc chuông')),
      body: ringtones.when(
        data: (list) => ListView(
          children: [
            for (final r in list)
              ListTile(
                leading: Icon(
                  r.highFrequency ? Icons.volume_up : Icons.music_note,
                  color: r.highFrequency ? theme.colorScheme.primary : null,
                ),
                title: Text(r.name),
                subtitle: r.highFrequency
                    ? const Text('Tần số cao — khó ngủ tiếp')
                    : null,
                onTap: () => _select(r.id),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _playingId == r.id
                            ? Icons.stop_circle
                            : Icons.play_circle_outline,
                      ),
                      tooltip: _playingId == r.id ? 'Dừng' : 'Nghe thử',
                      onPressed: () => _togglePreview(r),
                    ),
                    if (widget.selectedId == r.id)
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
