import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/widgets/avatar_image.dart';
import '../../domain/entities/challenge.dart';
import '../providers/challenge_providers.dart';

/// Challenge detail: header, daily check-in, and the live leaderboard.
class ChallengeDetailPage extends ConsumerStatefulWidget {
  const ChallengeDetailPage({super.key, required this.challengeId});

  final String challengeId;

  @override
  ConsumerState<ChallengeDetailPage> createState() =>
      _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends ConsumerState<ChallengeDetailPage> {
  bool _busy = false;

  Future<void> _checkIn() async {
    final uid = ref.read(sessionProvider).asData?.value?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      final ok = await ref
          .read(challengeRepositoryProvider)
          .checkIn(widget.challengeId, uid);
      _toast(ok ? 'Điểm danh thành công! +1 điểm 🎉' : 'Hôm nay bạn đã điểm danh rồi.');
    } catch (e) {
      _toast('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(sessionProvider).asData?.value?.uid;
    final challenge = ref.watch(challengeProvider(widget.challengeId));
    final parts = ref.watch(challengeParticipantsProvider(widget.challengeId));

    return Scaffold(
      appBar: AppBar(
        title: Text(challenge.asData?.value?.title ?? 'Thử thách'),
      ),
      body: challenge.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (c) {
          if (c == null) {
            return const Center(child: Text('Thử thách không tồn tại.'));
          }
          final list = parts.asData?.value ?? const <ChallengeParticipant>[];
          ChallengeParticipant? me;
          for (final p in list) {
            if (p.uid == myUid) {
              me = p;
              break;
            }
          }
          final canCheckIn = c.isActive && me != null && !me.checkedInOn();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _Header(challenge: c),
              const SizedBox(height: AppSpacing.lg),
              if (c.isActive && me != null)
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          canCheckIn ? AppColors.primary : AppColors.surfaceMuted,
                      foregroundColor:
                          canCheckIn ? AppColors.onPrimary : AppColors.mutedForeground,
                    ),
                    onPressed: (_busy || !canCheckIn) ? null : _checkIn,
                    icon: Icon(canCheckIn
                        ? Icons.wb_sunny_outlined
                        : Icons.check_circle),
                    label: Text(canCheckIn
                        ? 'Điểm danh dậy sớm hôm nay'
                        : 'Đã điểm danh hôm nay'),
                  ),
                )
              else if (!c.isActive)
                _EndedBanner(list: list),
              const SizedBox(height: AppSpacing.lg),
              Text('Bảng xếp hạng',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              ...list.asMap().entries.map((e) => _RankRow(
                    rank: e.key + 1,
                    p: e.value,
                    isMe: e.value.uid == myUid,
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.challenge});
  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(challenge.title,
              style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            challenge.isActive
                ? 'Còn ${challenge.daysLeft}/${challenge.days} ngày · ${challenge.participantCount} người'
                : 'Đã kết thúc · ${challenge.participantCount} người',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _EndedBanner extends StatelessWidget {
  const _EndedBanner({required this.list});
  final List<ChallengeParticipant> list;

  @override
  Widget build(BuildContext context) {
    final winner = list.isNotEmpty ? list.first : null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              winner == null
                  ? 'Thử thách đã kết thúc.'
                  : 'Người chiến thắng: ${winner.name} (${winner.score} điểm)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.p, required this.isMe});
  final int rank;
  final ChallengeParticipant p;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    const medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isMe ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isMe ? Border.all(color: AppColors.accent) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(medals[rank] ?? '$rank',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: AppSpacing.sm),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage:
                avatarImageProvider(base64Data: p.avatarBase64, url: p.avatarUrl),
            child: (p.avatarBase64 == null && (p.avatarUrl ?? '').isEmpty)
                ? Text(p.name.isEmpty ? '?' : p.name[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(isMe ? '${p.name} (bạn)' : p.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text('${p.score}',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(width: 2),
          const Text('đ', style: TextStyle(color: AppColors.mutedForeground)),
        ],
      ),
    );
  }
}
