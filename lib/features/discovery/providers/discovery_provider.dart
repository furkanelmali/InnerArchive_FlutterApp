import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/media_type.dart';
import '../models/discovery_media_model.dart';
import '../repository/discovery_repository.dart';

final discoveryRepoProvider =
    Provider<DiscoveryRepository>((ref) => DiscoveryRepository());

// ─────────────────────────────────────────────────
// Genre providers (cached via FutureProvider)
// ─────────────────────────────────────────────────

final movieGenresProvider = FutureProvider<List<Genre>>((ref) {
  return ref.read(discoveryRepoProvider).movieGenres();
});

final tvGenresProvider = FutureProvider<List<Genre>>((ref) {
  return ref.read(discoveryRepoProvider).tvGenres();
});

final animeGenresProvider = FutureProvider<List<Genre>>((ref) {
  return ref.read(discoveryRepoProvider).animeGenres();
});

final gameGenresProvider = FutureProvider<List<Genre>>((ref) {
  return ref.read(discoveryRepoProvider).gameGenres();
});

// ─────────────────────────────────────────────────
// Selected genre per section (Notifier-based)
// ─────────────────────────────────────────────────

class GenreNotifier extends Notifier<Genre?> {
  @override
  Genre? build() => null;
  void select(Genre? genre) => state = genre;
}

final selectedMovieGenreProvider =
    NotifierProvider<GenreNotifier, Genre?>(GenreNotifier.new);
final selectedTvGenreProvider =
    NotifierProvider<GenreNotifier, Genre?>(GenreNotifier.new);
final selectedAnimeGenreProvider =
    NotifierProvider<GenreNotifier, Genre?>(GenreNotifier.new);
final selectedGameGenreProvider =
    NotifierProvider<GenreNotifier, Genre?>(GenreNotifier.new);

// ─────────────────────────────────────────────────
// Search query (Notifier-based)
// ─────────────────────────────────────────────────

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void update(String query) => state = query;
}

// ─────────────────────────────────────────────────
// Title cross-reference exclusion set
// ─────────────────────────────────────────────────
// Fetches anime + game titles and caches them.
// Movie/TV sections filter out any TMDB result whose
// title matches an anime or game title.
// ─────────────────────────────────────────────────

String _normalize(String title) {
  return title
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

final _exclusionTitlesProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.read(discoveryRepoProvider);
  // Fetch first 3 pages of anime (60 titles) + 1 page of games (20)
  final results = await Future.wait([
    repo.popularAnime(page: 1),
    repo.popularAnime(page: 2),
    repo.popularAnime(page: 3),
    repo.popularGames(page: 1),
  ]);
  final titles = <String>{};
  for (final list in results) {
    for (final item in list) {
      titles.add(_normalize(item.title));
    }
  }
  return titles;
});

/// Filter out items whose normalized title appears in the exclusion set.
List<DiscoveryMedia> _applyExclusion(
    List<DiscoveryMedia> items, Set<String> exclusions) {
  return items.where((e) => !exclusions.contains(_normalize(e.title))).toList();
}

// ─────────────────────────────────────────────────
// Paginated state
// ─────────────────────────────────────────────────

class PaginatedState {
  final List<DiscoveryMedia> items;
  final int page;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isInitialLoading;

  const PaginatedState({
    this.items = const [],
    this.page = 1,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.isInitialLoading = true,
  });

  PaginatedState copyWith({
    List<DiscoveryMedia>? items,
    int? page,
    bool? isLoadingMore,
    bool? hasMore,
    bool? isInitialLoading,
  }) {
    return PaginatedState(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
    );
  }
}

// ─────────────────────────────────────────────────
// Safety guard
// ─────────────────────────────────────────────────

void _assertType(List<DiscoveryMedia> items, MediaType expected) {
  assert(() {
    for (final item in items) {
      if (item.type != expected) {
        throw FlutterError(
          'Wrong media type injected into $expected section: '
          '"${item.title}" has type ${item.type}',
        );
      }
    }
    return true;
  }());
}

// ─────────────────────────────────────────────────
// Paginated notifiers
// ─────────────────────────────────────────────────

