import 'package:flutter/material.dart';

import '../../features/alarm_management/domain/entities/alarm.dart';
import '../../features/alarm_management/presentation/pages/alarm_edit_page.dart';
import '../../features/alarm_management/presentation/pages/alarm_list_page.dart';
import '../../features/alarm_ringing/presentation/pages/alarm_ringing_page.dart';
import '../../features/ringtone/presentation/pages/ringtone_picker_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

/// Named routes + a simple `onGenerateRoute`. Swap for go_router later if the
/// navigation graph grows (deep links from notifications, etc.).
class AppRouter {
  AppRouter._();

  /// Lets non-widget code (notification launch wiring in app.dart) navigate.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String home = '/';
  static const String alarmEdit = '/alarm-edit';
  static const String alarmRinging = '/ringing';
  static const String ringtonePicker = '/ringtones';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _page(const AlarmListPage());
      case alarmEdit:
        // Pass an Alarm as `arguments` to edit it; null creates a new one.
        return _page(AlarmEditPage(existing: settings.arguments as Alarm?));
      case alarmRinging:
        return _page(AlarmRingingPage(alarm: settings.arguments as Alarm));
      case ringtonePicker:
        // Optional String argument = the currently-selected ringtone id.
        return _page(
          RingtonePickerPage(selectedId: settings.arguments as String?),
        );
      case AppRouter.settings:
        return _page(const SettingsPage());
      default:
        return _page(const AlarmListPage());
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget child) =>
      MaterialPageRoute<dynamic>(builder: (_) => child);
}
