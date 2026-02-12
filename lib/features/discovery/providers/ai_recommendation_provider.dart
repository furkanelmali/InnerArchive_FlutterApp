import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/media_type.dart';
import '../../media/providers/media_provider.dart';
import '../models/discovery_media_model.dart';
import '../providers/discovery_provider.dart';

// ─────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────

class RecommendationSection {
  final String sourceTitle;
  final String? sourceImageUrl;
  final MediaType sourceType;
  final List<DiscoveryMedia> recommendations;

  const RecommendationSection({
    required this.sourceTitle,
    this.sourceImageUrl,
    required this.sourceType,
    required this.recommendations,
  });
}

// ─────────────────────────────────────────────────
// Provider — fetches similar content for top-rated items
// ─────────────────────────────────────────────────

final recommendationsProvider =
    FutureProvider<List<RecommendationSection>>((ref) async {
  final items = await ref.watch(mediaProvider.future);
  final repo = ref.read(discoveryRepoProvider);

  // Filter: must have a rating + externalId to look up similars
  final rated = items
      .where((e) => e.rating != null && e.externalId != null)
      .toList()
    ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

  // Take up to 8 highest-rated items
  final topItems = rated.take(8).toList();

  if (topItems.isEmpty) return [];

  final sections = <RecommendationSection>[];

  // Fetch similar content in parallel
  final futures = topItems.map((item) async {
    try {
      List<DiscoveryMedia> similar;

      switch (item.type) {
        case MediaType.movie:
          similar = await repo.tmdbSimilar(item.externalId!, MediaType.movie);
          break;
        case MediaType.tv:
          similar = await repo.tmdbSimilar(item.externalId!, MediaType.tv);
          break;
        case MediaType.anime:
          similar = await repo.animeSimilar(item.externalId!);
          break;
        case MediaType.game:
          similar = await repo.gameSimilar(item.externalId!);
          break;
        default:
          similar = [];
      }

      // Filter out items already in user's library
      final libraryIds = items
          .where((e) => e.externalId != null)
          .map((e) => e.externalId!)
          .toSet();
      similar = similar
          .where((s) => !libraryIds.contains(s.externalId))
          .toList();

      if (similar.isNotEmpty) {
        return RecommendationSection(
          sourceTitle: item.title,
          sourceImageUrl: item.imageUrl,
          sourceType: item.type,
          recommendations: similar.take(10).toList(),
        );
      }
    } catch (_) {
      // Skip failed lookups silently
    }
    return null;
  });

  final results = await Future.wait(futures);

  for (final section in results) {
    if (section != null) sections.add(section);
  }

  return sections;
});
