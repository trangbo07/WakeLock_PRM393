import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'utils/logger.dart';

/// One-shot application initialization run before `runApp`.
///
/// Ordering matters:
///   1. Flutter bindings
///   2. `.env` (Supabase credentials) — see `.env.example`
///   3. Supabase client
///   4. (later) alarm manager + notifications + foreground service
///
/// Backend/scheduler init is wrapped defensively so the UI can still boot
/// during development even when `.env` or Supabase is not configured yet.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    AppLogger.w('.env not found — using empty Supabase config');
  }

  if (Env.isConfigured) {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        // supabase_flutter 2.16+ renamed anonKey -> publishableKey. The value
        // is still the project's public API key (anon / sb_publishable_...).
        publishableKey: Env.supabaseAnonKey,
      );
      AppLogger.i('Supabase initialized');
    } catch (e) {
      AppLogger.e('Supabase init failed: $e');
    }
  } else {
    AppLogger.w('Supabase credentials missing — running in offline/UI mode');
  }

  // TODO: AndroidAlarmManager.initialize() (see core/platform/alarm_scheduler.dart)
  // TODO: init flutter_local_notifications channels (core/constants/notification_channels.dart)
  // TODO: ForegroundServiceController().init() (core/platform/foreground_service.dart)

  AppLogger.i('Bootstrap complete');
}