class PaginatedMoviesNotifier extends Notifier<PaginatedState> {
  @override
  PaginatedState build() {
    final genre = ref.watch(selectedMovieGenreProvider);
    _fetchInitial(genre);
    return const PaginatedState();
  }

  Future<void> _fetchInitial(Genre? genre) async {
    final exclusions = await ref.read(_exclusionTitlesProvider.future);
    var items = await ref.read(discoveryRepoProvider).discoverMovies(
      page: 1,
      genreId: genre?.id,
    );
    items = _applyExclusion(items, exclusions);
    _assertType(items, MediaType.movie);
    state = PaginatedState(
      items: items,
      hasMore: items.length >= 10,
      isInitialLoading: false,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) return;
    state = state.copyWith(isLoadingMore: true);

    final genre = ref.read(selectedMovieGenreProvider);
    final exclusions = await ref.read(_exclusionTitlesProvider.future);
    var next = await ref.read(discoveryRepoProvider).discoverMovies(
      page: state.page + 1,
      genreId: genre?.id,
    );
    next = _applyExclusion(next, exclusions);
    _assertType(next, MediaType.movie);

    final existing = state.items.map((e) => e.externalId).toSet();
    final deduped = next.where((e) => !existing.contains(e.externalId)).toList();

    state = state.copyWith(
      items: [...state.items, ...deduped],
      page: state.page + 1,
      isLoadingMore: false,
      hasMore: next.length >= 10,
    );
  }
}

class PaginatedTvNotifier extends Notifier<PaginatedState> {
  @override
  PaginatedState build() {
    final genre = ref.watch(selectedTvGenreProvider);
    _fetchInitial(genre);
    return const PaginatedState();
  }

  Future<void> _fetchInitial(Genre? genre) async {
    final exclusions = await ref.read(_exclusionTitlesProvider.future);
    var items = await ref.read(discoveryRepoProvider).discoverTv(
      page: 1,
      genreId: genre?.id,
    );
    items = _applyExclusion(items, exclusions);
    _assertType(items, MediaType.tv);
    state = PaginatedState(
      items: items,
      hasMore: items.length >= 10,
      isInitialLoading: false,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) return;
    state = state.copyWith(isLoadingMore: true);

    final genre = ref.read(selectedTvGenreProvider);
    final exclusions = await ref.read(_exclusionTitlesProvider.future);
    var next = await ref.read(discoveryRepoProvider).discoverTv(
      page: state.page + 1,
      genreId: genre?.id,
    );
    next = _applyExclusion(next, exclusions);
    _assertType(next, MediaType.tv);

    final existing = state.items.map((e) => e.externalId).toSet();
    final deduped = next.where((e) => !existing.contains(e.externalId)).toList();

    state = state.copyWith(
      items: [...state.items, ...deduped],
      page: state.page + 1,
      isLoadingMore: false,
      hasMore: next.length >= 10,
    );
  }
}

class PaginatedAnimeNotifier extends Notifier<PaginatedState> {
  @override
  PaginatedState build() {
    final genre = ref.watch(selectedAnimeGenreProvider);
    _fetchInitial(genre);
    return const PaginatedState();
  }

  Future<void> _fetchInitial(Genre? genre) async {
    final items = await ref.read(discoveryRepoProvider).discoverAnime(
      page: 1,
      genreId: genre?.id,
    );
    _assertType(items, MediaType.anime);
    state = PaginatedState(
      items: items,
      hasMore: items.length >= 20,
      isInitialLoading: false,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) return;
    state = state.copyWith(isLoadingMore: true);

    final genre = ref.read(selectedAnimeGenreProvider);
    final next = await ref.read(discoveryRepoProvider).discoverAnime(
      page: state.page + 1,
      genreId: genre?.id,
    );
    _assertType(next, MediaType.anime);

    final existing = state.items.map((e) => e.externalId).toSet();
    final deduped = next.where((e) => !existing.contains(e.externalId)).toList();

    state = state.copyWith(
      items: [...state.items, ...deduped],
      page: state.page + 1,
      isLoadingMore: false,
      hasMore: next.length >= 20,
    );
  }
}

