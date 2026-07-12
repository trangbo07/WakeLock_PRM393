import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed accessors for values loaded from the git-ignored `.env` file.
///
/// Only holds the Gemini API key used by the photo dismiss task. Never hardcode
/// the key here — put it in `.env` (see `.env.example`).
class Env {
  Env._();

  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static bool get hasGemini => geminiApiKey.isNotEmpty;
}
