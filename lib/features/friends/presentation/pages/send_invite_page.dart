import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/avatar_image.dart';
import '../providers/friends_providers.dart';

const _kInviteMessage = 'Mình muốn kết bạn với bạn trên WakeLock!';

/// Send a friend request to [target]. Shows a confirmation once sent
/// (matches the "Gửi lời mời" → "Chờ xác nhận" mockups).
class SendInvitePage extends ConsumerStatefulWidget {
  const SendInvitePage({super.key, required this.target});

  final UserProfile target;

  @override
  ConsumerState<SendInvitePage> createState() => _SendInvitePageState();
}

class _SendInvitePageState extends ConsumerState<SendInvitePage> {
  bool _busy = false;
  bool _sent = false;

  Future<void> _send() async {
    final user = ref.read(sessionProvider).asData?.value;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final me = ref.read(myProfileProvider).asData?.value ??
          UserProfile(uid: user.uid, displayName: user.displayName ?? '');
      await ref.read(friendsRepositoryProvider).sendRequest(
            me: me,
            toUid: widget.target.uid,
            message: _kInviteMessage,
          );
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gửi lời mời lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.target;
    final theme = Theme.of(context);
    final name = t.displayName.isEmpty ? '@${t.username}' : t.displayName;

    return Scaffold(
      appBar: AppBar(title: Text(_sent ? 'Chờ xác nhận' : 'Gửi lời mời')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _sent
              ? _SentView(name: name)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.surfaceMuted,
                        backgroundImage: avatarImageProvider(
                            base64Data: t.avatarBase64, url: t.avatarUrl),
                        child: (t.avatarBase64 == null &&
                                (t.avatarUrl ?? '').isEmpty)
                            ? Text(_initial(name),
                                style: theme.textTheme.headlineMedium
                                    ?.copyWith(color: AppColors.primary))
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text(name,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    if (t.username.isNotEmpty)
                      Center(
                        child: Text('@${t.username}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lời mời kết bạn',
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(_kInviteMessage,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _IndigoButton(
                      label: _busy ? 'Đang gửi…' : 'Gửi lời mời',
                      onPressed: _busy ? null : _send,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SentView extends StatelessWidget {
  const _SentView({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 96, color: AppColors.accent),
        const SizedBox(height: AppSpacing.lg),
        Text('Lời mời đã gửi!',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Khi $name chấp nhận, hai bạn sẽ trở thành bạn bè.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xl),
        _IndigoButton(
          label: 'Xong',
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ],
    );
  }
}

/// Full-width indigo button (matches the Friends CTA style).
class _IndigoButton extends StatelessWidget {
  const _IndigoButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

String _initial(String s) => s.trim().isEmpty ? '?' : s.trim()[0].toUpperCase();
