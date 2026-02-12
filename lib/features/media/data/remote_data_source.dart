import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_client.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/enums/media_status.dart';
import '../../../core/enums/anime_format.dart';
import '../models/media_item.dart';

class RemoteDataSource {
  SupabaseClient get _client => SupabaseClientProvider.client;
  String? get _userId => _client.auth.currentUser?.id;

  Future<List<MediaItem>> fetchAll() async {
    if (_userId == null) return [];

    final response = await _client
        .from('media_items')
        .select()
        .eq('user_id', _userId!)
        .order('updated_at', ascending: false);

    return (response as List)
        .map((r) => rowToMediaItem(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsert(MediaItem item) async {
    if (_userId == null) return;
    await _client.from('media_items').upsert(_toRow(item));
  }

  Future<void> upsertAll(List<MediaItem> items) async {
    if (_userId == null || items.isEmpty) return;
    final rows = items.map(_toRow).toList();
    await _client.from('media_items').upsert(rows);
  }

  Future<void> delete(String id) async {
    if (_userId == null) return;
    await _client
        .from('media_items')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  Map<String, dynamic> _toRow(MediaItem item) {
    return {
      'id': item.id,
      'user_id': _userId,
      'external_id': item.externalId,
      'title': item.title,
      'description': item.description,
      'image_url': item.imageUrl,
      'release_date': item.releaseDate?.toIso8601String(),
      'type': item.type.name,
      'status': item.status.name,
      'rating': item.rating,
      'note': item.note,
      'source': item.source,
      'anime_format': item.animeFormat?.name,
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': item.updatedAt.toIso8601String(),
    };
  }

  static MediaItem rowToMediaItem(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as String,
      externalId: map['external_id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      releaseDate: map['release_date'] != null
          ? DateTime.parse(map['release_date'] as String)
          : null,
      type: MediaType.values.byName(map['type'] as String),
      status: MediaStatus.values.byName(map['status'] as String),
      rating: map['rating'] as int?,
      note: map['note'] as String?,
      source: map['source'] as String?,
      animeFormat: map['anime_format'] != null
          ? AnimeFormat.values.byName(map['anime_format'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
