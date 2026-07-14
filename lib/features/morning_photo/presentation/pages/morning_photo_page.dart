import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/morning_photo_providers.dart';
import 'morning_photo_capture_page.dart';

/// Morning Photo gallery — grid of locally-saved photos + a FAB for a manual
/// capture (outside the alarm-dismiss chain). Posting to the feed is Dev 2's
/// job (reads getUnposted() → uploads → markPosted()).
class MorningPhotoPage extends ConsumerWidget {
  const MorningPhotoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(morningPhotoListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Morning Photo')),
      body: photosAsync.when(
        data: (photos) => photos.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Chưa có ảnh buổi sáng nào.\nẢnh sẽ được gợi ý chụp sau khi bạn tắt báo thức.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(morningPhotoListProvider),
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (_, i) {
                    final photo = photos[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(photo.path), fit: BoxFit.cover),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MorningPhotoCapturePage()),
          );
          ref.invalidate(morningPhotoListProvider);
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
