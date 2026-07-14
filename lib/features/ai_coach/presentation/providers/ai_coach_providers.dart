import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../streak/presentation/providers/streak_providers.dart';
import '../../data/gemini_coach_service.dart';

final geminiCoachServiceProvider = Provider<GeminiCoachService>(
  (ref) => GeminiCoachService(apiKey: Env.geminiApiKey),
);

/// One tip, generated fresh each time this provider is (re)watched — the
/// page's "Làm mới" button calls `ref.invalidate(aiCoachTipProvider)`.
final aiCoachTipProvider = FutureProvider<String>((ref) async {
  final streak = await ref.watch(streakProvider.future);
  final dashboard = await ref.watch(dashboardStatsProvider.future);
  final summary = 'Streak hiện tại ${streak.current} ngày (dài nhất ${streak.longest} ngày). '
      'Tỷ lệ thức đúng giờ 7 ngày gần đây: ${dashboard.wakeRate7dPercent.round()}%. '
      'Số lần báo lại (snooze) trung bình mỗi lần: ${dashboard.avgSnoozeCount.toStringAsFixed(1)}. '
      'Tỷ lệ hoàn thành thói quen: ${dashboard.habitCompletionRatePercent.round()}%.';
  return ref.watch(geminiCoachServiceProvider).getTip(summary);
});
