import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/enums/media_status.dart';
import '../models/media_item.dart';
import 'media_provider.dart';

class MediaStats {
  final int totalItems;
  final int completedCount;
  final int watchlistCount;
  final int inProgressCount;
  final int droppedCount;
  final double completionRate;
  final double averageRating;
  final MediaType? mostConsumedType;
  final List<MediaItem> recentlyAdded;
  final Map<MediaType, TypeStats> byType;

  const MediaStats({
    required this.totalItems,
    required this.completedCount,
    required this.watchlistCount,
    required this.inProgressCount,
    required this.droppedCount,
    required this.completionRate,
    required this.averageRating,
    required this.mostConsumedType,
    required this.recentlyAdded,
    required this.byType,
  });
}

class TypeStats {
  final int total;
  final int completed;
  final int watchlist;
  final double averageRating;

  const TypeStats({
    required this.total,
    required this.completed,
    required this.watchlist,
    required this.averageRating,
  });
}

final statsProvider = Provider<MediaStats>((ref) {
  final itemsAsync = ref.watch(mediaProvider);
  final items = itemsAsync.asData?.value ?? [];

  if (items.isEmpty) {
    return const MediaStats(
      totalItems: 0,
      completedCount: 0,
      watchlistCount: 0,
      inProgressCount: 0,
      droppedCount: 0,
      completionRate: 0,
      averageRating: 0,
      mostConsumedType: null,
      recentlyAdded: [],
      byType: {},
    );
  }

  final completed = items.where((e) => e.status == MediaStatus.completed).length;
  final watchlist = items.where((e) => e.status == MediaStatus.watchlist).length;
  final inProgress = items.where((e) => e.status == MediaStatus.inProgress).length;
  final dropped = items.where((e) => e.status == MediaStatus.dropped).length;

  final rated = items.where((e) => e.rating != null).toList();
  final avgRating = rated.isEmpty
      ? 0.0
      : rated.fold<int>(0, (sum, e) => sum + e.rating!) / rated.length;

  final typeCounts = <MediaType, int>{};
  for (final item in items) {
    typeCounts[item.type] = (typeCounts[item.type] ?? 0) + 1;
  }
  MediaType? mostConsumed;
  int maxCount = 0;
  for (final entry in typeCounts.entries) {
    if (entry.value > maxCount) {
      maxCount = entry.value;
      mostConsumed = entry.key;
    }
  }

  final recent = [...items]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final byType = <MediaType, TypeStats>{};
  for (final type in MediaType.values) {
    final ofType = items.where((e) => e.type == type).toList();
    if (ofType.isEmpty) continue;
    final typeRated = ofType.where((e) => e.rating != null).toList();
    byType[type] = TypeStats(
      total: ofType.length,
      completed: ofType.where((e) => e.status == MediaStatus.completed).length,
      watchlist: ofType.where((e) => e.status == MediaStatus.watchlist).length,
      averageRating: typeRated.isEmpty
          ? 0
          : typeRated.fold<int>(0, (s, e) => s + e.rating!) / typeRated.length,
    );
  }

  return MediaStats(
    totalItems: items.length,
    completedCount: completed,
    watchlistCount: watchlist,
    inProgressCount: inProgress,
    droppedCount: dropped,
    completionRate: items.isEmpty ? 0 : completed / items.length * 100,
    averageRating: avgRating,
    mostConsumedType: mostConsumed,
    recentlyAdded: recent.take(5).toList(),
    byType: byType,
  );
});
