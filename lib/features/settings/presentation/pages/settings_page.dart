import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import 'about_page.dart';
import 'permissions_page.dart';

/// Grouped settings menu. Built rows (permissions, notifications, about) work;
/// not-yet-built rows show a "coming soon" note. Reached from the Profile tab.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _soon(BuildContext context, String name) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text('"$name" đang được phát triển.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SettingRow(
            icon: Icons.tune,
            color: AppColors.mutedForeground,
            title: 'Chung',
            onTap: () => _soon(context, 'Chung'),
          ),
          _SettingRow(
            icon: Icons.volume_up_outlined,
            color: const Color(0xFF0EA5E9),
            title: 'Âm báo & Rung',
            onTap: () => _soon(context, 'Âm báo & Rung'),
          ),
          _SettingRow(
            icon: Icons.shield_outlined,
            color: AppColors.primary,
            title: 'Chống tắt ứng dụng',
            subtitle: 'Quyền để báo thức không thể bị tắt',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PermissionsPage()),
            ),
          ),
          _SettingRow(
            icon: Icons.backup_outlined,
            color: const Color(0xFF22C55E),
            title: 'Sao lưu & Khôi phục',
            onTap: () => _soon(context, 'Sao lưu & Khôi phục'),
          ),
          _SettingRow(
            icon: Icons.language,
            color: const Color(0xFF8B5CF6),
            title: 'Ngôn ngữ',
            trailing: 'Tiếng Việt',
            onTap: () => _soon(context, 'Ngôn ngữ'),
          ),
          _SettingRow(
            icon: Icons.palette_outlined,
            color: AppColors.accent,
            title: 'Giao diện',
            trailing: 'Tối',
            onTap: () => _soon(context, 'Giao diện'),
          ),
          _SettingRow(
            icon: Icons.notifications_outlined,
            color: const Color(0xFFEF4444),
            title: 'Thông báo',
            subtitle: 'Mở cài đặt thông báo hệ thống',
            onTap: openAppSettings,
          ),
          _SettingRow(
            icon: Icons.info_outline,
            color: AppColors.mutedForeground,
            title: 'Về ứng dụng',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AboutPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.mutedForeground)),
                  ],
                ),
              ),
              if (trailing != null) ...[
                Text(trailing!,
                    style: const TextStyle(color: AppColors.mutedForeground)),
                const SizedBox(width: AppSpacing.xs),
              ],
              const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
