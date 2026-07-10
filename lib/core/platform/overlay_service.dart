import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Controls the lock-screen overlay window that draws over other apps and the
/// keyguard when an alarm fires (the "đè màn hình khóa" behavior).
///
/// Requires the SYSTEM_ALERT_WINDOW permission, which the user must grant from
/// system settings — call [requestPermission] first.
class OverlayService {
  Future<bool> hasPermission() => FlutterOverlayWindow.isPermissionGranted();

  Future<bool?> requestPermission() => FlutterOverlayWindow.requestPermission();

  /// Show the full-screen ringing overlay. The overlay UI itself is defined by
  /// the `overlayMain` entry point (see alarm_ringing/.../overlay_entry.dart).
  Future<void> showRinging() {
    return FlutterOverlayWindow.showOverlay(
      overlayTitle: 'Báo thức',
      overlayContent: 'Chạm để tắt',
      enableDrag: false,
    );
  }

  Future<void> close() => FlutterOverlayWindow.closeOverlay();

  Future<bool> get isActive => FlutterOverlayWindow.isActive();
}
