import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../friends/presentation/providers/friends_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/avatar_image.dart';
import '../../domain/entities/challenge.dart';
import '../providers/challenge_providers.dart';
import 'challenge_detail_page.dart';

/// Create a challenge: name it, pick a duration, and invite friends.
class CreateChallengePage extends ConsumerStatefulWidget {
  const CreateChallengePage({super.key});

  @override
  ConsumerState<CreateChallengePage> createState() =>
      _CreateChallengePageState();
}

class _CreateChallengePageState extends ConsumerState<CreateChallengePage> {
  final _title = TextEditingController(text: 'Thử thách dậy sớm');
  int _days = 7;
  final Set<String> _invited = {};
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final user = ref.read(sessionProvider).asData?.value;
    if (user == null) return;
    final title = _title.text.trim();
    if (title.isEmpty) {
      _toast('Nhập tên thử thách');
      return;
    }
    setState(() => _busy = true);
    try {
      final me = ref.read(myProfileProvider).asData?.value;
      final friends = ref.read(friendsListProvider).asData?.value ?? const [];
      final participants = <ChallengeParticipant>[
        ChallengeParticipant(
          uid: user.uid,
          name: (me?.displayName.isNotEmpty ?? false)
              ? me!.displayName
              : (user.displayName ?? 'Tôi'),
          username: me?.username ?? '',
          avatarUrl: me?.avatarUrl ?? user.photoUrl,
          avatarBase64: me?.avatarBase64,
        ),
        ...friends.where((f) => _invited.contains(f.uid)).map(
              (f) => ChallengeParticipant(
                uid: f.uid,
                name: f.name,
                username: f.username,
                avatarUrl: f.avatarUrl,
                avatarBase64: f.avatarBase64,
              ),
            ),
      ];
      final id = await ref.read(challengeRepositoryProvider).createChallenge(
            title: title,
            days: _days,
            participants: participants,
          );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => ChallengeDetailPage(challengeId: id)),
        );
      }
    } catch (e) {
      _toast('Tạo lỗi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friends = ref.watch(friendsListProvider).asData?.value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo thử thách')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Tên thử thách'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Thời gian', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final d in [7, 14, 30])
                  ChoiceChip(
                    label: Text('$d ngày'),
                    selected: _days == d,
                    onSelected: (_) => setState(() => _days = d),
                    selectedColor: AppColors.accent,
                    labelStyle: TextStyle(
                        color: _days == d ? Colors.white : null,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Mời bạn bè (${_invited.length})',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            if (friends.isEmpty)
              Text('Bạn chưa có bạn bè để mời. Vẫn có thể tạo thử thách cá nhân.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.mutedForeground))
            else
              ...friends.map((f) {
                final selected = _invited.contains(f.uid);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selected,
                  activeColor: AppColors.accent,
                  onChanged: (v) => setState(() =>
                      v == true ? _invited.add(f.uid) : _invited.remove(f.uid)),
                  secondary: CircleAvatar(
                    backgroundColor: AppColors.surfaceMuted,
                    backgroundImage: avatarImageProvider(
                        base64Data: f.avatarBase64, url: f.avatarUrl),
                    child: (f.avatarBase64 == null && (f.avatarUrl ?? '').isEmpty)
                        ? Text(f.name.isEmpty ? '?' : f.name[0].toUpperCase())
                        : null,
                  ),
                  title: Text(f.name.isEmpty ? '@${f.username}' : f.name),
                );
              }),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary),
                onPressed: _busy ? null : _create,
                child: Text(_busy ? 'Đang tạo…' : 'Tạo thử thách'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
