import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/achievement.dart';

enum _Filter { all, unlocked, locked }

/// Grid of achievement badges, filterable by unlocked state. Unlock is computed
/// live from the user's profile stats.
class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider).asData?.value ??
        const UserProfile(uid: '');
    final unlockedCount =
        kAchievements.where((a) => a.unlockedBy(profile)).length;

    final visible = kAchievements.where((a) {
      final u = a.unlockedBy(profile);
      return switch (_filter) {
        _Filter.all => true,
        _Filter.unlocked => u,
        _Filter.locked => !u,
      };
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Thành tích')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                for (final f in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(switch (f) {
                        _Filter.all => 'Tất cả',
                        _Filter.unlocked => 'Đã mở',
                        _Filter.locked => 'Chưa mở',
                      }),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppColors.accent,
                      labelStyle: TextStyle(
                          color: _filter == f ? Colors.white : null,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('$unlockedCount/${kAchievements.length} huy hiệu đã mở',
                  style: const TextStyle(color: AppColors.mutedForeground)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
              crossAxisCount: 3,
              childAspectRatio: 0.74,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              children: [
                for (final a in visible)
                  _Badge(achievement: a, unlocked: a.unlockedBy(profile)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: unlocked
                    ? LinearGradient(colors: [
                        achievement.color.withValues(alpha: 0.85),
                        achievement.color,
                      ])
                    : null,
                color: unlocked ? null : AppColors.surfaceMuted,
                border: Border.all(
                    color: unlocked ? achievement.color : AppColors.border,
                    width: 2),
                boxShadow: unlocked
                    ? [
                        BoxShadow(
                            color: achievement.color.withValues(alpha: 0.45),
                            blurRadius: 12)
                      ]
                    : null,
              ),
              child: Icon(achievement.icon,
                  size: 30,
                  color: unlocked ? Colors.white : AppColors.mutedForeground),
            ),
            if (!unlocked)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: AppColors.surfaceMuted, shape: BoxShape.circle),
                child: const Icon(Icons.lock,
                    size: 14, color: AppColors.mutedForeground),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(achievement.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: unlocked
                    ? AppColors.foreground
                    : AppColors.mutedForeground)),
        Text(achievement.description,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 10, color: AppColors.mutedForeground)),
      ],
    );
  }
}
