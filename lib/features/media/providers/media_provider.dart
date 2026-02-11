import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/media_status.dart';
import '../models/media_item.dart';
import '../repository/hive_media_repository.dart';
import '../repository/media_repository.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return HiveMediaRepository();
});

final mediaProvider =
    AsyncNotifierProvider<MediaNotifier, List<MediaItem>>(MediaNotifier.new);

class MediaNotifier extends AsyncNotifier<List<MediaItem>> {
  late final MediaRepository _repository;

  @override
  Future<List<MediaItem>> build() async {
    _repository = ref.read(mediaRepositoryProvider);
    return _repository.loadAll();
  }

  List<MediaItem> _current() => [...?state.asData?.value];

  Future<void> add(MediaItem item) async {
    final items = _current()..insert(0, item);
    state = AsyncData(items);
    await _repository.saveAll(items);
  }

  Future<void> updateItem(MediaItem item) async {
    final items = _current();
    final index = items.indexWhere((e) => e.id == item.id);
    if (index == -1) return;
    items[index] = item;
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = AsyncData(items);
    await _repository.saveAll(items);
  }

  Future<void> delete(String id) async {
    final items = _current()..removeWhere((e) => e.id == id);
    state = AsyncData(items);
    await _repository.saveAll(items);
  }

  Future<void> changeStatus(String id, MediaStatus status) async {
    final items = _current();
    final index = items.indexWhere((e) => e.id == id);
    if (index == -1) return;
    items[index] = items[index].copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    state = AsyncData(items);
    await _repository.saveAll(items);
  }

  Future<void> rate(String id, int rating) async {
    final items = _current();
    final index = items.indexWhere((e) => e.id == id);
    if (index == -1) return;
    items[index] = items[index].copyWith(
      rating: rating,
      updatedAt: DateTime.now(),
    );
    state = AsyncData(items);
    await _repository.saveAll(items);
  }
}
