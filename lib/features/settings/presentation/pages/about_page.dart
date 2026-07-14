import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';

/// Static "about the app" screen: identity, version, and a short description.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Về ứng dụng')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 18),
                ],
              ),
              child: const Icon(Icons.alarm, color: Colors.white, size: 52),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text('WakeLock',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          Center(
            child: Text('Phiên bản $_version',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.mutedForeground)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Báo thức "không thể trốn tránh": nhiệm vụ tắt chuông, chuỗi dậy '
              'sớm, và mạng xã hội để cùng bạn bè giữ thói quen dậy đúng giờ.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _InfoRow(label: 'Nhà phát triển', value: 'Nhóm PRM393'),
          const _InfoRow(label: 'Nền tảng', value: 'Android'),
          const _InfoRow(label: 'Công nghệ', value: 'Flutter · Firebase'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.mutedForeground)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
