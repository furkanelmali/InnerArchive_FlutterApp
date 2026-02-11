import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import 'media_provider.dart';
import 'stats_provider.dart';

class Recommendation {
  final String reason;
  final List<MediaItem> items;

  const Recommendation({required this.reason, required this.items});
}

final recommendationProvider = Provider<List<Recommendation>>((ref) {
  final stats = ref.watch(statsProvider);
  final itemsAsync = ref.watch(mediaProvider);
  final items = itemsAsync.asData?.value ?? [];

  if (items.length < 3) return [];

  final recommendations = <Recommendation>[];

  final topRated = items
      .where((e) => e.rating != null && e.rating! >= 8)
      .toList()
    ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

  if (topRated.length >= 2) {
    recommendations.add(Recommendation(
      reason: 'Your highest rated',
      items: topRated.take(5).toList(),
    ));
  }

  if (stats.mostConsumedType != null) {
    final ofType = items
        .where((e) => e.type == stats.mostConsumedType)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (ofType.length >= 2) {
      recommendations.add(Recommendation(
        reason: 'More ${stats.mostConsumedType!.label}',
        items: ofType.take(5).toList(),
      ));
    }
  }

  final watchlist = items
      .where((e) => e.status.name == 'watchlist')
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  if (watchlist.isNotEmpty) {
    recommendations.add(Recommendation(
      reason: 'From your watchlist',
      items: watchlist.take(5).toList(),
    ));
  }

  return recommendations;
});
