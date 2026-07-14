import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/post.dart';
import '../providers/feed_providers.dart';
import '../widgets/feed_helpers.dart';
import '../widgets/reaction_picker_sheet.dart';

/// Full post view: photo, caption, reactions and comments with a compose bar.
class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({super.key, required this.post});

  final Post post;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _commentCtl = TextEditingController();
  String? _myReaction;
  int _reactionCount = 0;
  bool _sending = false;

  String get _postId => widget.post.id;

  @override
  void initState() {
    super.initState();
    _reactionCount = widget.post.reactionCount;
    _loadMyReaction();
  }

  @override
  void dispose() {
    _commentCtl.dispose();
    super.dispose();
  }

  Future<void> _loadMyReaction() async {
    final uid = ref.read(sessionProvider).asData?.value?.uid;
    if (uid == null) return;
    final emoji = await ref.read(feedRepositoryProvider).myReaction(_postId, uid);
    if (mounted && emoji != null) setState(() => _myReaction = emoji);
  }

  ({String uid, String name, String? avatarUrl, String? avatarB64})? _me() {
    final user = ref.read(sessionProvider).asData?.value;
    if (user == null) return null;
    final p = ref.read(myProfileProvider).asData?.value;
    return (
      uid: user.uid,
      name: p?.displayName.isNotEmpty == true
          ? p!.displayName
          : (user.displayName ?? 'Tôi'),
      avatarUrl: p?.avatarUrl ?? user.photoUrl,
      avatarB64: p?.avatarBase64,
    );
  }

  Future<void> _setReaction(String emoji) async {
    final me = _me();
    if (me == null) return _needLogin();
    final was = _myReaction;
    setState(() {
      if (was == null) _reactionCount++;
      _myReaction = emoji;
    });
    await ref.read(feedRepositoryProvider).setReaction(
          _postId,
          uid: me.uid,
          emoji: emoji,
          name: me.name,
          avatarUrl: me.avatarUrl,
          avatarBase64: me.avatarB64,
        );
  }

  Future<void> _removeReaction() async {
    final me = _me();
    if (me == null) return;
    setState(() {
      if (_myReaction != null) _reactionCount--;
      _myReaction = null;
    });
    await ref.read(feedRepositoryProvider).removeReaction(_postId, me.uid);
  }

  void _openPicker() {
    if (_me() == null) return _needLogin();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (_) => ReactionPickerSheet(
        postId: _postId,
        current: _myReaction,
        onSelect: _setReaction,
        onRemove: _removeReaction,
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _commentCtl.text.trim();
    if (text.isEmpty) return;
    final me = _me();
    if (me == null) return _needLogin();
    setState(() => _sending = true);
    try {
      await ref.read(feedRepositoryProvider).addComment(
            _postId,
            uid: me.uid,
            name: me.name,
            avatarUrl: me.avatarUrl,
            avatarBase64: me.avatarB64,
            text: text,
          );
      _commentCtl.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _needLogin() => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập để tương tác với bài đăng.')),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final comments = ref.watch(commentsProvider(_postId));
    final name =
        post.authorName.isEmpty ? '@${post.authorUsername}' : post.authorName;

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              children: [
                _photo(post),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.caption.isNotEmpty)
                        Text(post.caption, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(timeAgo(post.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      const Divider(height: AppSpacing.xl),
                      _reactionBar(theme),
                      const SizedBox(height: AppSpacing.md),
                      Text('Bình luận', style: theme.textTheme.titleSmall),
                    ],
                  ),
                ),
                comments.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text('Lỗi bình luận: $e'),
                  ),
                  data: (list) => list.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text('Chưa có bình luận nào.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        )
                      : Column(
                          children: [for (final c in list) _commentTile(c)],
                        ),
                ),
              ],
            ),
          ),
          _composeBar(),
        ],
      ),
    );
  }

  Widget _photo(Post post) {
    final img =
        postImageProvider(base64Data: post.photoBase64, url: post.photoUrl);
    return AspectRatio(
      aspectRatio: 1,
      child: img == null
          ? Container(color: AppColors.surfaceMuted)
          : Image(image: img, fit: BoxFit.cover),
    );
  }

  Widget _reactionBar(ThemeData theme) {
    final active = _myReaction != null;
    return Row(
      children: [
        Material(
          color: active
              ? AppColors.accent.withValues(alpha: 0.20)
              : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            onTap: _openPicker,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  reactionGlyph(_myReaction ?? '❤️', size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(active ? 'Đã thả' : 'Thả cảm xúc'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text('$_reactionCount cảm xúc',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _commentTile(Comment c) {
    final name = c.name.isEmpty ? 'Người dùng' : c.name;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceMuted,
        backgroundImage:
            postImageProvider(base64Data: c.avatarBase64, url: c.avatarUrl),
        child: (c.avatarBase64 == null && (c.avatarUrl ?? '').isEmpty)
            ? Text(initialOf(name),
                style: const TextStyle(color: AppColors.primary))
            : null,
      ),
      title: Text(name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(c.text),
      trailing: Text(timeAgo(c.createdAt),
          style: TextStyle(
              fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }

  Widget _composeBar() => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentCtl,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendComment(),
                  decoration: const InputDecoration(
                    hintText: 'Viết bình luận…',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: _sending ? null : _sendComment,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, color: AppColors.accent),
              ),
            ],
          ),
        ),
      );
}
