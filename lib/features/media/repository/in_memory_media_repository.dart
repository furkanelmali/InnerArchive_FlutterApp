import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import 'media_repository.dart';

class InMemoryMediaRepository implements MediaRepository {
  static const _key = 'media_items';
  final SharedPreferences _prefs;

  InMemoryMediaRepository(this._prefs);

  @override
  Future<List<MediaItem>> loadAll() async {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null) return [];

    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<void> saveAll(List<MediaItem> items) async {
    final jsonString = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, jsonString);
  }
}
