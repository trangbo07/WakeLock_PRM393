import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../morning_photo/domain/entities/morning_photo.dart';
import '../../../morning_photo/presentation/providers/morning_photo_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import 'feed_providers.dart';

/// Uploads any locally-captured Morning Photos (`features/morning_photo`,
/// SQLite, `posted=false`) that the user chose to share (privacy != private)
/// to the Firestore feed, then marks them posted.
///
/// This is the Dev1<->Dev2 hand-off documented in docs/team-work-split.md
/// ("Dev 1 lưu ảnh vào morning_photos (posted=0) ... Dev 2 làm màn 'chia sẻ'
/// ... set posted=1") that was never wired up — captured photos were staying
/// local forever. Triggered once whenever the signed-in user opens the Feed
/// tab (see `feed_page.dart`); newly created posts then appear automatically
/// via `feedProvider`'s live Firestore stream, no manual refresh needed.
final morningPhotoFeedSyncProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(sessionProvider).asData?.value;
  if (user == null) return;

  final morningPhotoRepo = ref.watch(morningPhotoRepositoryProvider);
  final unposted = await morningPhotoRepo.getUnposted();
  final shareable = unposted.where((p) => p.privacy != PhotoPrivacy.private).toList();
  if (shareable.isEmpty) return;

  final profile = ref.watch(myProfileProvider).asData?.value;
  final feedRepo = ref.watch(feedRepositoryProvider);

  for (final photo in shareable) {
    try {
      final file = File(photo.path);
      if (!await file.exists()) {
        // Local file is gone — nothing left to upload; stop retrying it.
        await morningPhotoRepo.markPosted(photo.id, '');
        continue;
      }
      final base64 = base64Encode(await file.readAsBytes());
      final remoteId = await feedRepo.createPost(
        authorUid: user.uid,
        authorName: (profile?.displayName.isNotEmpty ?? false)
            ? profile!.displayName
            : (user.displayName ?? 'Tôi'),
        authorUsername: profile?.username ?? '',
        authorAvatarUrl: profile?.avatarUrl ?? user.photoUrl,
        authorAvatarBase64: profile?.avatarBase64,
        photoBase64: base64,
        caption: photo.caption,
      );
      await morningPhotoRepo.markPosted(photo.id, remoteId);
    } catch (e) {
      AppLogger.w('Morning photo feed sync failed for ${photo.id}: $e');
      // Leave it unposted — retried next time the Feed tab opens.
    }
  }
});
