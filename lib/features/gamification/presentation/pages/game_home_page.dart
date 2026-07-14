import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../leaderboard/presentation/pages/leaderboard_page.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/daily_mission.dart';
import '../providers/gamification_providers.dart';
import '../widgets/coin_pill.dart';
import '../widgets/level_header.dart';
import '../widgets/pill_button.dart';
import 'achievements_page.dart';
import 'shop_page.dart';

String _todayKey() {
  final n = DateTime.now();
  return '${n.year}-${n.month}-${n.day}';
}

/// Gamification hub: level/XP, quick links, and claimable daily missions.
class GameHomePage extends ConsumerStatefulWidget {
  const GameHomePage({super.key});

  @override
  ConsumerState<GameHomePage> createState() => _GameHomePageState();
}

class _GameHomePageState extends ConsumerState<GameHomePage> {
  final Set<String> _busy = {};

  Future<void> _claim(DailyMission m) async {
    final uid = ref.read(sessionProvider).asData?.value?.uid;
    if (uid == null) return;
    setState(() => _busy.add(m.id));
    try {
      final ok = await ref.read(gamificationDataSourceProvider).claimMission(
          uid, m.id, m.xp, m.coins, _todayKey());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? 'Nhận thưởng: +${m.xp} XP · +${m.coins} 🪙'
              : 'Nhiệm vụ này đã nhận hôm nay.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(m.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).asData?.value;
    if (user == null) return const _GameGuest();
    final profile = ref.watch(myProfileProvider).asData?.value;
    final coins = profile?.coins ?? 0;
    final claims = profile?.dailyClaims ?? const {};
    final today = _todayKey();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ Game'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(child: CoinPill(coins: coins)),
          ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                LevelHeader(profile: profile),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _ActionTile(
                      icon: Icons.emoji_events,
                      label: 'Thành tích',
                      color: AppColors.primary,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const AchievementsPage())),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ActionTile(
                      icon: Icons.storefront,
                      label: 'Cửa hàng',
                      color: AppColors.accent,
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ShopPage())),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ActionTile(
                      icon: Icons.leaderboard,
                      label: 'Xếp hạng',
                      color: const Color(0xFF22C55E),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const LeaderboardPage())),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Nhiệm vụ hàng ngày',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.sm),
                for (final m in kDailyMissions)
                  _MissionTile(
                    mission: m,
                    claimed: claims[m.id] == today,
                    busy: _busy.contains(m.id),
                    onClaim: () => _claim(m),
                  ),
              ],
            ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({
    required this.mission,
    required this.claimed,
    required this.busy,
    required this.onClaim,
  });

  final DailyMission mission;
  final bool claimed;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: claimed ? const Color(0xFF22C55E) : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(mission.icon,
              color: claimed ? const Color(0xFF22C55E) : AppColors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mission.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('+${mission.xp} XP · +${mission.coins} 🪙',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (claimed)
            const Icon(Icons.check_circle, color: Color(0xFF22C55E))
          else if (busy)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            PillButton(onTap: onClaim, child: const Text('Nhận')),
        ],
      ),
    );
  }
}

class _GameGuest extends StatelessWidget {
  const _GameGuest();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ Game')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videogame_asset_outlined,
                  size: 72, color: AppColors.mutedForeground),
              const SizedBox(height: AppSpacing.lg),
              Text('Đăng nhập để chơi', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('Lên cấp, mở huy hiệu và mua vật phẩm bằng xu.',
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
