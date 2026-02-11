import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/media_type.dart';
import '../models/media_item.dart';
import '../services/media_search_service.dart';

final mediaSearchServiceProvider = Provider<MediaSearchService>((ref) {
  return MediaSearchService();
});

final mediaSearchProvider =
    AsyncNotifierProvider<MediaSearchNotifier, List<MediaItem>>(
        MediaSearchNotifier.new);

class MediaSearchNotifier extends AsyncNotifier<List<MediaItem>> {
  String _lastQuery = '';
  MediaType _lastType = MediaType.movie;

  @override
  Future<List<MediaItem>> build() async => [];

  Future<void> search(String query, MediaType type) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const AsyncData([]);
      return;
    }

    if (trimmed == _lastQuery && type == _lastType && state.hasValue) return;

    _lastQuery = trimmed;
    _lastType = type;
    state = const AsyncLoading();

    try {
      final service = ref.read(mediaSearchServiceProvider);
      final results = await service.search(trimmed, type);
      state = AsyncData(results);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void clear() {
    _lastQuery = '';
    state = const AsyncData([]);
  }
}
