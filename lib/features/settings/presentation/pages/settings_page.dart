import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-level settings.
///
/// TODO (kickoff scaffold):
///   - Request/verify permissions: overlay (SYSTEM_ALERT_WINDOW), exact alarm,
///     notifications, battery-optimization exemption, camera.
///   - Toggle the anti-kill foreground service.
///   - Default dismiss task + default ringtone.
///   - Account (Supabase auth) sign-in/out.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.layers),
            title: Text('Quyền hiển thị trên màn hình khóa'),
            subtitle: Text('TODO: request overlay permission'),
          ),
          ListTile(
            leading: Icon(Icons.alarm),
            title: Text('Quyền báo thức chính xác'),
            subtitle: Text('TODO: request exact alarm permission'),
          ),
          ListTile(
            leading: Icon(Icons.battery_alert),
            title: Text('Bỏ tối ưu hóa pin (chống tắt ngầm)'),
            subtitle: Text('TODO: request ignore battery optimizations'),
          ),
        ],
      ),
    );
  }
}
