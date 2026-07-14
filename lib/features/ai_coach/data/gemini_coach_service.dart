import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../../core/utils/logger.dart';

/// Text-only Gemini coach tip generator. Same REST pattern as
/// `task/data/gemini_vision_service.dart` (same `.env` key, same model
/// endpoint), but sends a stats summary instead of an image.
///
/// Fails OPEN with a static Vietnamese tip: a network hiccup or missing key
/// must never show an error on this screen, just a slightly less personalized
/// suggestion.
class GeminiCoachService {
  GeminiCoachService({required this.apiKey, this.model = _defaultModel});

  static const String _defaultModel = 'gemini-3.1-flash-lite';

  final String apiKey;
  final String model;

  bool get isConfigured => apiKey.isNotEmpty;

  Uri get _endpoint => Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '$model:generateContent?key=$apiKey',
      );

  static const List<String> _fallbackTips = [
    'Hãy thử ngủ sớm hơn 30 phút để dậy dễ hơn vào sáng mai.',
    'Đặt báo thức xa giường để buộc bản thân phải đứng dậy tắt nó.',
    'Uống một cốc nước ngay khi thức dậy để tỉnh táo nhanh hơn.',
    'Hoàn thành nhiệm vụ trong 10 phút đầu để giữ streak không bị mất.',
    'Thử thêm một routine buổi sáng ngắn để bắt đầu ngày mới tốt hơn.',
    'Đi ngủ và thức dậy cùng một giờ mỗi ngày giúp đồng hồ sinh học ổn định hơn.',
  ];

  /// [statsSummary] is a short plain-text description of the user's recent
  /// wake/habit numbers (see `ai_coach_providers.dart`).
  Future<String> getTip(String statsSummary) async {
    if (!isConfigured) {
      AppLogger.w('Gemini not configured — using a static coach tip');
      return _randomFallback();
    }
    try {
      final prompt = 'Bạn là AI Coach của app báo thức WakeLock. Dựa trên số liệu '
          'thức dậy sau đây của người dùng, hãy đưa ra một nhận xét ngắn gọn kèm '
          '1 gợi ý cải thiện, bằng tiếng Việt, giọng thân thiện, tối đa 2 câu và '
          'dưới 40 từ. Không dùng markdown.\n\nSố liệu: $statsSummary';
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 120},
      });

      final res = await http
          .post(_endpoint, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        AppLogger.w('Gemini coach HTTP ${res.statusCode}: ${res.body}');
        return _randomFallback();
      }
      final text = _extractText(res.body).trim();
      return text.isEmpty ? _randomFallback() : text;
    } catch (e) {
      AppLogger.w('Gemini coach request failed: $e');
      return _randomFallback();
    }
  }

  String _randomFallback() => _fallbackTips[Random().nextInt(_fallbackTips.length)];

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
