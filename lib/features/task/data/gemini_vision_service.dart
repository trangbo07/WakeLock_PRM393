import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/utils/logger.dart';

/// Verifies a captured photo really contains the target object, using the
/// Gemini vision API. Fails OPEN: if the key is missing or the request errors,
/// the photo is accepted so a network hiccup can't trap the user at 6 AM.
class GeminiVisionService {
  GeminiVisionService({required this.apiKey, this.model = _defaultModel});

  /// User-specified model. Change here if the API rejects the id.
  static const String _defaultModel = 'gemini-3.1-flash-lite';

  final String apiKey;
  final String model;

  bool get isConfigured => apiKey.isNotEmpty;

  Uri get _endpoint => Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '$model:generateContent?key=$apiKey',
      );

  /// True if [imageBytes] (a JPEG) appears to contain [label]. Returns true
  /// (accept) when unconfigured or on any error.
  Future<bool> matchesLabel(Uint8List imageBytes, String label) async {
    if (!isConfigured) {
      AppLogger.w('Gemini not configured — accepting photo without check');
      return true;
    }
    try {
      final prompt =
          'Bạn là bộ kiểm tra báo thức. Trong bức ảnh này có "$label" '
          'rõ ràng không? Chỉ trả lời đúng một từ: YES hoặc NO.';
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Encode(imageBytes),
                }
              },
            ],
          },
        ],
        'generationConfig': {'temperature': 0, 'maxOutputTokens': 5},
      });

      final res = await http
          .post(_endpoint,
              headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        AppLogger.w('Gemini HTTP ${res.statusCode}: ${res.body}');
        return true; // fail open
      }
      final text = _extractText(res.body).toLowerCase();
      AppLogger.i('Gemini verdict for "$label": $text');
      return text.contains('yes');
    } catch (e) {
      AppLogger.w('Gemini request failed: $e');
      return true; // fail open
    }
  }

  static String _extractText(String responseBody) {
    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return '';
    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null || parts.isEmpty) return '';
    return (parts.first['text'] as String?) ?? '';
  }
}
