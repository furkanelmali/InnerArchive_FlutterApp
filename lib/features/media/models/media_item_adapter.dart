import 'package:hive/hive.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/enums/media_status.dart';
import '../models/media_item.dart';

class MediaItemAdapter extends TypeAdapter<MediaItem> {
  @override
  final int typeId = 0;

  @override
  MediaItem read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return MediaItem(
      id: map['id'] as String,
      externalId: map['externalId'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      imageUrl: map['imageUrl'] as String?,
      releaseDate: map['releaseDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['releaseDate'] as int)
          : null,
      type: MediaType.values[map['type'] as int],
      status: MediaStatus.values[map['status'] as int],
      rating: map['rating'] as int?,
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  @override
  void write(BinaryWriter writer, MediaItem obj) {
    writer.writeMap({
      'id': obj.id,
      'externalId': obj.externalId,
      'title': obj.title,
      'description': obj.description,
      'imageUrl': obj.imageUrl,
      'releaseDate': obj.releaseDate?.millisecondsSinceEpoch,
      'type': obj.type.index,
      'status': obj.status.index,
      'rating': obj.rating,
      'note': obj.note,
      'createdAt': obj.createdAt.millisecondsSinceEpoch,
      'updatedAt': obj.updatedAt.millisecondsSinceEpoch,
    });
  }
}
