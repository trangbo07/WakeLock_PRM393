import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/widgets/avatar_image.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_providers.dart';

String _timeAgo(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
  if (diff.inHours < 24) return '${diff.inHours} giờ';
  if (diff.inDays < 7) return '${diff.inDays} ngày';
  return '${d.day}/${d.month}';
}

({IconData icon, Color color}) _style(String type) => switch (type) {
      'friend_request' => (icon: Icons.person_add, color: AppColors.accent),
      'friend_accept' => (icon: Icons.how_to_reg, color: Color(0xFF22C55E)),
      'reaction' => (icon: Icons.favorite, color: Color(0xFFF43F5E)),
      'comment' => (icon: Icons.chat_bubble, color: AppColors.primary),
      _ => (icon: Icons.notifications, color: AppColors.mutedForeground),
    };

/// Notification inbox. Tapping a row marks it read; "Đọc tất cả" clears all.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(sessionProvider).asData?.value?.uid;
    final items = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (uid != null)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsRepositoryProvider).markAllRead(uid),
              child: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (list) {
          if (list.isEmpty) return const _Empty();
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: list.length,
            itemBuilder: (_, i) => _NotificationTile(
              n: list[i],
              onTap: () {
                if (uid != null && !list[i].read) {
                  ref
                      .read(notificationsRepositoryProvider)
                      .markRead(uid, list[i].id);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n, required this.onTap});

  final AppNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _style(n.type);
    final avatar = avatarImageProvider(
        base64Data: n.actorAvatarBase64, url: n.actorAvatarUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: n.read
            ? AppColors.surface
            : AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: n.read ? AppColors.border : AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.surfaceMuted,
                    backgroundImage: avatar,
                    child: avatar == null
                        ? Icon(s.icon, color: s.color, size: 20)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        color: s.color, shape: BoxShape.circle),
                    child: Icon(s.icon, size: 11, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight:
                                n.read ? FontWeight.w600 : FontWeight.w700)),
                    if (n.body.isNotEmpty)
                      Text(n.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(_timeAgo(n.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.mutedForeground)),
                  ],
                ),
              ),
              if (!n.read)
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none,
                size: 72, color: AppColors.mutedForeground),
            const SizedBox(height: AppSpacing.lg),
            Text('Chưa có thông báo', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text('Lời mời kết bạn, cảm xúc và bình luận sẽ hiện ở đây.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.mutedForeground)),
          ],
        ),
      ),
    );
  }
}
