import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

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
            'maxOutputTokens': 256,
          },
        }),
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
          as String?;

      if (text == null) return [];

      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final list = jsonDecode(cleaned) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }
}
