import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed accessors for values loaded from the `.env` file.
///
/// Never hardcode secrets here — put them in `.env` (git-ignored) and copy
/// `.env.example` as a template.
class Env {
  Env._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// True when both Supabase credentials are present.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
