import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/leader_metric.dart';
import '../providers/leaderboard_providers.dart';
import '../widgets/leader_rank_row.dart';
import '../widgets/leaderboard_podium.dart';
import '../widgets/metric_selector.dart';

/// Ranks the user and their friends by a chosen metric (streak / wake-rate / XP)
/// with a top-3 podium and a personal-rank summary. Login required.
class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  LeaderMetric _metric = LeaderMetric.streak;

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(sessionProvider).asData?.value?.uid;
    if (myUid == null) return const _LeaderGuest();
    final data = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bảng xếp hạng')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: MetricSelector(
              selected: _metric,
              onChanged: (m) => setState(() => _metric = m),
            ),
          ),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('Chưa có dữ liệu xếp hạng.'));
                }
                final sorted = [...list]
                  ..sort((a, b) =>
                      _metric.value(b).compareTo(_metric.value(a)));
                final myIndex = sorted.indexWhere((p) => p.uid == myUid);
                final rest = sorted.skip(3).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
                  children: [
                    if (myIndex >= 0)
                      _MyRankCard(
                        rank: myIndex + 1,
                        value: _metric.display(sorted[myIndex]),
                        total: sorted.length,
                      ),
                    LeaderboardPodium(
                        top: sorted.take(3).toList(),
                        metric: _metric,
                        myUid: myUid),
                    if (rest.isNotEmpty) const SizedBox(height: AppSpacing.sm),
                    for (var i = 0; i < rest.length; i++)
                      LeaderRankRow(
                        rank: i + 4,
                        profile: rest[i],
                        metric: _metric,
                        isMe: rest[i].uid == myUid,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Highlighted summary of the viewer's own standing.
class _MyRankCard extends StatelessWidget {
  const _MyRankCard(
      {required this.rank, required this.value, required this.total});

  final int rank;
  final String value;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, Color(0xFF818CF8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person_pin_circle, color: Colors.white, size: 28),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text('Hạng của bạn',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
          Text('#$rank',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  fontFeatures: [FontFeature.tabularFigures()])),
          Text(' / $total',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _LeaderGuest extends StatelessWidget {
  const _LeaderGuest();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bảng xếp hạng')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.leaderboard_outlined,
                  size: 72, color: AppColors.mutedForeground),
              const SizedBox(height: AppSpacing.lg),
              Text('Đăng nhập để xem xếp hạng',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('So tài chuỗi dậy sớm, tỉ lệ dậy và XP với bạn bè.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.mutedForeground)),
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
