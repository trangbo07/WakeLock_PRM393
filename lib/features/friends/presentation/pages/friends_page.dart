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
import '../../../challenge/presentation/pages/challenge_list_page.dart';
import '../../../leaderboard/presentation/pages/leaderboard_page.dart';
import '../../domain/entities/friend.dart';
import '../providers/friends_providers.dart';
import 'add_friend_page.dart';
import 'friend_profile_page.dart';

/// Friends tab: friends list + incoming requests. Pill tabs + a full-width
/// "add friend" button, on the indigo accent. Login required (guests see a prompt).
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
          actions: [
            IconButton(
              icon: const Icon(Icons.leaderboard_outlined),
              tooltip: 'Bảng xếp hạng',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const LeaderboardPage()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.emoji_events_outlined),
              tooltip: 'Thử thách',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const ChallengeListPage()),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _PillTabs(
              labels: ['Bạn bè (${friends.length})', 'Lời mời (${requests.length})'],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _FriendsList(friends: friends),
                  _RequestsList(requests: requests, user: user),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Thêm bạn bè'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AddFriendPage()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented pill tab bar (selected tab = filled amber pill).
class _PillTabs extends StatelessWidget {
  const _PillTabs({required this.labels});
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        splashBorderRadius: BorderRadius.circular(AppRadius.pill),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.mutedForeground,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: labels.map((l) => Tab(text: l)).toList(),
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
    final maxStreak =
        friends.fold<int>(0, (m, f) => f.streak > m ? f.streak : m);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: friends.length,
      itemBuilder: (_, i) {
        final f = friends[i];
        final isTop = f.streak > 0 && f.streak == maxStreak;
        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage: avatarImageProvider(
                base64Data: f.avatarBase64, url: f.avatarUrl),
            child: (f.avatarBase64 == null && (f.avatarUrl ?? '').isEmpty)
                ? Text(_initial(f.name.isEmpty ? f.username : f.name))
                : null,
          ),
          title: Text(f.name.isEmpty ? '@${f.username}' : f.name),
          subtitle: f.username.isNotEmpty ? Text('@${f.username}') : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${f.streak} ngày',
                  style: TextStyle(color: AppColors.mutedForeground)),
              const SizedBox(width: 6),
              Icon(
                isTop ? Icons.local_fire_department : Icons.chevron_right,
                size: 20,
                color: isTop ? AppColors.secondary : AppColors.mutedForeground,
              ),
            ],
          ),
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: requests.length,
      itemBuilder: (_, i) {
        final r = requests[i];
        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage: avatarImageProvider(
                base64Data: r.fromAvatarBase64, url: r.fromAvatarUrl),
            child: (r.fromAvatarBase64 == null && (r.fromAvatarUrl ?? '').isEmpty)
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
