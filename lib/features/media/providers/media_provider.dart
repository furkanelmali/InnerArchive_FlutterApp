import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/media_status.dart';
import '../data/remote_data_source.dart';
import '../models/media_item.dart';
import '../repository/hive_media_repository.dart';
import '../repository/media_repository_impl.dart';

final mediaRepositoryProvider = Provider<MediaRepositoryImpl>((ref) {
  return MediaRepositoryImpl(
    local: HiveMediaRepository(),
    remote: RemoteDataSource(),
  );
});

final mediaProvider =
    AsyncNotifierProvider<MediaNotifier, List<MediaItem>>(MediaNotifier.new);

class MediaNotifier extends AsyncNotifier<List<MediaItem>> {
  late final MediaRepositoryImpl _repository;

  @override
  Future<List<MediaItem>> build() async {
    _repository = ref.read(mediaRepositoryProvider);
    final localItems = await _repository.loadAll();
    state = AsyncData(localItems);

    _syncInBackground();
    return localItems;
  }

  Future<void> _syncInBackground() async {
    try {
      await _repository.syncWithRemote();
      final synced = await _repository.loadAll();
      state = AsyncData(synced);
    } catch (_) {}
  }

  List<MediaItem> _current() => [...?state.asData?.value];

  Future<void> add(MediaItem item) async {
    final items = _current()..insert(0, item);
    state = AsyncData(items);
    await _repository.addAndSync(item);
  }

  Future<void> updateItem(MediaItem item) async {
    final items = _current();
    final index = items.indexWhere((e) => e.id == item.id);
    if (index == -1) return;
    items[index] = item;
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = AsyncData(items);
    await _repository.updateAndSync(item);
  }

  Future<void> delete(String id) async {
    final items = _current()..removeWhere((e) => e.id == id);
    state = AsyncData(items);
    await _repository.deleteAndSync(id);
  }

  Future<void> changeStatus(String id, MediaStatus status) async {
    final items = _current();
    final index = items.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final updated = items[index].copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    items[index] = updated;
    state = AsyncData(items);
    await _repository.updateAndSync(updated);
  }

  Future<void> rate(String id, int rating) async {
    final items = _current();
    final index = items.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final updated = items[index].copyWith(
      rating: rating,
      updatedAt: DateTime.now(),
    );
    items[index] = updated;
    state = AsyncData(items);
    await _repository.updateAndSync(updated);
  }

  Future<void> forceSync() async {
    await _syncInBackground();
  }
}
