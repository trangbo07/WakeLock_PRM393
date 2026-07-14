import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_header.dart';

/// Shown right after sign-up: pick avatar, display name and a unique username,
/// then write them to users/{uid}. "Để sau" skips (profile is optional).
class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  XFile? _avatar;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authRepositoryProvider).currentUser;
    _name.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
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
        .pickImage(source: source, maxWidth: 256, imageQuality: 60);
    if (img != null && mounted) setState(() => _avatar = img);
  }

  Future<void> _finish() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final username = _username.text.trim().toLowerCase();
      final ok = await repo.reserveUsername(username, user.uid);
      if (!ok) {
        _toast('Username "@$username" đã có người dùng');
        return;
      }
      String? avatarBase64;
      if (_avatar != null) {
        // Inline the (small, resized) avatar as base64 — no Cloud Storage.
        avatarBase64 = base64Encode(await _avatar!.readAsBytes());
      }
      await repo.updateProfileFields(
        user.uid,
        username: username,
        displayName: _name.text.trim(),
        avatarBase64: avatarBase64,
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      _toast('Lưu hồ sơ lỗi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authRepositoryProvider).currentUser;
    final photoUrl = user?.photoUrl;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Hoàn tất hồ sơ'),
        actions: [
          TextButton(
            onPressed: _busy
                ? null
                : () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Để sau'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(
                  title: 'Hoàn tất hồ sơ',
                  subtitle: 'Đặt tên hiển thị và username để bạn bè tìm thấy bạn.',
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(child: _AvatarPicker(file: _avatar, photoUrl: photoUrl, onTap: _busy ? null : _pickAvatar)),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nhập tên hiển thị'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _username,
                  autofillHints: const [AutofillHints.newUsername],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _finish(),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixText: '@',
                    helperText: '3–20 ký tự: chữ thường, số, gạch dưới',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: _validateUsername,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: _busy ? 'Đang lưu…' : 'Hoàn tất',
                  onPressed: _busy ? null : _finish,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _validateUsername(String? v) {
  final value = (v ?? '').trim().toLowerCase();
  if (value.isEmpty) return 'Nhập username';
  if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(value)) {
    return '3–20 ký tự, chỉ chữ thường/số/gạch dưới';
  }
  return null;
}

/// Circular avatar with a camera badge. Shows picked file, else remote photo,
/// else a person icon.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.file, required this.photoUrl, this.onTap});

  final XFile? file;
  final String? photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (file != null) {
      image = FileImage(File(file!.path));
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      image = NetworkImage(photoUrl!);
    }
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage: image,
            child: image == null
                ? const Icon(Icons.person, size: 52, color: AppColors.mutedForeground)
                : null,
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.photo_camera, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
