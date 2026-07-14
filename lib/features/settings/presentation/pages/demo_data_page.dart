import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../core/dev/local_demo_seeder.dart';
import '../../../../core/dev/sample_data_seeder.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../habit/presentation/providers/habit_providers.dart';
import '../../../leaderboard/presentation/providers/leaderboard_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../streak/presentation/providers/streak_providers.dart';

/// Debug-only marketing helper: seeds 50 sample users + full social/local data
/// for the signed-in ("hero") account, or clears it. Reached from Settings only
/// in debug builds. Not shipped to end users.
class DemoDataPage extends ConsumerStatefulWidget {
  const DemoDataPage({super.key});

  @override
  ConsumerState<DemoDataPage> createState() => _DemoDataPageState();
}

class _DemoDataPageState extends ConsumerState<DemoDataPage> {
  bool _busy = false;
  String _status = '';

  Future<void> _seed() => _run('Đang tạo dữ liệu demo…', (uid, name, username) async {
        await SampleDataSeeder().seed(myUid: uid, myName: name, myUsername: username);
        await LocalDemoSeeder(ref.read(appDatabaseProvider)).seed();
      }, done: 'Đã tạo xong: 50 người dùng + feed, bạn bè, thử thách, streak & thói quen.');

  Future<void> _clear() => _run('Đang xoá dữ liệu demo…', (uid, name, username) async {
        await SampleDataSeeder().clearSeed(myUid: uid);
        await LocalDemoSeeder(ref.read(appDatabaseProvider)).clear();
      }, done: 'Đã xoá toàn bộ dữ liệu demo.');

  Future<void> _run(
    String working,
    Future<void> Function(String uid, String name, String username) action, {
    required String done,
  }) async {
    final user = ref.read(sessionProvider).asData?.value;
    if (user == null) {
      _toast('Bạn cần đăng nhập trước khi tạo dữ liệu demo.');
      return;
    }
    final profile = ref.read(myProfileProvider).asData?.value;
    final name = (profile?.displayName.isNotEmpty ?? false)
        ? profile!.displayName
        : (user.displayName ?? 'Người dùng');
    final username = (profile?.username.isNotEmpty ?? false)
        ? profile!.username
        : 'me_${user.uid.substring(0, user.uid.length.clamp(0, 6))}';

    setState(() {
      _busy = true;
      _status = working;
    });
    try {
      await action(user.uid, name, username);
      // Local FutureProviders need a nudge; Firestore streams refresh on their own.
      ref
        ..invalidate(wakeEventListProvider)
        ..invalidate(streakProvider)
        ..invalidate(dashboardStatsProvider)
        ..invalidate(habitListProvider)
        ..invalidate(leaderboardProvider);
      if (mounted) setState(() => _status = done);
      _toast(done);
    } catch (e) {
      if (mounted) setState(() => _status = 'Lỗi: $e');
      _toast('Thất bại: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Dữ liệu demo')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Tạo 50 người dùng mẫu + làm đầy Feed, Bạn bè, Bảng xếp hạng, '
                    'Thử thách, Thông báo và nạp Streak/Dashboard/Thói quen cho '
                    'tài khoản đang đăng nhập. Chỉ dùng để demo.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: _busy ? null : _seed,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Tạo dữ liệu demo (50 người)'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _busy ? null : _clear,
            icon: const Icon(Icons.delete_outline, color: AppColors.destructive),
            label: const Text('Xoá dữ liệu demo',
                style: TextStyle(color: AppColors.destructive)),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_busy)
            const Center(child: CircularProgressIndicator())
          else if (_status.isNotEmpty)
            Text(_status,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.mutedForeground)),
        ],
      ),
    );
  }
}
