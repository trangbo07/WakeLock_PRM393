import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/feed_providers.dart';

/// Capture (or pick) a morning photo + caption and publish it to the feed.
/// Photo is downscaled and stored base64 in Firestore (Cloud Storage is paid).
class ComposePostPage extends ConsumerStatefulWidget {
  const ComposePostPage({super.key});

  @override
  ConsumerState<ComposePostPage> createState() => _ComposePostPageState();
}

class _ComposePostPageState extends ConsumerState<ComposePostPage> {
  final _captionCtl = TextEditingController();
  XFile? _photo;
  bool _busy = false;

  @override
  void dispose() {
    _captionCtl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final img = await ImagePicker()
        .pickImage(source: source, maxWidth: 1080, imageQuality: 60);
    if (img != null && mounted) setState(() => _photo = img);
  }

  Future<void> _post() async {
    if (_photo == null) {
      _toast('Hãy chọn một tấm ảnh trước.');
      return;
    }
    final user = ref.read(sessionProvider).asData?.value;
    if (user == null) {
      _toast('Bạn cần đăng nhập để đăng bài.');
      return;
    }
    setState(() => _busy = true);
    try {
      final p = ref.read(myProfileProvider).asData?.value;
      final base64 = base64Encode(await _photo!.readAsBytes());
      await ref.read(feedRepositoryProvider).createPost(
            authorUid: user.uid,
            authorName: (p?.displayName.isNotEmpty ?? false)
                ? p!.displayName
                : (user.displayName ?? 'Tôi'),
            authorUsername: p?.username ?? '',
            authorAvatarUrl: p?.avatarUrl ?? user.photoUrl,
            authorAvatarBase64: p?.avatarBase64,
            photoBase64: base64,
            caption: _captionCtl.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng ảnh buổi sáng!')),
        );
      }
    } catch (e) {
      _toast('Đăng lỗi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ảnh buổi sáng')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PhotoPicker(photo: _photo, onTap: _pick),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _captionCtl,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Chú thích',
                  hintText: 'Chào buổi sáng! ☀️',
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  onPressed: _busy ? null : _post,
                  icon: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: Text(_busy ? 'Đang đăng…' : 'Đăng lên feed'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photo, required this.onTap});

  final XFile? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            image: photo != null
                ? DecorationImage(
                    image: FileImage(File(photo!.path)), fit: BoxFit.cover)
                : null,
          ),
          child: photo == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        size: 48, color: AppColors.mutedForeground),
                    SizedBox(height: AppSpacing.sm),
                    Text('Chạm để chụp / chọn ảnh',
                        style: TextStyle(color: AppColors.mutedForeground)),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}
