import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/enums/media_status.dart';
import '../models/media_item.dart';

class RawgService {
  Future<List<MediaItem>> searchGames(String query) async {
    final uri = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games'
      '?key=${ApiConfig.rawgApiKey}'
      '&search=${Uri.encodeComponent(query)}&page_size=20',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final results = data['results'] as List<dynamic>? ?? [];
    final now = DateTime.now();

    return results.map((item) {
      final released = item['released'] as String?;

      return MediaItem(
        id: '${now.millisecondsSinceEpoch}_${item['id']}',
        externalId: item['id'].toString(),
        title: item['name'] as String? ?? '',
        description: null,
        imageUrl: item['background_image'] as String?,
        releaseDate:
            released != null ? DateTime.tryParse(released) : null,
        type: MediaType.game,
        status: MediaStatus.watchlist,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }
}
