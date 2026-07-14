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

/// XP needed to gain one level. Level/progress derive from total XP so the
/// header can show a "progress to next level" bar without a stored level.
const int _xpPerLevel = 500;
int _levelFor(int xp) => xp ~/ _xpPerLevel + 1;
int _xpToNext(int xp) => _xpPerLevel - (xp % _xpPerLevel);
double _levelProgress(int xp) => (xp % _xpPerLevel) / _xpPerLevel;

/// Profile tab. Login-optional: guests see a sign-in prompt (offline alarm
/// features keep working); signed-in users see their profile + stats.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
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

/// Signed-in profile: identity header w/ level progress, stat row, and a
/// grouped action menu (game hub, edit, settings, sign out).
class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).asData?.value;

    final name = (profile?.displayName.isNotEmpty ?? false)
        ? profile!.displayName
        : (user.displayName ?? 'Người dùng');
    final username = profile?.username ?? '';
    final xp = profile?.xp ?? 0;
    final coins = profile?.coins ?? 0;
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
          xp: xp,
          streak: profile?.currentStreak ?? 0,
          coins: coins,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _MiniStat(
                icon: Icons.local_fire_department,
                color: AppColors.primary,
                value: '${profile?.currentStreak ?? 0}',
                label: 'Streak'),
            const SizedBox(width: AppSpacing.sm),
            _MiniStat(
                icon: Icons.emoji_events,
                color: AppColors.accent,
                value: '${profile?.longestStreak ?? 0}',
                label: 'Dài nhất'),
            const SizedBox(width: AppSpacing.sm),
            _MiniStat(
                icon: Icons.wb_sunny,
                color: const Color(0xFF0EA5E9),
                value: '${((profile?.wakeRate ?? 0) * 100).round()}%',
                label: 'Tỉ lệ dậy'),
            const SizedBox(width: AppSpacing.sm),
            _MiniStat(
                icon: Icons.photo_library,
                color: const Color(0xFF22C55E),
                value: '${profile?.photosShared ?? 0}',
                label: 'Ảnh'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ActionMenu(
          level: _levelFor(xp),
          coins: coins,
          onSignOut: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
    );
  }

  String _initial(String name) =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
}

/// Premium identity header: gradient banner, avatar w/ amber ring, name +
/// @username, coin balance, a level-progress bar, streak pill, and bio.
class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.username,
    required this.bio,
    required this.avatar,
    required this.initial,
    required this.xp,
    required this.streak,
    required this.coins,
  });

  final String name;
  final String username;
  final String bio;
  final ImageProvider? avatar;
  final String initial;
  final int xp;
  final int streak;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = _levelFor(xp);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarRing(avatar: avatar, initial: initial),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    if (username.isNotEmpty)
                      Text('@$username',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.sm),
                    _HeroPill(
                        icon: Icons.local_fire_department,
                        label: '$streak ngày',
                        color: AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _CoinChip(coins: coins),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _LevelBar(
              level: level,
              progress: _levelProgress(xp),
              toNext: _xpToNext(xp)),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(bio, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Avatar inside a glowing amber gradient ring.
class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.avatar, required this.initial});

  final ImageProvider? avatar;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary]),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 16),
        ],
      ),
      child: CircleAvatar(
        radius: 34,
        backgroundColor: AppColors.surfaceMuted,
        backgroundImage: avatar,
        child: avatar == null
            ? Text(initial,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: AppColors.primary))
            : null,
      ),
    );
  }
}

/// Coin balance chip (amber, top-right of the header).
class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, size: 15, color: AppColors.primary),
          const SizedBox(width: 4),
          Text('$coins',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

/// "Level N" label + gradient progress bar toward the next level.
class _LevelBar extends StatelessWidget {
  const _LevelBar(
      {required this.level, required this.progress, required this.toNext});

  final int level;
  final double progress;
  final int toNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.military_tech,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 4),
                Text('Level $level',
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ],
            ),
            Text('còn $toNext XP',
                style: const TextStyle(
                    color: AppColors.mutedForeground, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          width: double.infinity, // full-width track; fill overlays via FractionallySizedBox
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            // Lighter track so the bar stays visible even at 0% on the card.
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 8),
                ],
              ),
            ),
          ),
        ),
      ],
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

/// Compact vertical stat tile (icon chip + value + label). Four fit in a row.
class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// Grouped action list: game hub (with live level/coins), edit profile,
/// settings, and sign out — one clear tap target per row.
class _ActionMenu extends StatelessWidget {
  const _ActionMenu(
      {required this.level, required this.coins, required this.onSignOut});

  final int level;
  final int coins;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _MenuRow(
            icon: Icons.videogame_asset,
            color: AppColors.accent,
            title: 'Trò chơi & Thành tích',
            subtitle: 'Lv $level · $coins xu',
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.mutedForeground),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const GameHomePage()),
            ),
          ),
          const _MenuDivider(),
          _MenuRow(
            icon: Icons.edit_outlined,
            color: AppColors.primary,
            title: 'Chỉnh sửa hồ sơ',
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.mutedForeground),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const EditProfilePage()),
            ),
          ),
          const _MenuDivider(),
          _MenuRow(
            icon: Icons.settings_outlined,
            color: AppColors.mutedForeground,
            title: 'Cài đặt',
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.mutedForeground),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
          ),
          const _MenuDivider(),
          _MenuRow(
            icon: Icons.logout,
            color: AppColors.destructive,
            title: 'Đăng xuất',
            danger: true,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: AppColors.border);
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: danger ? AppColors.destructive : null)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
