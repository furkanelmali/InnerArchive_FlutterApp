enum AnimeFormat {
  movie,
  series,
  ova,
  special,
  unknown;

  String get label {
    switch (this) {
      case AnimeFormat.movie:
        return 'Movie';
      case AnimeFormat.series:
        return 'Series';
      case AnimeFormat.ova:
        return 'OVA';
      case AnimeFormat.special:
        return 'Special';
      case AnimeFormat.unknown:
        return 'Unknown';
    }
  }

  /// Map from Jikan API "type" field.
  static AnimeFormat fromJikan(String? jikanType) {
    switch (jikanType?.toLowerCase()) {
      case 'movie':
        return AnimeFormat.movie;
      case 'tv':
        return AnimeFormat.series;
      case 'ova':
        return AnimeFormat.ova;
      case 'special':
        return AnimeFormat.special;
      case 'ona':
        return AnimeFormat.series;
      default:
        return AnimeFormat.unknown;
    }
  }
}
