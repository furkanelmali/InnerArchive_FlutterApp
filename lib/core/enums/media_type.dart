enum MediaType {
  movie,
  tv,
  anime,
  book,
  game;

  String get label {
    switch (this) {
      case MediaType.movie:
        return 'Movie';
      case MediaType.tv:
        return 'TV Show';
      case MediaType.anime:
        return 'Anime';
      case MediaType.book:
        return 'Book';
      case MediaType.game:
        return 'Game';
    }
  }
}
