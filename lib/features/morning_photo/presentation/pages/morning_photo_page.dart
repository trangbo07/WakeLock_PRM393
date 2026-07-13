import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/morning_photo_providers.dart';

/// Morning Photo entry (STARTER SCAFFOLD for Dev 1).
///
/// Real flow: Camera (camera-only, no gallery) → Preview → Caption →
/// Mood/Weather → Privacy → save via morningPhotoRepositoryProvider.save(...).
/// Data layer is wired; replace this UI with the capture flow from the design.
/// Posting to the feed is Dev 2 (reads getUnposted() → uploads → markPosted()).
class MorningPhotoPage extends ConsumerWidget {
  const MorningPhotoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(morningPhotoListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Morning Photo')),
      body: Center(
        child: photosAsync.when(
          data: (photos) => Text(
            'Đã lưu ${photos.length} ảnh.\nMàn chụp ảnh (camera-only) sẽ dựng ở đây.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Lỗi: $e'),
        ),
      ),
    );
  }
}
