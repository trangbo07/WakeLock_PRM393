import 'package:flutter/material.dart';

/// Separate Flutter entry point for the system overlay window rendered by
/// `flutter_overlay_window` (registered via [OverlayService]).
///
/// It runs in its own engine, so keep it self-contained — no shared Riverpod
/// state with the main app. Communicate via `FlutterOverlayWindow` message
/// channels if needed.
@pragma('vm:entry-point')
void overlayMain() {
  runApp(const _OverlayApp());
}

class _OverlayApp extends StatelessWidget {
  const _OverlayApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'BÁO THỨC!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
