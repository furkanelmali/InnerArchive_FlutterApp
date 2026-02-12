import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/enums/anime_format.dart';
import '../models/discovery_media_model.dart';

class SearchRepository {
  final http.Client _http;

  SearchRepository({http.Client? client}) : _http = client ?? http.Client();

  /// Aggregate search: top 5 per type.
  Future<Map<MediaType, List<DiscoveryMedia>>> searchAll(String query) async {
    if (query.trim().isEmpty) return {};

    final results = await Future.wait([
      searchMovies(query),
      searchTv(query),
      searchAnime(query),
      searchBooks(query),
      searchGames(query),
    ]);

    final map = <MediaType, List<DiscoveryMedia>>{};
    if (results[0].isNotEmpty) map[MediaType.movie] = results[0].take(5).toList();
    if (results[1].isNotEmpty) map[MediaType.tv] = results[1].take(5).toList();
    if (results[2].isNotEmpty) map[MediaType.anime] = results[2].take(5).toList();
    if (results[3].isNotEmpty) map[MediaType.book] = results[3].take(5).toList();
    if (results[4].isNotEmpty) map[MediaType.game] = results[4].take(5).toList();
    return map;
  }

  // ──── TMDB Movies ────

  Future<List<DiscoveryMedia>> searchMovies(String query, {int page = 1}) async {
    final uri = Uri.parse(
      '${ApiConfig.tmdbBaseUrl}/search/movie'
      '?api_key=${ApiConfig.tmdbApiKey}&query=${Uri.encodeComponent(query)}&page=$page',
    );
    return _parseTmdb(await _get(uri), MediaType.movie);
  }

  // ──── TMDB TV ────

  Future<List<DiscoveryMedia>> searchTv(String query, {int page = 1}) async {
    final uri = Uri.parse(
      '${ApiConfig.tmdbBaseUrl}/search/tv'
      '?api_key=${ApiConfig.tmdbApiKey}&query=${Uri.encodeComponent(query)}&page=$page',
    );
    return _parseTmdb(await _get(uri), MediaType.tv);
  }

  // ──── Jikan Anime ────

  Future<List<DiscoveryMedia>> searchAnime(String query, {int page = 1}) async {
    final uri = Uri.parse(
      '${ApiConfig.jikanBaseUrl}/anime?q=${Uri.encodeComponent(query)}&page=$page&limit=20',
    );
    final json = await _get(uri);
    if (json == null) return [];
    final data = json['data'] as List<dynamic>? ?? [];
    return data.map((r) => _jikanToDiscovery(r as Map<String, dynamic>)).toList();
  }

  // ──── OpenLibrary Books ────

  Future<List<DiscoveryMedia>> searchBooks(String query, {int page = 1}) async {
    final offset = (page - 1) * 20;
    final uri = Uri.parse(
      '${ApiConfig.openLibraryBaseUrl}/search.json'
      '?q=${Uri.encodeComponent(query)}&limit=20&offset=$offset',
    );
    final json = await _get(uri);
    if (json == null) return [];
    final docs = json['docs'] as List<dynamic>? ?? [];
    return docs.map((r) {
      final doc = r as Map<String, dynamic>;
      final coverId = doc['cover_i'] as int?;
      final authors = (doc['author_name'] as List<dynamic>?)?.cast<String>() ?? [];
      final publishYear = doc['first_publish_year'] as int?;

      return DiscoveryMedia(
        externalId: doc['key'] as String? ?? '',
        title: doc['title'] as String? ?? '',
        posterUrl: coverId != null
            ? '${ApiConfig.openLibraryCoverBase}/$coverId-L.jpg'
            : null,
        author: authors.firstOrNull,
        releaseDate: publishYear != null ? DateTime(publishYear) : null,
        genres: (doc['subject'] as List<dynamic>?)
                ?.take(3)
                .cast<String>()
                .toList() ??
            [],
        type: MediaType.book,
        source: 'openlibrary',
        apiRating: (doc['ratings_average'] as num?)?.toDouble(),
      );
    }).toList();
  }

  // ──── RAWG Games ────

