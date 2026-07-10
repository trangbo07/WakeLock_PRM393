import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/alarm_model.dart';

/// Supabase-backed remote source for alarms (table [AppConstants.alarmsTable]).
///
/// Assumes Row Level Security scoping rows to the signed-in user; `user_id`
/// should be defaulted server-side via `auth.uid()`.
class AlarmRemoteDataSource {
  AlarmRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<AlarmModel>> fetchAll() async {
    final rows = await _client.from(AppConstants.alarmsTable).select();
    return rows
        .map((e) => AlarmModel.fromJson(e))
        .toList(growable: false);
  }

  Future<void> upsert(AlarmModel alarm) async {
    await _client.from(AppConstants.alarmsTable).upsert(alarm.toJson());
  }

  Future<void> delete(String id) async {
    await _client.from(AppConstants.alarmsTable).delete().eq('id', id);
  }

  // TODO: expose a realtime stream via `_client.from(table).stream(...)`.
}
