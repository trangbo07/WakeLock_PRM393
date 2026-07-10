import 'package:flutter/material.dart';

import '../../features/alarm_management/presentation/pages/alarm_edit_page.dart';
import '../../features/alarm_management/presentation/pages/alarm_list_page.dart';
import '../../features/ringtone/presentation/pages/ringtone_picker_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

/// Named routes + a simple `onGenerateRoute`. Swap for go_router later if the
/// navigation graph grows (deep links from notifications, etc.).
class AppRouter {
  AppRouter._();

  static const String home = '/';
  static const String alarmEdit = '/alarm-edit';
  static const String ringtonePicker = '/ringtones';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _page(const AlarmListPage());
      case alarmEdit:
        return _page(const AlarmEditPage());
      case ringtonePicker:
        return _page(const RingtonePickerPage());
      case AppRouter.settings:
        return _page(const SettingsPage());
      default:
        return _page(const AlarmListPage());
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget child) =>
      MaterialPageRoute<dynamic>(builder: (_) => child);
}
