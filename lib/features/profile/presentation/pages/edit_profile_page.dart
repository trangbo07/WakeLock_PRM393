import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../widgets/avatar_image.dart';

/// Edit the signed-in user's profile (avatar / name / username / bio) and save
/// to Firestore. Reachable from the Profile tab. Username uniqueness is only
/// re-checked when it actually changes.
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  String _initialUsername = '';
  XFile? _avatar;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(myProfileProvider).asData?.value;
    final user = ref.read(authRepositoryProvider).currentUser;
    _name = TextEditingController(
        text: p?.displayName.isNotEmpty == true
            ? p!.displayName
            : (user?.displayName ?? ''));
    _username = TextEditingController(text: p?.username ?? '');
    _bio = TextEditingController(text: p?.bio ?? '');
    _initialUsername = p?.username ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
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

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      Navigator.of(context).pop();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final username = _username.text.trim().toLowerCase();
      if (username != _initialUsername) {
        final ok = await repo.reserveUsername(username, user.uid);
        if (!ok) {
          _toast('Username "@$username" đã có người dùng');
          return;
        }
      }
      String? avatarBase64;
      if (_avatar != null) {
        avatarBase64 = base64Encode(await _avatar!.readAsBytes());
      }
      await repo.updateProfileFields(
        user.uid,
        username: username,
        displayName: _name.text.trim(),
        bio: _bio.text.trim(),
        avatarBase64: avatarBase64,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _toast('Lưu lỗi: $e');
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
    final p = ref.watch(myProfileProvider).asData?.value;
    final ImageProvider? preview = _avatar != null
        ? FileImage(File(_avatar!.path))
        : avatarImageProvider(
            base64Data: p?.avatarBase64, url: p?.avatarUrl);

    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _busy ? null : _pickAvatar,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.surfaceMuted,
                          backgroundImage: preview,
                          child: preview == null
                              ? const Icon(Icons.person,
                                  size: 48,
                                  color: AppColors.mutedForeground)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.photo_camera,
                              size: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nhập tên hiển thị' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixText: '@',
                    prefixIcon: Icon(Icons.alternate_email),
                    helperText: '3–20 ký tự: chữ thường, số, gạch dưới',
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim().toLowerCase();
                    if (value.isEmpty) return 'Nhập username';
                    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(value)) {
                      return '3–20 ký tự, chỉ chữ thường/số/gạch dưới';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _bio,
                  maxLines: 3,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Giới thiệu',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppPrimaryButton(
                  label: _busy ? 'Đang lưu…' : 'Lưu',
                  onPressed: _busy ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
