import 'package:permission_handler/permission_handler.dart';

/// The Android permissions WakeLock needs for its hardcore behavior, each with
/// a user-facing description. Kept in one place so the settings screen and any
/// onboarding flow request the same set.
enum AppPermission {
  notification(
    'Thông báo',
    'Hiển thị báo thức toàn màn hình khi tới giờ',
    Permission.notification,
  ),
  exactAlarm(
    'Báo thức chính xác',
    'Đặt lịch reo đúng giây, kể cả khi máy đang ngủ',
    Permission.scheduleExactAlarm,
  ),
  overlay(
    'Hiển thị trên màn hình khóa',
    'Vẽ màn hình báo thức đè lên mọi ứng dụng',
    Permission.systemAlertWindow,
  ),
  ignoreBattery(
    'Bỏ tối ưu hóa pin',
    'Chống hệ thống tắt ngầm ứng dụng trước khi báo thức reo',
    Permission.ignoreBatteryOptimizations,
  ),
  camera(
    'Máy ảnh',
    'Dùng cho nhiệm vụ quét QR / chụp ảnh để tắt báo thức',
    Permission.camera,
  );

  const AppPermission(this.title, this.description, this.permission);

  final String title;
  final String description;
  final Permission permission;

  Future<bool> isGranted() => permission.isGranted;

  /// Request the permission; returns the resulting granted state.
  Future<bool> request() async => (await permission.request()).isGranted;
}
