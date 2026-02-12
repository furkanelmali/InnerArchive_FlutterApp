import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/enums/anime_format.dart';
import '../models/discovery_media_model.dart';

class DiscoveryRepository {
  final http.Client _http;

  DiscoveryRepository({http.Client? client}) : _http = client ?? http.Client();

  // ───────────────────── GENRES ─────────────────────

  Future<List<Genre>> movieGenres() async {
    final uri = Uri.parse(
      '${ApiConfig.tmdbBaseUrl}/genre/movie/list?api_key=${ApiConfig.tmdbApiKey}',
    );
    return _parseGenres(await _get(uri));
  }

  Future<List<Genre>> tvGenres() async {
    final uri = Uri.parse(
      '${ApiConfig.tmdbBaseUrl}/genre/tv/list?api_key=${ApiConfig.tmdbApiKey}',
    );
    return _parseGenres(await _get(uri));
  }

  Future<List<Genre>> animeGenres() async {
    final uri = Uri.parse('${ApiConfig.jikanBaseUrl}/genres/anime');
    final json = await _get(uri);
    if (json == null) return [];
    final data = json['data'] as List<dynamic>? ?? [];
    return data
        .map((g) => Genre(
              id: '${g['mal_id']}',
              name: g['name'] as String? ?? '',
            ))
        .take(20)
        .toList();
  }

