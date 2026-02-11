import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/enums/media_status.dart';
import '../models/media_item.dart';

class TmdbService {
  Future<List<MediaItem>> searchMovies(String query) async {
    return _search(query, 'movie', MediaType.movie);
  }

  Future<List<MediaItem>> searchTv(String query) async {
    return _search(query, 'tv', MediaType.tv);
  }

  Future<List<MediaItem>> _search(
    String query,
    String endpoint,
    MediaType type,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.tmdbBaseUrl}/search/$endpoint'
      '?api_key=${ApiConfig.tmdbApiKey}'
      '&query=${Uri.encodeComponent(query)}',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final results = data['results'] as List<dynamic>? ?? [];
    final now = DateTime.now();

    return results.take(20).map((item) {
      final posterPath = item['poster_path'] as String?;
      final dateStr = type == MediaType.movie
          ? item['release_date'] as String?
          : item['first_air_date'] as String?;

      return MediaItem(
        id: '${now.millisecondsSinceEpoch}_${item['id']}',
        externalId: item['id'].toString(),
        title: (type == MediaType.movie
                ? item['title']
                : item['name']) as String? ??
            '',
        description: item['overview'] as String?,
        imageUrl: posterPath != null
            ? '${ApiConfig.tmdbImageBase}$posterPath'
            : null,
        releaseDate: dateStr != null && dateStr.isNotEmpty
            ? DateTime.tryParse(dateStr)
            : null,
        type: type,
        status: MediaStatus.watchlist,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }
}
