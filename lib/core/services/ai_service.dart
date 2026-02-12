import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../features/profile/models/taste_summary_model.dart';

class AiService {
  Future<List<String>> getRecommendations({
    required List<String> topRatedTitles,
    required String mostConsumedType,
  }) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY') return [];

    final prompt = '''
You are a media recommendation engine.
The user's most watched type is: $mostConsumedType.
Their top-rated items are: ${topRatedTitles.join(', ')}.

Suggest 5 new titles they might enjoy. 
Return ONLY a JSON array of strings, no explanation.
Example: ["Title 1", "Title 2", "Title 3", "Title 4", "Title 5"]
''';

    try {
      final result = await callGemini(prompt);
      if (result == null) return [];

      final cleaned = result
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final list = jsonDecode(cleaned) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<TasteSummary?> getTasteSummary({
    required List<String> topRatedTitles,
    required String mostConsumedType,
    required double averageRating,
    required List<String> recentCompletedTitles,
    required Map<String, int> typeBreakdown,
  }) async {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY') return null;

    final prompt = '''
You are a media taste analyst. Analyze this user's media consumption and return a JSON object.

Data:
- Most consumed type: $mostConsumedType
- Top rated items: ${topRatedTitles.join(', ')}
- Average rating: ${averageRating.toStringAsFixed(1)}/10
- Recently completed: ${recentCompletedTitles.join(', ')}
- Type breakdown: ${typeBreakdown.entries.map((e) => '${e.key}: ${e.value}').join(', ')}

Return ONLY this JSON format, no explanation:
{
  "summary": "A 2-3 sentence personality-driven taste analysis. Be specific and insightful.",
  "topGenres": ["genre1", "genre2", "genre3"],
  "suggestedFocus": "One sentence suggesting what to explore next."
}
''';

    try {
      final result = await callGemini(prompt);
      if (result == null) return null;

      final cleaned = result
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      json['generatedAt'] = DateTime.now().toIso8601String();
      return TasteSummary.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<String?> callGemini(String prompt) async {
    final uri = Uri.parse(
      '${ApiConfig.geminiBaseUrl}/models/gemini-2.0-flash:generateContent'
      '?key=${ApiConfig.geminiApiKey}',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 512,
        },
      }),
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    return data['candidates']?[0]?['content']?['parts']?[0]?['text']
        as String?;
  }
}