  Future<List<Genre>> gameGenres() async {
    final uri = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/genres?key=${ApiConfig.rawgApiKey}',
    );
    final json = await _get(uri);
    if (json == null) return [];
    final results = json['results'] as List<dynamic>? ?? [];
    return results
        .map((g) => Genre(
              id: '${g['id']}',
              name: g['name'] as String? ?? '',
            ))
        .toList();
  }

  List<Genre> _parseGenres(Map<String, dynamic>? json) {
    if (json == null) return [];
    final list = json['genres'] as List<dynamic>? ?? [];
    return list
        .map((g) => Genre(id: '${g['id']}', name: g['name'] as String? ?? ''))
        .toList();
  }

  // ───────────────────── FILTERED DISCOVERY ─────────────────────

  Future<List<DiscoveryMedia>> discoverMovies({
    int page = 1,
    String? genreId,
  }) async {
    var url = '${ApiConfig.tmdbBaseUrl}/discover/movie'
        '?api_key=${ApiConfig.tmdbApiKey}&sort_by=popularity.desc&page=$page';
    if (genreId != null) url += '&with_genres=$genreId';
    return _parseTmdbFiltered(await _get(Uri.parse(url)), MediaType.movie);
  }

  Future<List<DiscoveryMedia>> discoverTv({
    int page = 1,
    String? genreId,
  }) async {
    var url = '${ApiConfig.tmdbBaseUrl}/discover/tv'
        '?api_key=${ApiConfig.tmdbApiKey}&sort_by=popularity.desc&page=$page';
    if (genreId != null) url += '&with_genres=$genreId';
    return _parseTmdbFiltered(await _get(Uri.parse(url)), MediaType.tv);
  }

  Future<List<DiscoveryMedia>> discoverAnime({
    int page = 1,
    String? genreId,
  }) async {
    var url = '${ApiConfig.jikanBaseUrl}/anime?order_by=popularity&sort=asc&page=$page&limit=20';
    if (genreId != null) url += '&genres=$genreId';
    final json = await _get(Uri.parse(url));
    if (json == null) return [];
    final data = json['data'] as List<dynamic>? ?? [];
    return data.map((r) => _jikanToDiscovery(r as Map<String, dynamic>)).toList();
  }

  Future<List<DiscoveryMedia>> discoverGames({
    int page = 1,
    String? genreId,
  }) async {
    var url = '${ApiConfig.rawgBaseUrl}/games'
        '?key=${ApiConfig.rawgApiKey}&ordering=-rating&page=$page&page_size=20';
    if (genreId != null) url += '&genres=$genreId';
    final json = await _get(Uri.parse(url));
    if (json == null) return [];
    final results = json['results'] as List<dynamic>? ?? [];
    return results.map((r) => _rawgToDiscovery(r as Map<String, dynamic>)).toList();
  }

  // ───────────────────── TMDB ─────────────────────

  Future<List<DiscoveryMedia>> trendingMovies({int page = 1}) async {
    final uri = Uri.parse(
      '${ApiConfig.tmdbBaseUrl}/trending/movie/week'
      '?api_key=${ApiConfig.tmdbApiKey}&page=$page',
    );
    return _parseTmdbFiltered(await _get(uri), MediaType.movie);
  }

  Future<List<DiscoveryMedia>> trendingTv({int page = 1}) async {
    final uri = Uri.parse(
      '${ApiConfig.tmdbBaseUrl}/trending/tv/week'
      '?api_key=${ApiConfig.tmdbApiKey}&page=$page',
    );
    return _parseTmdbFiltered(await _get(uri), MediaType.tv);
  }

  Future<DiscoveryMedia?> tmdbDetail(String id, MediaType type) async {
    final path = type == MediaType.movie ? 'movie' : 'tv';
    final uri = Uri.parse(
      '${ApiConfig.tmdbBaseUrl}/$path/$id'
      '?api_key=${ApiConfig.tmdbApiKey}&append_to_response=credits',
    );
    final json = await _get(uri);
    if (json == null) return null;
    return _tmdbToDiscovery(json, type);
  }

  Future<List<DiscoveryMedia>> tmdbSimilar(String id, MediaType type) async {
    final path = type == MediaType.movie ? 'movie' : 'tv';
    final uri = Uri.parse(
      '${ApiConfig.tmdbBaseUrl}/$path/$id/similar'
      '?api_key=${ApiConfig.tmdbApiKey}&page=1',
    );
    return _parseTmdbFiltered(await _get(uri), type);
  }

  // ───────────────────── TMDB ANIME EXCLUSION ─────────────────────

  /// Animation genre ID in TMDB = 16.
  static const _tmdbAnimationGenreId = 16;

  /// Detect if a TMDB result is actually Japanese anime content.
  /// Excluded from movie/TV sections to prevent mixing.
  bool _isAnimeContent(Map<String, dynamic> r) {
    final genreIds = (r['genre_ids'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toSet() ??
        <int>{};
    // Also check expanded genres array (detail responses)
    final genres = (r['genres'] as List<dynamic>?)
            ?.map((g) => g['id'] as int)
            .toSet() ??
        <int>{};
    final allGenres = genreIds.union(genres);

    if (!allGenres.contains(_tmdbAnimationGenreId)) return false;

    // Check original language
    final origLang = r['original_language'] as String? ?? '';
    if (origLang == 'ja') return true;

    // Check origin countries (TV shows)
    final countries = (r['origin_country'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toSet() ??
        <String>{};
    if (countries.contains('JP')) return true;

    return false;
  }

  /// Parse TMDB results with anime exclusion filter.
  List<DiscoveryMedia> _parseTmdbFiltered(
      Map<String, dynamic>? json, MediaType type) {
    if (json == null) return [];
    final results = json['results'] as List<dynamic>? ?? [];
    return results
        .where((r) => !_isAnimeContent(r as Map<String, dynamic>))
        .map((r) => _tmdbToDiscovery(r as Map<String, dynamic>, type))
        .toList();
  }

  DiscoveryMedia _tmdbToDiscovery(Map<String, dynamic> r, MediaType type) {
    final title = (r['title'] ?? r['name'] ?? '') as String;
    final dateStr =
        (r['release_date'] ?? r['first_air_date'] ?? '') as String;
    final genres = (r['genres'] as List<dynamic>?)
            ?.map((g) => g['name'] as String)
            .toList() ??
        (r['genre_ids'] as List<dynamic>?)
            ?.map((id) => 'Genre $id')
            .toList() ??
        [];

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
      genres: genres,
      type: type,
      source: 'tmdb',
      runtime: r['runtime'] as int?,
      episodeCount: r['number_of_episodes'] as int?,
      seasonCount: r['number_of_seasons'] as int?,
      studio: (r['production_companies'] as List<dynamic>?)
              ?.map((c) => c['name'] as String)
              .firstOrNull ??
          (r['networks'] as List<dynamic>?)
              ?.map((c) => c['name'] as String)
              .firstOrNull,
    );
  }

  // ───────────────────── JIKAN ─────────────────────

  Future<List<DiscoveryMedia>> popularAnime({int page = 1}) async {
    final uri = Uri.parse(
      '${ApiConfig.jikanBaseUrl}/top/anime?page=$page&limit=20',
    );
    final json = await _get(uri);
    if (json == null) return [];
    final data = json['data'] as List<dynamic>? ?? [];
    return data
        .map((r) => _jikanToDiscovery(r as Map<String, dynamic>))
        .toList();
  }

  Future<DiscoveryMedia?> animeDetail(String id) async {
    final uri = Uri.parse('${ApiConfig.jikanBaseUrl}/anime/$id/full');
    final json = await _get(uri);
    if (json == null) return null;
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) return null;
    return _jikanToDiscovery(data);
  }

  Future<List<DiscoveryMedia>> animeSimilar(String id) async {
    final uri = Uri.parse(
        '${ApiConfig.jikanBaseUrl}/anime/$id/recommendations');
    final json = await _get(uri);
    if (json == null) return [];
    final data = json['data'] as List<dynamic>? ?? [];
    return data.take(10).map((r) {
      final entry = r['entry'] as Map<String, dynamic>;
      return DiscoveryMedia(
        externalId: '${entry['mal_id']}',
        title: entry['title'] as String? ?? '',
        posterUrl: (entry['images'] as Map<String, dynamic>?)?['jpg']
            ?['large_image_url'] as String?,
        type: MediaType.anime,
        source: 'jikan',
      );
    }).toList();
  }

  DiscoveryMedia _jikanToDiscovery(Map<String, dynamic> r) {
    final images = r['images'] as Map<String, dynamic>?;
    final jpg = images?['jpg'] as Map<String, dynamic>?;
    final aired = r['aired'] as Map<String, dynamic>?;
    final fromDate = aired?['from'] as String?;

    final genres = <String>[
      ...(r['genres'] as List<dynamic>? ?? [])
          .map((g) => g['name'] as String),
      ...(r['themes'] as List<dynamic>? ?? [])
          .map((g) => g['name'] as String),
    ];

    final studios = (r['studios'] as List<dynamic>? ?? [])
        .map((s) => s['name'] as String)
        .toList();

    final jikanType = r['type'] as String?;
    final animeFormat = AnimeFormat.fromJikan(jikanType);

    return DiscoveryMedia(
      externalId: '${r['mal_id']}',
      title: r['title'] as String? ?? '',
      overview: r['synopsis'] as String?,
      posterUrl: jpg?['large_image_url'] as String?,
      apiRating: (r['score'] as num?)?.toDouble(),
      releaseDate: fromDate != null ? DateTime.tryParse(fromDate) : null,
      genres: genres,
      type: MediaType.anime,
      source: 'jikan',
      animeFormat: animeFormat,
      episodeCount: r['episodes'] as int?,
      status: r['status'] as String?,
      studio: studios.firstOrNull,
    );
  }

  // ───────────────────── OPENLIBRARY ─────────────────────

  Future<List<DiscoveryMedia>> popularBooks({int page = 1}) async {
    final offset = (page - 1) * 20;
    final uri = Uri.parse(
      '${ApiConfig.openLibraryBaseUrl}/search.json'
      '?q=subject:fiction&sort=rating&limit=20&offset=$offset',
    );
    final json = await _get(uri);
    if (json == null) return [];
    final docs = json['docs'] as List<dynamic>? ?? [];
    return docs.map((r) {
      final doc = r as Map<String, dynamic>;
      final coverId = doc['cover_i'] as int?;
      final authors =
          (doc['author_name'] as List<dynamic>?)?.cast<String>() ?? [];
      final publishYear = doc['first_publish_year'] as int?;

      return DiscoveryMedia(
        externalId: doc['key'] as String? ?? '',
        title: doc['title'] as String? ?? '',
        posterUrl: coverId != null
            ? '${ApiConfig.openLibraryCoverBase}/$coverId-L.jpg'
            : null,
        author: authors.firstOrNull,
        releaseDate:
            publishYear != null ? DateTime(publishYear) : null,
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

  // ───────────────────── RAWG ─────────────────────

  Future<List<DiscoveryMedia>> popularGames({int page = 1}) async {
    final uri = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games'
      '?key=${ApiConfig.rawgApiKey}&ordering=-rating&page=$page&page_size=20',
    );
    final json = await _get(uri);
    if (json == null) return [];
    final results = json['results'] as List<dynamic>? ?? [];
    return results
        .map((r) => _rawgToDiscovery(r as Map<String, dynamic>))
        .toList();
  }

  Future<DiscoveryMedia?> gameDetail(String id) async {
    final uri = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games/$id?key=${ApiConfig.rawgApiKey}',
    );
    final json = await _get(uri);
    if (json == null) return null;
    return _rawgToDiscovery(json);
  }

  Future<List<DiscoveryMedia>> gameSimilar(String id) async {
    final uri = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games/$id/suggested'
      '?key=${ApiConfig.rawgApiKey}&page_size=10',
    );
    final json = await _get(uri);
    if (json == null) return [];
    final results = json['results'] as List<dynamic>? ?? [];
    return results
        .map((r) => _rawgToDiscovery(r as Map<String, dynamic>))
        .toList();
  }

  DiscoveryMedia _rawgToDiscovery(Map<String, dynamic> r) {
    final genres = (r['genres'] as List<dynamic>?)
            ?.map((g) => g['name'] as String)
            .toList() ??
        [];
    final released = r['released'] as String?;
    final devs = (r['developers'] as List<dynamic>? ?? [])
        .map((d) => d['name'] as String)
        .toList();
    final pubs = (r['publishers'] as List<dynamic>? ?? [])
        .map((p) => p['name'] as String)
        .toList();

    return DiscoveryMedia(
      externalId: '${r['id']}',
      title: r['name'] as String? ?? '',
      overview: r['description_raw'] as String?,
      posterUrl: r['background_image'] as String?,
      apiRating: (r['rating'] as num?)?.toDouble(),
      releaseDate: released != null ? DateTime.tryParse(released) : null,
      genres: genres,
      type: MediaType.game,
      source: 'rawg',
      studio: devs.firstOrNull ?? pubs.firstOrNull,
    );
  }

  // ───────────────────── HTTP ─────────────────────

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
