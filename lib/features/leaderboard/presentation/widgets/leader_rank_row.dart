import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/widgets/avatar_image.dart';
import '../../domain/leader_metric.dart';
import 'rank_badge.dart';

/// A ranked leaderboard row (rank 4+). Highlights the current user.
class LeaderRankRow extends StatelessWidget {
  const LeaderRankRow({
    super.key,
    required this.rank,
    required this.profile,
    required this.metric,
    required this.isMe,
  });

  final int rank;
  final UserProfile profile;
  final LeaderMetric metric;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final name =
        profile.displayName.isEmpty ? '@${profile.username}' : profile.displayName;
    final img = avatarImageProvider(
        base64Data: profile.avatarBase64, url: profile.avatarUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: isMe ? AppColors.accent.withValues(alpha: 0.16) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isMe ? AppColors.accent : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          RankBadge(rank: rank, size: 30),
          const SizedBox(width: AppSpacing.md),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage: img,
            child: img == null
                ? Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.primary))
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              isMe ? '$name (bạn)' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Text(
            metric.display(profile),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
