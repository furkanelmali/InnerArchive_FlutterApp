import '../../../core/enums/media_type.dart';
import '../models/media_item.dart';
import 'tmdb_service.dart';
import 'jikan_service.dart';
import 'openlibrary_service.dart';
import 'rawg_service.dart';

class MediaSearchService {
  final _tmdb = TmdbService();
  final _jikan = JikanService();
  final _openLibrary = OpenLibraryService();
  final _rawg = RawgService();

  Future<List<MediaItem>> search(String query, MediaType type) async {
    switch (type) {
      case MediaType.movie:
        return _tmdb.searchMovies(query);
      case MediaType.tv:
        return _tmdb.searchTv(query);
      case MediaType.anime:
        return _jikan.searchAnime(query);
      case MediaType.book:
        return _openLibrary.searchBooks(query);
      case MediaType.game:
        return _rawg.searchGames(query);
    }
  }
}
