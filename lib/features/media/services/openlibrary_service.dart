import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/enums/media_status.dart';
import '../models/media_item.dart';

class OpenLibraryService {
  Future<List<MediaItem>> searchBooks(String query) async {
    final uri = Uri.parse(
      '${ApiConfig.openLibraryBaseUrl}/search.json'
      '?q=${Uri.encodeComponent(query)}&limit=20',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final docs = data['docs'] as List<dynamic>? ?? [];
    final now = DateTime.now();

    return docs.map((item) {
      final coverId = item['cover_i'];
      final year = item['first_publish_year'] as int?;

      return MediaItem(
        id: '${now.millisecondsSinceEpoch}_${item['key']}',
        externalId: item['key'] as String?,
        title: item['title'] as String? ?? '',
        description: item['first_sentence'] is List
            ? (item['first_sentence'] as List).firstOrNull as String?
            : item['first_sentence'] as String?,
        imageUrl: coverId != null
            ? '${ApiConfig.openLibraryCoverBase}/$coverId-L.jpg'
            : null,
        releaseDate: year != null ? DateTime(year) : null,
        type: MediaType.book,
        status: MediaStatus.watchlist,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }
}
