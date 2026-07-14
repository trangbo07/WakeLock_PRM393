import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/avatar_image.dart';
import '../providers/friends_providers.dart';

/// Send a friend request to [target], with a short message. Shows a
/// confirmation once sent.
class SendInvitePage extends ConsumerStatefulWidget {
  const SendInvitePage({super.key, required this.target});

  final UserProfile target;

  @override
  ConsumerState<SendInvitePage> createState() => _SendInvitePageState();
}

class _SendInvitePageState extends ConsumerState<SendInvitePage> {
  final _message =
      TextEditingController(text: 'Mình muốn kết bạn với bạn trên WakeLock!');
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = ref.read(sessionProvider).asData?.value;
    if (user == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final me = ref.read(myProfileProvider).asData?.value ??
          UserProfile(uid: user.uid, displayName: user.displayName ?? '');
      await ref.read(friendsRepositoryProvider).sendRequest(
            me: me,
            toUid: widget.target.uid,
            message: _message.text.trim(),
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
    return Scaffold(
      appBar: AppBar(title: Text(_sent ? 'Chờ xác nhận' : 'Gửi lời mời')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _sent ? _SentView(name: t.displayName.isEmpty ? t.username : t.displayName) : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Center(
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.surfaceMuted,
                  backgroundImage: avatarImageProvider(
                      base64Data: t.avatarBase64, url: t.avatarUrl),
                  child: (t.avatarBase64 == null && (t.avatarUrl ?? '').isEmpty)
                      ? Text(
                          _initial(t.displayName.isEmpty ? t.username : t.displayName),
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(color: AppColors.primary))
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(t.displayName.isEmpty ? '@${t.username}' : t.displayName,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (t.username.isNotEmpty)
                Center(
                  child: Text('@${t.username}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _message,
                maxLines: 3,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Lời nhắn kết bạn',
                  alignLabelWithHint: true,
                ),
              ),
              const Spacer(),
              AppPrimaryButton(
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
            size: 88, color: AppColors.primary),
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
        AppPrimaryButton(
          label: 'Xong',
          onPressed: () =>
              Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ],
    );
  }
}

String _initial(String s) => s.trim().isEmpty ? '?' : s.trim()[0].toUpperCase();
