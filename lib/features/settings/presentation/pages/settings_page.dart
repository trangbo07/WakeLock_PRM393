import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_permission.dart';

/// Permission onboarding: shows each hardcore permission with its live grant
/// status and a button to request it. Re-checks on resume so returning from
/// system settings updates the row.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  final Map<AppPermission, bool> _granted = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the system settings screen — re-read grant status.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    for (final p in AppPermission.values) {
      _granted[p] = await p.isGranted();
    }
    if (mounted) setState(() {});
  }

  Future<void> _request(AppPermission p) async {
    final granted = await p.request();
    if (mounted) setState(() => _granted[p] = granted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt & Quyền')),
      body: ListView(
        children: [
          for (final p in AppPermission.values)
            ListTile(
              leading: Icon(
                (_granted[p] ?? false)
                    ? Icons.check_circle
                    : Icons.error_outline,
                color: (_granted[p] ?? false) ? Colors.green : Colors.orange,
              ),
              title: Text(p.title),
              subtitle: Text(p.description),
              trailing: (_granted[p] ?? false)
                  ? null
                  : TextButton(
                      onPressed: () => _request(p),
                      child: const Text('Cấp quyền'),
                    ),
            ),
        ],
      ),
    );
  }
}
