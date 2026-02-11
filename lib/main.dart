import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'features/media/models/media_item.dart';
import 'features/media/models/media_item_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(MediaItemAdapter());
  await Hive.openBox<MediaItem>('media_library');

  runApp(const ProviderScope(child: InnerArchiveApp()));
}
