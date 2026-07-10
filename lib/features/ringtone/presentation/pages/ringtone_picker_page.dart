import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ringtone_providers.dart';

/// Lets the user pick an alarm ringtone. Pops with the selected ringtone id.
class RingtonePickerPage extends ConsumerWidget {
  const RingtonePickerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ringtones = ref.watch(ringtoneListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kho nhạc chuông')),
      body: ringtones.when(
        data: (list) => ListView(
          children: [
            for (final r in list)
              ListTile(
                leading: Icon(
                  r.highFrequency ? Icons.volume_up : Icons.music_note,
                ),
                title: Text(r.name),
                onTap: () => Navigator.pop(context, r.id),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}
