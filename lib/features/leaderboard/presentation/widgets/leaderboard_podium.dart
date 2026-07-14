import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/widgets/avatar_image.dart';
import '../../domain/leader_metric.dart';
import 'rank_badge.dart';

/// Premium top-3 podium (2nd · 1st · 3rd) with metallic rings, a crown on the
/// leader, and gradient pedestals.
class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({
    super.key,
    required this.top,
    required this.metric,
    required this.myUid,
  });

  /// Ranked profiles (index 0 = 1st). May contain fewer than 3.
  final List<UserProfile> top;
  final LeaderMetric metric;
  final String? myUid;

  @override
  Widget build(BuildContext context) {
    UserProfile? at(int i) => i < top.length ? top[i] : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.lg, AppSpacing.sm, AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _Spot(p: at(1), rank: 2, metric: metric, myUid: myUid)),
          Expanded(child: _Spot(p: at(0), rank: 1, metric: metric, myUid: myUid)),
          Expanded(child: _Spot(p: at(2), rank: 3, metric: metric, myUid: myUid)),
        ],
      ),
    );
  }
}

class _Spot extends StatelessWidget {
  const _Spot({
    required this.p,
    required this.rank,
    required this.metric,
    required this.myUid,
  });

  final UserProfile? p;
  final int rank;
  final LeaderMetric metric;
  final String? myUid;

  static const _heights = {1: 104.0, 2: 76.0, 3: 58.0};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (p == null) return const SizedBox.shrink();
    final me = p!.uid == myUid;
    final name = p!.displayName.isEmpty ? '@${p!.username}' : p!.displayName;
    final grad = rankGradient(rank);
    final radius = rank == 1 ? 38.0 : 30.0;
    final img =
        avatarImageProvider(base64Data: p!.avatarBase64, url: p!.avatarUrl);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (rank == 1)
          const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 26)
        else
          const SizedBox(height: 26),
        const SizedBox(height: 4),
        // Avatar with metallic gradient ring + glow.
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: grad),
            boxShadow: [
              BoxShadow(
                color: grad.last.withValues(alpha: rank == 1 ? 0.55 : 0.35),
                blurRadius: rank == 1 ? 20 : 10,
                spreadRadius: rank == 1 ? 1 : 0,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage: img,
            child: img == null
                ? Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: rank == 1 ? 28 : 22,
                        fontWeight: FontWeight.w700))
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          me ? '$name (bạn)' : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700, color: me ? AppColors.accent : null),
        ),
        const SizedBox(height: 2),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(metric.display(p!),
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Pedestal.
        Container(
          height: _heights[rank],
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [grad.first.withValues(alpha: 0.9), grad.last],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: RankBadge(rank: rank, size: rank == 1 ? 32 : 26),
        ),
      ],
    );
  }
}
