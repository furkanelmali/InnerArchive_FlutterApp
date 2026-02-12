import 'package:flutter/foundation.dart';
import '../../media/models/media_item.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/enums/media_status.dart';
import '../../../core/enums/anime_format.dart';

@immutable
class Genre {
  final String id;
  final String name;
  const Genre({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Genre && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class DiscoveryMedia {
  final String externalId;
  final String title;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final double? apiRating;
  final DateTime? releaseDate;
  final List<String> genres;
  final MediaType type;
  final String? source; // tmdb, jikan, openlibrary, rawg
  final AnimeFormat? animeFormat;

  // Extended metadata
  final int? runtime;           // minutes (movies)
  final String? studio;         // studio / publisher / developer
  final String? author;         // book author
  final int? episodeCount;      // tv / anime
  final int? seasonCount;       // tv
  final String? status;         // airing, finished, etc.

  const DiscoveryMedia({
    required this.externalId,
    required this.title,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
    this.apiRating,
    this.releaseDate,
    this.genres = const [],
    required this.type,
    this.source,
    this.animeFormat,
    this.runtime,
    this.studio,
    this.author,
    this.episodeCount,
    this.seasonCount,
    this.status,
  });

  /// Convert to user library item for persistence.
  MediaItem toMediaItem({
    MediaStatus status = MediaStatus.watchlist,
    int? rating,
    String? note,
  }) {
    final now = DateTime.now();
    return MediaItem(
      id: now.millisecondsSinceEpoch.toString(),
      externalId: externalId,
      title: title,
      description: overview,
      imageUrl: posterUrl,
      releaseDate: releaseDate,
      type: type,
      status: status,
      rating: rating,
      note: note,
      source: source,
      animeFormat: animeFormat,
      createdAt: now,
      updatedAt: now,
    );
  }

  String? get year =>
      releaseDate != null ? '${releaseDate!.year}' : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveryMedia &&
          runtimeType == other.runtimeType &&
          externalId == other.externalId &&
          type == other.type;

  @override
  int get hashCode => Object.hash(externalId, type);
}
