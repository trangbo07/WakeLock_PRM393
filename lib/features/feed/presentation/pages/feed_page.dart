import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../friends/presentation/providers/friends_providers.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../domain/entities/post.dart';
import '../providers/feed_providers.dart';
import '../providers/morning_photo_sync_provider.dart';
import '../widgets/post_card.dart';
import 'compose_post_page.dart';
import 'post_detail_page.dart';

/// Feed tab root — Locket-style morning-photo feed with a Friends / Recent
/// split and a compose button. Login required (guests see a prompt), matching
/// the app's "social features need an account" rule. Owned by Dev 2.
class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(sessionProvider).asData?.value != null;
    if (!signedIn) return const _FeedGuest();

    // Upload any locally-captured Morning Photos the user chose to share —
    // see morning_photo_sync_provider.dart for why this is needed. New posts
    // then show up on their own via feedProvider's live Firestore stream.
    ref.watch(morningPhotoFeedSyncProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Feed'),
          actions: const [NotificationBell()],
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            tabs: [
              Tab(text: 'Bạn bè'),
              Tab(text: 'Gần đây'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FeedList(friendsOnly: true),
            _FeedList(friendsOnly: false),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Đăng ảnh'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ComposePostPage()),
          ),
        ),
      ),
    );
  }
}

/// Shown to guests: prompt to sign in before viewing the feed.
class _FeedGuest extends StatelessWidget {
  const _FeedGuest();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined,
                  size: 72, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.lg),
              Text('Đăng nhập để xem feed', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Xem ảnh buổi sáng của bạn bè và chia sẻ ảnh của bạn.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppPrimaryButton(
                label: 'Đăng nhập',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The scrollable list of posts. When [friendsOnly] is true, filters to the
/// signed-in user's friends (and their own posts).
class _FeedList extends ConsumerWidget {
  const _FeedList({required this.friendsOnly});

  final bool friendsOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider);

    return feed.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Message(text: 'Không tải được feed:\n$e'),
      data: (posts) {
        final visible = friendsOnly ? _friendsPosts(ref, posts) : posts;
        if (visible.isEmpty) {
          return _Message(
            text: friendsOnly
                ? 'Chưa có bài từ bạn bè.\nKết bạn hoặc đăng ảnh đầu tiên nhé!'
                : 'Chưa có bài đăng nào.\nHãy là người đầu tiên đăng ảnh buổi sáng!',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(feedProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
            itemCount: visible.length,
            itemBuilder: (_, i) {
              final post = visible[i];
              return PostCard(
                post: post,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => PostDetailPage(post: post)),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Post> _friendsPosts(WidgetRef ref, List<Post> posts) {
    final myUid = ref.watch(sessionProvider).asData?.value?.uid;
    final friends = ref.watch(friendsListProvider).asData?.value ?? const [];
    final allowed = {
      ?myUid,
      ...friends.map((f) => f.uid),
    };
    return posts.where((p) => allowed.contains(p.authorUid)).toList();
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.mutedForeground),
          ),
        ),
      );
}
