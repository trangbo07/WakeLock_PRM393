import '../entities/wake_event.dart';

/// Persistence-agnostic access to `wake_events` — the streak/dashboard
/// backbone. Written by `alarm_ringing` as an alarm fires/is dismissed/is
/// snoozed; read by `streak`, `dashboard`, and `ai_coach`.
abstract class WakeEventRepository {
  /// Create the row for a freshly-fired alarm. Returns the new event's id.
  Future<String> insertFired({required String? alarmId, required DateTime firedAt});

  /// Record a successful Mission dismiss: sets `dismissedAt`,
  /// `missionCompleted = true`, and `wakeSuccess` per [WakeEvent.onTimeWindow].
  Future<void> recordMissionDismissed(String eventId, {required DateTime dismissedAt});

  Future<void> incrementSnooze(String eventId);

  Future<void> markRoutineCompleted(String eventId);

  Future<void> markPhotoPosted(String eventId);

  /// Most recent events, newest first.
  Future<List<WakeEvent>> getRecent({int limit = 90});

  Future<List<WakeEvent>> getAll();
}