  Future<List<DiscoveryMedia>> searchGames(String query, {int page = 1}) async {
    final uri = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games'
      '?key=${ApiConfig.rawgApiKey}&search=${Uri.encodeComponent(query)}&page=$page&page_size=20',
    );
    final json = await _get(uri);
    if (json == null) return [];
    final results = json['results'] as List<dynamic>? ?? [];
    return results.map((r) => _rawgToDiscovery(r as Map<String, dynamic>)).toList();
  }

  /// Search a single title (used to resolve titles to real media).
  Future<DiscoveryMedia?> findByTitle(String title) async {
    final movie = await searchMovies(title);
    if (movie.isNotEmpty) return movie.first;

    final tv = await searchTv(title);
    if (tv.isNotEmpty) return tv.first;

    final anime = await searchAnime(title);
    if (anime.isNotEmpty) return anime.first;

    final game = await searchGames(title);
    if (game.isNotEmpty) return game.first;

    return null;
  }

  // ──── Parsers ────

  List<DiscoveryMedia> _parseTmdb(Map<String, dynamic>? json, MediaType type) {
    if (json == null) return [];
    final results = json['results'] as List<dynamic>? ?? [];
    return results
        .map((r) => _tmdbToDiscovery(r as Map<String, dynamic>, type))
        .toList();
  }

  DiscoveryMedia _tmdbToDiscovery(Map<String, dynamic> r, MediaType type) {
    final title = (r['title'] ?? r['name'] ?? '') as String;
    final dateStr = (r['release_date'] ?? r['first_air_date'] ?? '') as String;

    return DiscoveryMedia(
      externalId: '${r['id']}',
      title: title,
      overview: r['overview'] as String?,
      posterUrl: r['poster_path'] != null
          ? '${ApiConfig.tmdbImageBase}${r['poster_path']}'
          : null,
      backdropUrl: r['backdrop_path'] != null
          ? 'https://image.tmdb.org/t/p/w780${r['backdrop_path']}'
          : null,
      apiRating: (r['vote_average'] as num?)?.toDouble(),
      releaseDate: dateStr.isNotEmpty ? DateTime.tryParse(dateStr) : null,
      genres: (r['genre_ids'] as List<dynamic>?)
              ?.map((id) => '$id')
              .toList() ??
          [],
      type: type,
      source: 'tmdb',
    );
  }

  DiscoveryMedia _jikanToDiscovery(Map<String, dynamic> r) {
    final images = r['images'] as Map<String, dynamic>?;
    final jpg = images?['jpg'] as Map<String, dynamic>?;
    final aired = r['aired'] as Map<String, dynamic>?;
    final fromDate = aired?['from'] as String?;

    final jikanType = r['type'] as String?;
    final animeFormat = AnimeFormat.fromJikan(jikanType);

    return DiscoveryMedia(
      externalId: '${r['mal_id']}',
      title: r['title'] as String? ?? '',
      overview: r['synopsis'] as String?,
      posterUrl: jpg?['large_image_url'] as String?,
      apiRating: (r['score'] as num?)?.toDouble(),
      releaseDate: fromDate != null ? DateTime.tryParse(fromDate) : null,
      genres: (r['genres'] as List<dynamic>? ?? [])
          .map((g) => g['name'] as String)
          .toList(),
      type: MediaType.anime,
      source: 'jikan',
      animeFormat: animeFormat,
      episodeCount: r['episodes'] as int?,
      status: r['status'] as String?,
    );
  }

  DiscoveryMedia _rawgToDiscovery(Map<String, dynamic> r) {
    final released = r['released'] as String?;
    return DiscoveryMedia(
      externalId: '${r['id']}',
      title: r['name'] as String? ?? '',
      overview: r['description_raw'] as String?,
      posterUrl: r['background_image'] as String?,
      apiRating: (r['rating'] as num?)?.toDouble(),
      releaseDate: released != null ? DateTime.tryParse(released) : null,
      genres: (r['genres'] as List<dynamic>?)
              ?.map((g) => g['name'] as String)
              .toList() ??
          [],
      type: MediaType.game,
      source: 'rawg',
    );
  }

  Future<Map<String, dynamic>?> _get(Uri uri) async {
    try {
      final resp = await _http.get(uri);
      if (resp.statusCode != 200) return null;
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
