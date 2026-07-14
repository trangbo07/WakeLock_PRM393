import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/widgets/avatar_image.dart';
import '../providers/friends_providers.dart';
import 'send_invite_page.dart';

/// Find people by username and start a friend request. QR / link methods are
/// placeholders for now.
class AddFriendPage extends ConsumerStatefulWidget {
  const AddFriendPage({super.key});

  @override
  ConsumerState<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends ConsumerState<AddFriendPage> {
  final _query = TextEditingController();
  List<UserProfile> _results = const [];
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    try {
      final me = ref.read(sessionProvider).asData?.value;
      final results = await ref
          .read(friendsRepositoryProvider)
          .searchByUsername(q, excludeUid: me?.uid ?? '');
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Tìm kiếm lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _searching = false;
          _searched = true;
        });
      }
    }
  }

  void _soon() => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Tính năng sắp ra mắt')));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm bạn bè')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Tìm theo username…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _search,
                      ),
              ),
            ),
          ),
          Expanded(
            child: _searched
                ? _ResultsList(results: _results)
                : ListView(
                    children: [
                      _MethodTile(
                        icon: Icons.qr_code_scanner,
                        title: 'Quét mã QR',
                        subtitle: 'Quét mã để kết bạn',
                        onTap: _soon,
                      ),
                      _MethodTile(
                        icon: Icons.link,
                        title: 'Mời qua link',
                        subtitle: 'Gửi link mời cho bạn bè',
                        onTap: _soon,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.results});
  final List<UserProfile> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Text('Không tìm thấy ai.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = results[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage: avatarImageProvider(
                base64Data: p.avatarBase64, url: p.avatarUrl),
            child: (p.avatarBase64 == null && (p.avatarUrl ?? '').isEmpty)
                ? Text(_initial(
                    p.displayName.isEmpty ? p.username : p.displayName))
                : null,
          ),
          title: Text(p.displayName.isEmpty ? '@${p.username}' : p.displayName),
          subtitle: p.username.isNotEmpty ? Text('@${p.username}') : null,
          trailing: const Icon(Icons.person_add_alt_1),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => SendInvitePage(target: p)),
          ),
        );
      },
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: AppColors.accent),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

String _initial(String s) => s.trim().isEmpty ? '?' : s.trim()[0].toUpperCase();
