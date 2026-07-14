import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/register_page.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../gamification/presentation/pages/game_home_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../providers/profile_providers.dart';
import '../widgets/avatar_image.dart';
import 'edit_profile_page.dart';

/// Profile tab. Login-optional: guests see a sign-in prompt (offline alarm
/// features keep working); signed-in users see their profile + stats.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: session.when(
        data: (user) =>
            user == null ? const _GuestView() : _ProfileView(user: user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _GuestView(),
      ),
    );
  }
}

/// Shown when not signed in. Emphasizes that the alarm still works offline.
class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_circle_outlined,
                size: 88, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text('Chưa đăng nhập', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Đăng nhập để mở khoá Feed, bạn bè và thử thách.\n'
              'Báo thức, nhiệm vụ và thói quen vẫn chạy bình thường khi chưa đăng nhập.',
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
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RegisterPage()),
              ),
              child: const Text('Tạo tài khoản mới'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Signed-in profile: identity header, stat tiles, edit + sign out.
class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final profile = profileAsync.asData?.value;

    final name = (profile?.displayName.isNotEmpty ?? false)
        ? profile!.displayName
        : (user.displayName ?? 'Người dùng');
    final username = profile?.username ?? '';
    final avatar = avatarImageProvider(
      base64Data: profile?.avatarBase64,
      url: profile?.avatarUrl ?? user.photoUrl,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _ProfileHero(
          name: name,
          username: username,
          bio: profile?.bio ?? '',
          avatar: avatar,
          initial: _initial(name),
          level: (profile?.xp ?? 0) ~/ 500 + 1,
          streak: profile?.currentStreak ?? 0,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            _StatTile(
                icon: Icons.local_fire_department,
                color: AppColors.primary,
                label: 'Streak',
                value: '${profile?.currentStreak ?? 0}'),
            const SizedBox(width: AppSpacing.md),
            _StatTile(
                icon: Icons.emoji_events,
                color: AppColors.accent,
                label: 'Dài nhất',
                value: '${profile?.longestStreak ?? 0}'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _StatTile(
                icon: Icons.military_tech,
                color: const Color(0xFF22C55E),
                label: 'Level',
                value: '${(profile?.xp ?? 0) ~/ 500 + 1}'),
            const SizedBox(width: AppSpacing.md),
            _StatTile(
                icon: Icons.wb_sunny,
                color: const Color(0xFF0EA5E9),
                label: 'Tỉ lệ dậy',
                value: '${((profile?.wakeRate ?? 0) * 100).round()}%'),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _GameEntryCard(
          level: (profile?.xp ?? 0) ~/ 500 + 1,
          coins: profile?.coins ?? 0,
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Chỉnh sửa hồ sơ'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const EditProfilePage()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          icon: const Icon(Icons.logout, color: AppColors.destructive),
          label: const Text('Đăng xuất',
              style: TextStyle(color: AppColors.destructive)),
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
    );
  }

  String _initial(String name) =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
}

/// Premium identity header: gradient banner, avatar with amber ring, name,
/// @username, level + streak pills, and bio.
class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.username,
    required this.bio,
    required this.avatar,
    required this.initial,
    required this.level,
    required this.streak,
  });

  final String name;
  final String username;
  final String bio;
  final ImageProvider? avatar;
  final String initial;
  final int level;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF241C33), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary]),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 18),
              ],
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.surfaceMuted,
              backgroundImage: avatar,
              child: avatar == null
                  ? Text(initial,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: AppColors.primary))
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(name,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          if (username.isNotEmpty)
            Text('@$username',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeroPill(
                  icon: Icons.military_tech,
                  label: 'Level $level',
                  color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              _HeroPill(
                  icon: Icons.local_fire_department,
                  label: '$streak ngày',
                  color: AppColors.primary),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(bio,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Gradient shortcut into the gamification hub (level, badges, shop).
class _GameEntryCard extends StatelessWidget {
  const _GameEntryCard({required this.level, required this.coins});

  final int level;
  final int coins;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const GameHomePage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFD97706)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.videogame_asset, color: Colors.white, size: 28),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trò chơi & Thành tích',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  Text('Nhiệm vụ · huy hiệu · cửa hàng',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Text('Lv $level · $coins 🪙',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
