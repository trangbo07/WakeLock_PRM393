import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../domain/entities/post.dart';
import 'feed_helpers.dart';

/// A single morning-photo post in the feed list.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.onTap});

  final Post post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = post.authorName.isEmpty
        ? '@${post.authorUsername}'
        : post.authorName;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author + timestamp
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surfaceMuted,
                    backgroundImage: postImageProvider(
                        base64Data: post.authorAvatarBase64,
                        url: post.authorAvatarUrl),
                    child: (post.authorAvatarBase64 == null &&
                            (post.authorAvatarUrl ?? '').isEmpty)
                        ? Text(initialOf(name),
                            style: const TextStyle(color: AppColors.primary))
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        if (post.createdAt != null)
                          Text(timeAgo(post.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Photo
            AspectRatio(
              aspectRatio: 1,
              child: _Photo(post: post),
            ),

            // Caption + counters
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.caption.isNotEmpty) ...[
                    Text(post.caption, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Row(
                    children: [
                      _Counter(
                          emoji: post.myReaction ?? '❤️',
                          count: post.reactionCount),
                      const SizedBox(width: AppSpacing.lg),
                      _Counter(emoji: '💬', count: post.commentCount),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final img =
        postImageProvider(base64Data: post.photoBase64, url: post.photoUrl);
    if (img == null) {
      return Container(
        color: AppColors.surfaceMuted,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined,
            color: AppColors.mutedForeground, size: 40),
      );
    }
    return Image(
      image: img,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.surfaceMuted,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined,
            color: AppColors.mutedForeground, size: 40),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.emoji, required this.count});
  final String emoji;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        reactionGlyph(emoji, size: 16),
        const SizedBox(width: AppSpacing.xs),
        Text('$count',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
