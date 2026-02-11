import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/media_status.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/filter_provider.dart';
import '../providers/media_provider.dart';
import '../widgets/filter_sort_bar.dart';
import '../widgets/library_tabs.dart';
import '../widgets/media_card.dart';
import 'edit_media_screen.dart';
import 'search_media_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  MediaStatus? _tabStatus;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(mediaProvider);
    final filter = ref.watch(filterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchMediaScreen()),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
      body: Column(
        children: [
          LibraryTabs(
            selectedStatus: _tabStatus,
            onStatusChanged: (status) => setState(() => _tabStatus = status),
          ),
          FilterSortBar(
            filter: filter,
            onTypeChanged: (type) =>
                ref.read(filterProvider.notifier).setType(type),
            onSortChanged: (field) =>
                ref.read(filterProvider.notifier).setSort(field),
          ),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              data: (items) {
                var filtered = applyFilters(items, filter);
                if (_tabStatus != null) {
                  filtered = filtered
                      .where((e) => e.status == _tabStatus)
                      .toList();
                }
                return filtered.isEmpty
                    ? _buildEmptyState(context)
                    : _buildList(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Nothing here yet',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first item',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return MediaCard(
          item: item,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditMediaScreen(itemId: item.id),
            ),
          ),
          onDismissed: () {
            ref.read(mediaProvider.notifier).delete(item.id);
          },
        );
      },
    );
  }
}
