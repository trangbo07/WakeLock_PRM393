import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/avatar_image.dart';
import 'friend_photos_page.dart';

/// A friend's public profile: avatar, streak stats, a month calendar of
/// wake-ups (derived from the current streak) and a morning-photo strip.
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
        // Header: avatar + name + @username + bio.
        Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.surfaceMuted,
              backgroundImage: avatar,
              child: avatar == null
                  ? Text(name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: AppColors.primary))
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  if (profile.username.isNotEmpty)
                    Text('@${profile.username}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  if (profile.bio.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(profile.bio, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        // Stats.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Stat(value: '${profile.currentStreak}', label: 'Ngày streak'),
            _Stat(
                value: '${(profile.wakeRate * 100).round()}%',
                label: 'Tỷ lệ đúng giờ'),
            _Stat(value: '${profile.photosShared}', label: 'Ảnh đã chia sẻ'),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _MonthCalendar(streak: profile.currentStreak),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ảnh buổi sáng',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: () => _openGallery(context, profile, name),
              child: Text('Xem tất cả',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.accent)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: profile.photosShared > 0
              ? () => _openGallery(context, profile, name)
              : null,
          child: _PhotoStrip(uid: profile.uid, count: profile.photosShared),
        ),
      ],
    );
  }

  void _openGallery(BuildContext context, UserProfile profile, String name) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => FriendPhotosPage(
          uid: profile.uid, count: profile.photosShared, title: name),
    ));
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

/// Current-month grid; the last [streak] days up to today are marked done.
class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.streak});
  final int streak;

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leadBlanks = DateTime(now.year, now.month, 1).weekday - 1; // Mon=0
    final today = now.day;

    final cells = <Widget>[
      for (var i = 0; i < leadBlanks; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          day: day,
          done: day <= today && (today - day) < streak,
          isToday: day == today,
          isFuture: day > today,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tháng ${now.month}, ${now.year}',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: _weekdays
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            children: cells,
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.done,
    required this.isToday,
    required this.isFuture,
  });

  final int day;
  final bool done;
  final bool isToday;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return const CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Icon(Icons.check, size: 16, color: Colors.white),
      );
    }
    final color = isToday
        ? AppColors.accent
        : (isFuture ? AppColors.mutedForeground : AppColors.foreground);
    return Container(
      alignment: Alignment.center,
      decoration: isToday
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2))
          : null,
      child: Text('$day',
          style: TextStyle(
              color: color, fontWeight: isToday ? FontWeight.w700 : null)),
    );
  }
}

/// Horizontal strip of morning photos. Uses placeholder imagery until Dev 1's
/// Morning Photo feed is integrated; shows an empty hint when none.
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.uid, required this.count});
  final String uid;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (count == 0) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text('Chưa có ảnh',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      );
    }
    final shown = count < 6 ? count : 6;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shown,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.network(
            'https://picsum.photos/seed/$uid$i/200',
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 96,
              height: 96,
              color: AppColors.surfaceMuted,
              child: const Icon(Icons.image_outlined,
                  color: AppColors.mutedForeground),
            ),
          ),
        ),
      ),
    );
  }
}
