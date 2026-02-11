import '../data/remote_data_source.dart';
import '../models/media_item.dart';
import 'hive_media_repository.dart';
import 'media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  final HiveMediaRepository _local;
  final RemoteDataSource _remote;

  MediaRepositoryImpl({
    required HiveMediaRepository local,
    required RemoteDataSource remote,
  })  : _local = local,
        _remote = remote;

  @override
  Future<List<MediaItem>> loadAll() async {
    return _local.loadAll();
  }

  @override
  Future<void> saveAll(List<MediaItem> items) async {
    await _local.saveAll(items);
  }

  Future<void> syncWithRemote() async {
    try {
      final localItems = await _local.loadAll();
      final remoteItems = await _remote.fetchAll();

      final merged = _merge(localItems, remoteItems);

      await _local.saveAll(merged);

      if (merged.isNotEmpty) {
        await _remote.upsertAll(merged);
      }
    } catch (_) {
      // Offline or error — continue with local data
    }
  }

  Future<void> addAndSync(MediaItem item) async {
    await _local.put(item);
    try {
      await _remote.upsert(item);
    } catch (_) {}
  }

  Future<void> updateAndSync(MediaItem item) async {
    await _local.put(item);
    try {
      await _remote.upsert(item);
    } catch (_) {}
  }

  Future<void> deleteAndSync(String id) async {
    await _local.remove(id);
    try {
      await _remote.delete(id);
    } catch (_) {}
  }

  List<MediaItem> _merge(List<MediaItem> local, List<MediaItem> remote) {
    final map = <String, MediaItem>{};

    for (final item in remote) {
      map[item.id] = item;
    }

    for (final item in local) {
      final existing = map[item.id];
      if (existing == null ||
          item.updatedAt.isAfter(existing.updatedAt)) {
        map[item.id] = item;
      }
    }

    final merged = map.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return merged;
  }
}
