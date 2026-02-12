import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/media_status.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../media/models/media_item.dart';
import '../../media/providers/media_provider.dart';
import '../../media/screens/edit_media_screen.dart';
import '../../media/widgets/media_poster_card.dart';

class CollectionTypeScreen extends ConsumerStatefulWidget {
  final MediaType type;
  const CollectionTypeScreen({super.key, required this.type});

  @override
  ConsumerState<CollectionTypeScreen> createState() =>
      _CollectionTypeScreenState();
}

class _CollectionTypeScreenState extends ConsumerState<CollectionTypeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  static const _tabs = [
    'All',
    'Watchlist',
    'In Progress',
    'Completed',
    'Dropped',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  MediaStatus? _statusForTab(int index) {
    switch (index) {
      case 1:
        return MediaStatus.watchlist;
      case 2:
        return MediaStatus.inProgress;
      case 3:
        return MediaStatus.completed;
      case 4:
        return MediaStatus.dropped;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(mediaProvider);
    final allItems = itemsAsync.asData?.value ?? [];
    final ofType = allItems.where((e) => e.type == widget.type).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type.label),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: List.generate(_tabs.length, (i) {
          final status = _statusForTab(i);
          final filtered = status == null
              ? ofType
              : ofType.where((e) => e.status == status).toList();
          return _CollectionGrid(items: filtered);
        }),
      ),
    );
  }
}

class _CollectionGrid extends StatelessWidget {
  final List<MediaItem> items;
  const _CollectionGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined,
                size: 48,
                color: AppColors.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'Nothing here yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        return MediaPosterCard(
          item: items[i],
          onTap: () => Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => EditMediaScreen(itemId: items[i].id),
            ),
          ),
        );
      },
    );
  }
}
