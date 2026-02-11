import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/enums/media_status.dart';
import '../models/media_item.dart';

class JikanService {
  Future<List<MediaItem>> searchAnime(String query) async {
    final uri = Uri.parse(
      '${ApiConfig.jikanBaseUrl}/anime'
      '?q=${Uri.encodeComponent(query)}&limit=20',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final results = data['data'] as List<dynamic>? ?? [];
    final now = DateTime.now();

    return results.map((item) {
      final images = item['images'] as Map<String, dynamic>?;
      final jpg = images?['jpg'] as Map<String, dynamic>?;
      final imageUrl = jpg?['large_image_url'] as String? ??
          jpg?['image_url'] as String?;

      final airedFrom = item['aired']?['from'] as String?;

      return MediaItem(
        id: '${now.millisecondsSinceEpoch}_${item['mal_id']}',
        externalId: item['mal_id'].toString(),
        title: item['title'] as String? ?? '',
        description: item['synopsis'] as String?,
        imageUrl: imageUrl,
        releaseDate: airedFrom != null ? DateTime.tryParse(airedFrom) : null,
        type: MediaType.anime,
        status: MediaStatus.watchlist,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }
}
