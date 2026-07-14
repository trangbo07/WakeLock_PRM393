import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/widgets/avatar_image.dart';
import '../../domain/level_progress.dart';

/// Level + XP progress card for the game home (avatar, level, XP bar).
class LevelHeader extends StatelessWidget {
  const LevelHeader({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = profile.displayName.isEmpty
        ? '@${profile.username}'
        : profile.displayName;
    final lvl = LevelProgress.fromXp(profile.xp);
    final img = avatarImageProvider(
        base64Data: profile.avatarBase64, url: profile.avatarUrl);

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary]),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 14),
                  ],
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.surfaceMuted,
                  backgroundImage: img,
                  child: img == null
                      ? Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700))
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level ${lvl.level}',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: lvl.fraction,
              minHeight: 10,
              backgroundColor: AppColors.surfaceMuted,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${lvl.xpIntoLevel} / ${lvl.xpPerLevel} XP',
                  style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()])),
              Text('còn ${lvl.xpToNext} XP đến Level ${lvl.level + 1}',
                  style: const TextStyle(
                      color: AppColors.mutedForeground, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
