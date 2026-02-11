import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/theme/app_colors.dart';
import '../models/media_item.dart';
import '../providers/media_search_provider.dart';
import 'edit_media_screen.dart';

class SearchMediaScreen extends ConsumerStatefulWidget {
  const SearchMediaScreen({super.key});

  @override
  ConsumerState<SearchMediaScreen> createState() => _SearchMediaScreenState();
}

class _SearchMediaScreenState extends ConsumerState<SearchMediaScreen> {
  final _controller = TextEditingController();
  MediaType _selectedType = MediaType.movie;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(mediaSearchProvider.notifier).search(query, _selectedType);
    });
  }

  void _onTypeChanged(MediaType type) {
    setState(() => _selectedType = type);
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      ref.read(mediaSearchProvider.notifier).search(query, type);
    }
  }

  void _onResultTap(MediaItem item) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EditMediaScreen(searchResult: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resultsAsync = ref.watch(mediaSearchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onQueryChanged,
              style: theme.textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Search movies, shows, anime, books, games...',
                prefixIcon: Icon(Icons.search, color: AppColors.textTertiary),
              ),
            ),
          ),
          _buildTypeSelector(),
          Expanded(
            child: resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      Text('Search failed', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Check your connection or API keys',
                        style: theme.textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              data: (results) {
                if (_controller.text.trim().isEmpty) {
                  return _buildInitialState(theme);
                }
                if (results.isEmpty) {
                  return _buildEmptyState(theme);
                }
                return _buildResults(results);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: MediaType.values.map((type) {
          final selected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onTypeChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  type.label,
                  style: TextStyle(
                    color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInitialState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64, color: AppColors.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Start typing to search', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No results found', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildResults(List<MediaItem> results) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = results[index];
        return _SearchResultCard(item: item, onTap: () => _onResultTap(item));
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onTap;

  const _SearchResultCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 80,
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(color: AppColors.surfaceLight),
                        errorWidget: (_, _, _) => _posterFallback(),
                      )
                    : _posterFallback(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.releaseDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.releaseDate!.year.toString(),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _posterFallback() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 24),
    );
  }
}
