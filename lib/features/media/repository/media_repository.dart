import '../models/media_item.dart';

abstract class MediaRepository {
  Future<List<MediaItem>> loadAll();
  Future<void> saveAll(List<MediaItem> items);
}
