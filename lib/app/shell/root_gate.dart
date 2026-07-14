import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/splash_page.dart';
import 'main_shell.dart';

/// Root of the `home` route: shows the branded [SplashPage] briefly, then the
/// [MainShell]. It swaps via setState (NOT a navigator push), so the alarm
/// ring-launch flow in app.dart (which pushes on the root navigator) is
/// unaffected — the ring screen still layers cleanly on top.
///
/// Login is optional: everyone lands on MainShell (guest or signed-in); social
/// tabs prompt sign-in on their own.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // App init already ran in bootstrap(); this is just a brief brand moment.
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _ready ? const MainShell() : const SplashPage(),
    );
  }
}
