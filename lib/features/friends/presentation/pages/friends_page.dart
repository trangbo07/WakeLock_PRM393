import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/avatar_image.dart';
import '../../domain/entities/friend.dart';
import '../providers/friends_providers.dart';
import 'add_friend_page.dart';
import 'friend_profile_page.dart';

/// Friends tab: friends list + incoming requests. Login required (guests see a
/// prompt). Reachable actions: add friend, accept/reject requests, open profile.
class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).asData?.value;
    if (user == null) return const _FriendsGuest();

    final friends = ref.watch(friendsListProvider).asData?.value ?? const [];
    final requests = ref.watch(friendRequestsProvider).asData?.value ?? const [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bạn bè'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Bạn bè (${friends.length})'),
              Tab(text: 'Lời mời (${requests.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FriendsList(friends: friends),
            _RequestsList(requests: requests, user: user),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddFriendPage()),
          ),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Thêm bạn bè'),
        ),
      ),
    );
  }
}

class _FriendsGuest extends StatelessWidget {
  const _FriendsGuest();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bạn bè')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_outlined,
                  size: 72, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.lg),
              Text('Đăng nhập để kết bạn', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Kết bạn, xem streak chung và rủ nhau dậy sớm.',
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

class _FriendsList extends StatelessWidget {
  const _FriendsList({required this.friends});

  final List<Friend> friends;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const _Empty(
          icon: Icons.group_outlined,
          text: 'Chưa có bạn bè.\nNhấn "Thêm bạn bè" để kết nối.');
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: friends.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final f = friends[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage: avatarImageProvider(base64Data: f.avatarBase64),
            child: f.avatarBase64 == null
                ? Text(_initial(f.name.isEmpty ? f.username : f.name))
                : null,
          ),
          title: Text(f.name.isEmpty ? '@${f.username}' : f.name),
          subtitle: f.username.isNotEmpty ? Text('@${f.username}') : null,
          trailing: f.streak > 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${f.streak}',
                        style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    const Icon(Icons.local_fire_department,
                        size: 18, color: AppColors.secondary),
                  ],
                )
              : const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => FriendProfilePage(uid: f.uid)),
          ),
        );
      },
    );
  }
}

class _RequestsList extends ConsumerWidget {
  const _RequestsList({required this.requests, required this.user});

  final List<FriendRequest> requests;
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return const _Empty(
          icon: Icons.mail_outline, text: 'Không có lời mời nào.');
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = requests[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage:
                avatarImageProvider(base64Data: r.fromAvatarBase64),
            child: r.fromAvatarBase64 == null
                ? Text(_initial(r.fromName.isEmpty ? r.fromUsername : r.fromName))
                : null,
          ),
          title: Text(r.fromName.isEmpty ? '@${r.fromUsername}' : r.fromName),
          subtitle: Text(r.message.isEmpty ? 'muốn kết bạn' : r.message),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle, color: AppColors.primary),
                tooltip: 'Chấp nhận',
                onPressed: () => _accept(ref, r),
              ),
              IconButton(
                icon: const Icon(Icons.cancel_outlined,
                    color: AppColors.destructive),
                tooltip: 'Từ chối',
                onPressed: () =>
                    ref.read(friendsRepositoryProvider).rejectRequest(r.id),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _accept(WidgetRef ref, FriendRequest r) async {
    final me = ref.read(myProfileProvider).asData?.value ??
        UserProfile(uid: user.uid, displayName: user.displayName ?? '');
    await ref.read(friendsRepositoryProvider).acceptRequest(req: r, me: me);
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

String _initial(String s) => s.trim().isEmpty ? '?' : s.trim()[0].toUpperCase();
