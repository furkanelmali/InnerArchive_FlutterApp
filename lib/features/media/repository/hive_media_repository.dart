import 'package:hive/hive.dart';
import '../models/media_item.dart';
import 'media_repository.dart';

class HiveMediaRepository implements MediaRepository {
  static const _boxName = 'media_library';

  Box<MediaItem>? _box;

  Future<Box<MediaItem>> get _mediaBox async {
    _box ??= await Hive.openBox<MediaItem>(_boxName);
    return _box!;
  }

  @override
  Future<List<MediaItem>> loadAll() async {
    final box = await _mediaBox;
    final items = box.values.toList();
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<void> saveAll(List<MediaItem> items) async {
    final box = await _mediaBox;
    await box.clear();
    final map = {for (final item in items) item.id: item};
    await box.putAll(map);
  }

  Future<void> put(MediaItem item) async {
    final box = await _mediaBox;
    await box.put(item.id, item);
  }

  Future<void> remove(String id) async {
    final box = await _mediaBox;
    await box.delete(id);
  }
}
