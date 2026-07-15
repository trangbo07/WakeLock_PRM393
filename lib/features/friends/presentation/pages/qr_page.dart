import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/invite_link.dart';
import '../providers/friends_providers.dart';
import 'send_invite_page.dart';

/// Add friends via QR: scan someone's code, or show your own for them to scan.
class QrPage extends ConsumerStatefulWidget {
  const QrPage({super.key});

  @override
  ConsumerState<QrPage> createState() => _QrPageState();
}

class _QrPageState extends ConsumerState<QrPage> {
  bool _handling = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    final username = parseInviteUsername(raw);
    if (username == null) return;

    final myUid = ref.read(sessionProvider).asData?.value?.uid ?? '';
    final myUsername = ref.read(myProfileProvider).asData?.value?.username;
    if (username == myUsername) return; // scanned my own code

    setState(() => _handling = true);
    try {
      final results = await ref
          .read(friendsRepositoryProvider)
          .searchByUsername(username, excludeUid: myUid);
      final match = results.where((p) => p.username == username);
      if (match.isEmpty) {
        _toast('Không tìm thấy @$username');
        if (mounted) setState(() => _handling = false);
        return;
      }
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => SendInvitePage(target: match.first)));
      }
    } catch (e) {
      _toast('Lỗi: $e');
      if (mounted) setState(() => _handling = false);
    }
  }

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUsername =
        ref.watch(myProfileProvider).asData?.value?.username ?? '';
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mã QR'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Quét mã'), Tab(text: 'Mã của tôi')],
          ),
        ),
        body: TabBarView(
          children: [
            _ScanTab(onDetect: _onDetect),
            _MyCodeTab(username: myUsername),
          ],
        ),
      ),
    );
  }
}

class _ScanTab extends StatelessWidget {
  const _ScanTab({required this.onDetect});
  final void Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          onDetect: onDetect,
          // Camera/ML-Kit failures (no camera on emulators, denied permission,
          // unsupported device) otherwise surface as a raw native crash string.
          errorBuilder: (context, error) => const _ScanError(),
        ),
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 3),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        const Positioned(
          bottom: 40,
          child: Text('Đưa mã QR của bạn bè vào khung',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

/// Friendly fallback when the camera/ML-Kit scanner can't start (denied
/// permission, unsupported device) instead of a raw native error string.
class _ScanError extends StatelessWidget {
  const _ScanError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.no_photography_outlined,
                  size: 64, color: Colors.white70),
              SizedBox(height: AppSpacing.md),
              Text('Không mở được camera để quét',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Hãy cấp quyền Camera cho ứng dụng, hoặc kết bạn bằng cách '
                'tìm username ở màn trước.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyCodeTab extends StatelessWidget {
  const _MyCodeTab({required this.username});
  final String username;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (username.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Bạn cần đặt username trước.\nVào Hồ sơ → Chỉnh sửa hồ sơ.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: QrImageView(
              data: buildInviteLink(username),
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('@$username',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text('Cho bạn bè quét mã này để kết bạn',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
