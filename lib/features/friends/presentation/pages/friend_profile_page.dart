import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/avatar_image.dart';

/// A friend's public profile: avatar, name, bio and streak stats. Morning-photo
/// grid + calendar are placeholders until those features land.
class FriendProfilePage extends ConsumerWidget {
  const FriendProfilePage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userProfileProvider(uid));
    return Scaffold(
      appBar: AppBar(title: const Text('Trang cá nhân')),
      body: async.when(
        data: (p) => p == null
            ? const Center(child: Text('Không tìm thấy hồ sơ'))
            : _Content(profile: p),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name =
        profile.displayName.isEmpty ? '@${profile.username}' : profile.displayName;
    final avatar = avatarImageProvider(
        base64Data: profile.avatarBase64, url: profile.avatarUrl);

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
                    name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(color: AppColors.primary))
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(name,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        if (profile.username.isNotEmpty)
          Center(
            child: Text('@${profile.username}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Center(child: Text(profile.bio, textAlign: TextAlign.center)),
        ],
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Stat(value: '${profile.currentStreak}', label: 'Ngày streak'),
            _Stat(
                value: '${(profile.wakeRate * 100).round()}%',
                label: 'Tỷ lệ đúng giờ'),
            _Stat(value: '${profile.level}', label: 'Level'),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Ảnh buổi sáng',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Text('Sắp có',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: AppSpacing.xs),
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