class PaginatedBooksNotifier extends Notifier<PaginatedState> {
  @override
  PaginatedState build() {
    _fetchInitial();
    return const PaginatedState();
  }

  Future<void> _fetchInitial() async {
    final items = await ref.read(discoveryRepoProvider).popularBooks(page: 1);
    _assertType(items, MediaType.book);
    state = PaginatedState(
      items: items,
      hasMore: items.length >= 20,
      isInitialLoading: false,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) return;
    state = state.copyWith(isLoadingMore: true);

    final next = await ref.read(discoveryRepoProvider).popularBooks(
      page: state.page + 1,
    );
    _assertType(next, MediaType.book);

    final existing = state.items.map((e) => e.externalId).toSet();
    final deduped = next.where((e) => !existing.contains(e.externalId)).toList();

    state = state.copyWith(
      items: [...state.items, ...deduped],
      page: state.page + 1,
      isLoadingMore: false,
      hasMore: next.length >= 20,
    );
  }
}

class PaginatedGamesNotifier extends Notifier<PaginatedState> {
  @override
  PaginatedState build() {
    final genre = ref.watch(selectedGameGenreProvider);
    _fetchInitial(genre);
    return const PaginatedState();
  }

  Future<void> _fetchInitial(Genre? genre) async {
    final items = await ref.read(discoveryRepoProvider).discoverGames(
      page: 1,
      genreId: genre?.id,
    );
    _assertType(items, MediaType.game);
    state = PaginatedState(
      items: items,
      hasMore: items.length >= 20,
      isInitialLoading: false,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) return;
    state = state.copyWith(isLoadingMore: true);

    final genre = ref.read(selectedGameGenreProvider);
    final next = await ref.read(discoveryRepoProvider).discoverGames(
      page: state.page + 1,
      genreId: genre?.id,
    );
    _assertType(next, MediaType.game);

    final existing = state.items.map((e) => e.externalId).toSet();
    final deduped = next.where((e) => !existing.contains(e.externalId)).toList();

    state = state.copyWith(
      items: [...state.items, ...deduped],
      page: state.page + 1,
      isLoadingMore: false,
      hasMore: next.length >= 20,
    );
  }
}

// ─────────────────────────────────────────────────
// Provider declarations
// ─────────────────────────────────────────────────

final paginatedMoviesProvider =
    NotifierProvider<PaginatedMoviesNotifier, PaginatedState>(
  PaginatedMoviesNotifier.new,
);

final paginatedTvProvider =
    NotifierProvider<PaginatedTvNotifier, PaginatedState>(
  PaginatedTvNotifier.new,
);

final paginatedAnimeProvider =
    NotifierProvider<PaginatedAnimeNotifier, PaginatedState>(
  PaginatedAnimeNotifier.new,
);

final paginatedBooksProvider =
    NotifierProvider<PaginatedBooksNotifier, PaginatedState>(
  PaginatedBooksNotifier.new,
);

final paginatedGamesProvider =
    NotifierProvider<PaginatedGamesNotifier, PaginatedState>(
  PaginatedGamesNotifier.new,
);

// ─────────────────────────────────────────────────
// Detail / Similar
// ─────────────────────────────────────────────────

final mediaDetailProvider =
    FutureProvider.family<DiscoveryMedia?, ({String id, String typeName})>(
  (ref, key) async {
    final repo = ref.read(discoveryRepoProvider);
    switch (key.typeName) {
      case 'movie':
      case 'tv':
        return repo.tmdbDetail(key.id, MediaType.values.byName(key.typeName));
      case 'anime':
        return repo.animeDetail(key.id);
      case 'game':
        return repo.gameDetail(key.id);
      default:
        return null;
    }
  },
);

final similarMediaProvider =
    FutureProvider.family<List<DiscoveryMedia>, ({String id, String typeName})>(
  (ref, key) async {
    final repo = ref.read(discoveryRepoProvider);
    switch (key.typeName) {
      case 'movie':
      case 'tv':
        return repo.tmdbSimilar(key.id, MediaType.values.byName(key.typeName));
      case 'anime':
        return repo.animeSimilar(key.id);
      case 'game':
        return repo.gameSimilar(key.id);
      default:
        return [];
    }
  },
);
