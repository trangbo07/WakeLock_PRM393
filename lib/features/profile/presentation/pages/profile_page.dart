import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/register_page.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
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
    final theme = Theme.of(context);
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
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage: avatar,
            child: avatar == null
                ? Text(
                    _initial(name),
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(color: AppColors.primary),
                  )
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(name,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        if (username.isNotEmpty)
          Center(
            child: Text('@$username',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        if ((profile?.bio ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Center(child: Text(profile!.bio, textAlign: TextAlign.center)),
        ],
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            _StatTile(
                label: 'Streak', value: '${profile?.currentStreak ?? 0}'),
            const SizedBox(width: AppSpacing.md),
            _StatTile(
                label: 'Dài nhất', value: '${profile?.longestStreak ?? 0}'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _StatTile(label: 'Level', value: '${profile?.level ?? 1}'),
            const SizedBox(width: AppSpacing.md),
            _StatTile(
                label: 'Tỉ lệ dậy',
                value: '${((profile?.wakeRate ?? 0) * 100).round()}%'),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
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

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

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
        child: Column(
          children: [
            Text(value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
