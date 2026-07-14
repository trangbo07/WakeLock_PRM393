import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_header.dart';
import '../widgets/google_button.dart';
import 'register_page.dart';

/// Email/password sign-in. Wired to authRepositoryProvider; on success
/// sessionProvider emits the user and we pop back to the caller (e.g. Profile).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmail(_email.text.trim(), _password.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _toast('Đăng nhập thất bại: ${_readable(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _email.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đặt lại mật khẩu'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'nhập email của bạn',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      _toast('Đã gửi email đặt lại mật khẩu tới $email');
    } catch (e) {
      _toast('Không gửi được: ${_readable(e)}');
    }
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // User dismissed the Google sheet → stay silent; else surface the error.
      if (!e.toString().contains('canceled')) {
        _toast('Đăng nhập Google lỗi: ${_readable(e)}');
      }
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
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
                  title: 'Chào mừng trở lại',
                  subtitle: 'Đăng nhập để mở khoá Feed, bạn bè và thử thách.',
                ),
                const SizedBox(height: AppSpacing.xl),
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
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                      tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Nhập mật khẩu'
                      : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : _forgotPassword,
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppPrimaryButton(
                  label: _busy ? 'Đang đăng nhập…' : 'Đăng nhập',
                  onPressed: _busy ? null : _signIn,
                ),
                const SizedBox(height: AppSpacing.lg),
                _OrDivider(color: theme.colorScheme.outline),
                const SizedBox(height: AppSpacing.lg),
                GoogleButton(onPressed: _busy ? null : _google),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Chưa có tài khoản?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                    builder: (_) => const RegisterPage()),
                              ),
                      child: const Text('Đăng ký'),
                    ),
                  ],
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

/// Turns a FirebaseAuthException-ish error into a short Vietnamese message.
String _readable(Object e) {
  final s = e.toString();
  if (s.contains('invalid-credential') || s.contains('wrong-password')) {
    return 'sai email hoặc mật khẩu';
  }
  if (s.contains('user-not-found')) return 'tài khoản không tồn tại';
  if (s.contains('network')) return 'lỗi mạng';
  if (s.contains('too-many-requests')) return 'thử lại sau ít phút';
  return 'vui lòng thử lại';
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Divider(color: color));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('hoặc',
              style: TextStyle(color: AppColors.mutedForeground)),
        ),
        line,
      ],
    );
  }
}
