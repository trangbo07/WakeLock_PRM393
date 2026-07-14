import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../providers/ai_coach_providers.dart';

/// A single coaching tip, generated from the user's recent wake/habit stats.
/// "Làm mới" regenerates it — no chat history is kept.
class AiCoachPage extends ConsumerWidget {
  const AiCoachPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipAsync = ref.watch(aiCoachTipProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const _Hero(),
          const SizedBox(height: AppSpacing.lg),
          _TipBubble(tipAsync: tipAsync),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
              onPressed: () => ref.invalidate(aiCoachTipProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Làm mới gợi ý'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 32),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Coach',
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                const Text(
                  'Gợi ý cá nhân từ thói quen dậy của bạn',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipBubble extends StatelessWidget {
  const _TipBubble({required this.tipAsync});

  final AsyncValue<String> tipAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text('Huấn luyện viên',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          tipAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                children: [
                  SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: Text('Đang phân tích thói quen của bạn…',
                          style: TextStyle(color: AppColors.mutedForeground))),
                ],
              ),
            ),
            error: (e, _) => const Text(
                'Không tải được gợi ý, thử "Làm mới" nhé.',
                style: TextStyle(color: AppColors.mutedForeground)),
            data: (tip) => Text(
              tip,
              style: theme.textTheme.titleMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
