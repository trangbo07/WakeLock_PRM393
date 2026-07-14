import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_header.dart';

/// Email/password registration. On success it creates a starter Firestore
/// profile (`users/{uid}`) then pops. Username uniqueness / avatar come later
/// in Complete Profile.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .registerWithEmail(_email.text.trim(), _password.text);
      // Best-effort starter profile; don't block the user if it fails (rules/net).
      try {
        final localPart = _email.text.trim().split('@').first.toLowerCase();
        await ref.read(profileRepositoryProvider).upsertProfile(
              UserProfile(
                uid: user.uid,
                username: localPart,
                displayName: _name.text.trim(),
              ),
            );
      } catch (_) {/* profile doc can be created later in Complete Profile */}
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _toast('Đăng ký thất bại: ${_readable(e)}');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
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
                  title: 'Tạo tài khoản',
                  subtitle: 'Tham gia để chia sẻ streak và thử thách cùng bạn bè.',
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nhập tên hiển thị' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    helperText: 'Ít nhất 6 ký tự',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                      tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mật khẩu tối thiểu 6 ký tự'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  decoration: const InputDecoration(
                    labelText: 'Nhập lại mật khẩu',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      v != _password.text ? 'Mật khẩu không khớp' : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppPrimaryButton(
                  label: _busy ? 'Đang tạo tài khoản…' : 'Đăng ký',
                  onPressed: _busy ? null : _register,
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton(
                    onPressed:
                        _busy ? null : () => Navigator.of(context).pop(),
                    child: const Text('Đã có tài khoản? Đăng nhập'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _validateEmail(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Nhập email';
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  return ok ? null : 'Email không hợp lệ';
}

String _readable(Object e) {
  final s = e.toString();
  if (s.contains('email-already-in-use')) return 'email đã được dùng';
  if (s.contains('weak-password')) return 'mật khẩu quá yếu';
  if (s.contains('invalid-email')) return 'email không hợp lệ';
  if (s.contains('network')) return 'lỗi mạng';
  return 'vui lòng thử lại';
}
