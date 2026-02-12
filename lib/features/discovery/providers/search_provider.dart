import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/media_type.dart';
import '../models/discovery_media_model.dart';
import '../repository/search_repository.dart';
import '../providers/discovery_provider.dart';

final searchRepoProvider =
    Provider<SearchRepository>((ref) => SearchRepository());

/// Current search query — managed by Notifier.
final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Grouped search results keyed by MediaType.
final searchResultsProvider =
    FutureProvider<Map<MediaType, List<DiscoveryMedia>>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return {};
  return ref.read(searchRepoProvider).searchAll(query);
});

/// Full search for a single type (paginated).
final typedSearchProvider = FutureProvider.family<
    List<DiscoveryMedia>,
    ({String query, String typeName, int page})>((ref, key) async {
  final repo = ref.read(searchRepoProvider);
  switch (key.typeName) {
    case 'movie':
      return repo.searchMovies(key.query, page: key.page);
    case 'tv':
      return repo.searchTv(key.query, page: key.page);
    case 'anime':
      return repo.searchAnime(key.query, page: key.page);
    case 'book':
      return repo.searchBooks(key.query, page: key.page);
    case 'game':
      return repo.searchGames(key.query, page: key.page);
    default:
      return [];
  }
});
