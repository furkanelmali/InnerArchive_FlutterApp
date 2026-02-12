import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/enums/media_status.dart';
import '../../../core/enums/media_type.dart';
import '../../media/providers/media_provider.dart';
import '../../media/providers/stats_provider.dart';
import '../models/taste_summary_model.dart';

final aiServiceProvider = Provider<AiService>((ref) => AiService());

final tasteProvider =
    AsyncNotifierProvider<TasteNotifier, TasteSummary?>(TasteNotifier.new);

class TasteNotifier extends AsyncNotifier<TasteSummary?> {
  static const _boxName = 'taste_cache';
  static const _key = 'last_taste';

  @override
  Future<TasteSummary?> build() async {
    // Try cached first
    final box = await Hive.openBox(_boxName);
    final cached = box.get(_key) as String?;
    if (cached != null) {
      try {
        return TasteSummary.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    return null;
  }

  Future<void> generate() async {
    final stats = ref.read(statsProvider);
    final itemsAsync = ref.read(mediaProvider);
    final items = itemsAsync.asData?.value ?? [];

    if (items.isEmpty) return;

    state = const AsyncLoading();

    final ai = ref.read(aiServiceProvider);

    final rated = [...items]
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    final topRated = rated.take(20).map((e) => e.title).toList();

    final recentCompleted = items
        .where((e) => e.status == MediaStatus.completed)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recentTitles =
        recentCompleted.take(10).map((e) => e.title).toList();

    final typeBreakdown = <String, int>{};
    for (final type in MediaType.values) {
      final count = items.where((e) => e.type == type).length;
      if (count > 0) typeBreakdown[type.label] = count;
    }

    final result = await ai.getTasteSummary(
      topRatedTitles: topRated,
      mostConsumedType: stats.mostConsumedType?.label ?? 'Unknown',
      averageRating: stats.averageRating,
      recentCompletedTitles: recentTitles,
      typeBreakdown: typeBreakdown,
    );

    if (result != null) {
      state = AsyncData(result);
      // Cache
      final box = await Hive.openBox(_boxName);
      await box.put(_key, jsonEncode(result.toJson()));
    } else {
      state = AsyncData(state.asData?.value);
    }
  }
}
