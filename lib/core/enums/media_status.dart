enum MediaStatus {
  watchlist,
  inProgress,
  completed,
  dropped;

  String get label {
    switch (this) {
      case MediaStatus.watchlist:
        return 'Watchlist';
      case MediaStatus.inProgress:
        return 'In Progress';
      case MediaStatus.completed:
        return 'Completed';
      case MediaStatus.dropped:
        return 'Dropped';
    }
  }
}
