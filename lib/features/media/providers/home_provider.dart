import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/media_status.dart';
import '../../../core/enums/media_type.dart';
import '../models/media_item.dart';
import 'media_provider.dart';

class HomeData {
  final List<MediaItem> continueWatching;
  final List<MediaItem> recentlyAdded;
  final List<MediaItem> movies;
  final List<MediaItem> tvShows;
  final List<MediaItem> anime;
  final List<MediaItem> books;
  final List<MediaItem> games;

  const HomeData({
    required this.continueWatching,
    required this.recentlyAdded,
    required this.movies,
    required this.tvShows,
    required this.anime,
    required this.books,
    required this.games,
  });

  bool get isEmpty =>
      continueWatching.isEmpty &&
      recentlyAdded.isEmpty &&
      movies.isEmpty &&
      tvShows.isEmpty &&
      anime.isEmpty &&
      books.isEmpty &&
      games.isEmpty;
}

final homeProvider = Provider<HomeData>((ref) {
  final itemsAsync = ref.watch(mediaProvider);
  final items = itemsAsync.asData?.value ?? [];

  if (items.isEmpty) {
    return const HomeData(
      continueWatching: [],
      recentlyAdded: [],
      movies: [],
      tvShows: [],
      anime: [],
      books: [],
      games: [],
    );
  }

  final continueWatching = items
      .where((e) => e.status == MediaStatus.inProgress)
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  final recentlyAdded = [...items]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<MediaItem> forType(MediaType type) {
    final ofType = items.where((e) => e.type == type).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ofType.take(10).toList();
  }

  return HomeData(
    continueWatching: continueWatching.take(10).toList(),
    recentlyAdded: recentlyAdded.take(15).toList(),
    movies: forType(MediaType.movie),
    tvShows: forType(MediaType.tv),
    anime: forType(MediaType.anime),
    books: forType(MediaType.book),
    games: forType(MediaType.game),
  );
});
