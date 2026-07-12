import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../data/gemini_vision_service.dart';

/// Gemini vision service for the photo dismiss task (key from `.env`).
final geminiVisionServiceProvider = Provider<GeminiVisionService>((ref) {
  return GeminiVisionService(apiKey: Env.geminiApiKey);
});
