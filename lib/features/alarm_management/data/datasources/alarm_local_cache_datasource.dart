import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/alarm_model.dart';

/// Local mirror of the alarm list so the background scheduler can operate
/// offline (no network at 6 AM). Supabase remains the source of truth; this is
/// last-known state only.
class AlarmLocalCacheDataSource {
  Future<List<AlarmModel>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.cachedAlarmsKey);
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => AlarmModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> writeAll(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(alarms.map((a) => a.toJson()).toList());
    await prefs.setString(AppConstants.cachedAlarmsKey, raw);
  }
}
