import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../providers/feed_providers.dart';
import 'feed_helpers.dart';

/// Bottom sheet with the emoji picker row + the list of who reacted.
/// [current] is the viewer's active emoji (highlighted); tapping it again
/// removes the reaction.
class ReactionPickerSheet extends ConsumerWidget {
  const ReactionPickerSheet({
    super.key,
    required this.postId,
    required this.current,
    required this.onSelect,
    required this.onRemove,
  });

  final String postId;
  final String? current;
  final ValueChanged<String> onSelect;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reactors = ref.watch(reactorsProvider(postId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final e in kReactionEmojis)
                  _EmojiButton(
                    emoji: e,
                    selected: e == current,
                    onTap: () {
                      if (e == current) {
                        onRemove();
                      } else {
                        onSelect(e);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Mọi người đã thả cảm xúc',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: reactors.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Lỗi: $e'),
                data: (list) => list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                        child: Text('Chưa có ai thả cảm xúc.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final r = list[i];
                          final name = r.name.isEmpty ? 'Người dùng' : r.name;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.surfaceMuted,
                              backgroundImage: postImageProvider(
                                  base64Data: r.avatarBase64, url: r.avatarUrl),
                              child: (r.avatarBase64 == null &&
                                      (r.avatarUrl ?? '').isEmpty)
                                  ? Text(initialOf(name),
                                      style: const TextStyle(
                                          color: AppColors.primary))
                                  : null,
                            ),
                            title: Text(name),
                            trailing: reactionGlyph(r.emoji, size: 20),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.25) : null,
          shape: BoxShape.circle,
        ),
        child: reactionGlyph(emoji, size: 30),
      ),
    );
  }
}
