import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../domain/entities/challenge.dart';
import '../providers/challenge_providers.dart';
import 'challenge_detail_page.dart';
import 'create_challenge_page.dart';

/// Lists the challenges the signed-in user is part of, active ones first.
class ChallengeListPage extends ConsumerWidget {
  const ChallengeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(myChallengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thử thách')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Tạo thử thách'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateChallengePage()),
        ),
      ),
      body: challenges.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (list) {
          if (list.isEmpty) return const _Empty();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
            itemCount: list.length,
            itemBuilder: (_, i) => _ChallengeCard(challenge: list[i]),
          );
        },
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.challenge});
  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = challenge.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => ChallengeDetailPage(challengeId: challenge.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      challenge.title.isEmpty ? 'Thử thách' : challenge.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _StatusChip(active: active),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _Meta(icon: Icons.timer_outlined, text: '${challenge.days} ngày'),
                  const SizedBox(width: AppSpacing.md),
                  _Meta(
                      icon: Icons.group_outlined,
                      text: '${challenge.participantCount} người'),
                  const SizedBox(width: AppSpacing.md),
                  if (active)
                    _Meta(
                        icon: Icons.hourglass_bottom,
                        text: 'còn ${challenge.daysLeft} ngày'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.mutedForeground;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(active ? 'Đang diễn ra' : 'Đã kết thúc',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.mutedForeground),
        const SizedBox(width: AppSpacing.xs),
        Text(text,
            style: const TextStyle(
                color: AppColors.mutedForeground, fontSize: 13)),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined,
                size: 72, color: AppColors.mutedForeground),
            const SizedBox(height: AppSpacing.lg),
            Text('Chưa có thử thách nào', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tạo thử thách dậy sớm và rủ bạn bè cùng thi đua!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
