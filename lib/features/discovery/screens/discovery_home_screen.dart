import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/enums/media_type.dart';
import '../models/discovery_media_model.dart';
import '../providers/discovery_provider.dart';
import '../providers/search_provider.dart';
import '../screens/media_detail_screen.dart';
import '../widgets/discovery_poster_card.dart';

class DiscoveryHomeScreen extends ConsumerStatefulWidget {
  const DiscoveryHomeScreen({super.key});

  @override
  ConsumerState<DiscoveryHomeScreen> createState() =>
      _DiscoveryHomeScreenState();
}

class _DiscoveryHomeScreenState extends ConsumerState<DiscoveryHomeScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).update(query.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final isSearching = query.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            title: const Text('Discover'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search movies, shows, anime, books, games…',
                    hintStyle: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textTertiary, size: 20),
                    suffixIcon: isSearching
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: AppColors.textTertiary),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref
                                  .read(searchQueryProvider.notifier)
                                  .update('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isSearching) ..._buildSearchResults() else ..._buildDiscovery(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // Search results view
  // ─────────────────────────────────────────────────

  List<Widget> _buildSearchResults() {
    final results = ref.watch(searchResultsProvider);
    return [
      results.when(
        loading: () => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
        error: (_, _) => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(
              child: Text(
                'Search failed. Try again.',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
          ),
        ),
        data: (grouped) {
          if (grouped.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(
                  child: Text(
                    'No results found.',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                ),
              ),
            );
          }
          return SliverList(
            delegate: SliverChildListDelegate(
              grouped.entries.map((entry) {
                return _SearchTypeSection(
                  type: entry.key,
                  items: entry.value,
                );
              }).toList(),
            ),
          );
        },
      ),
    ];
  }

  // ─────────────────────────────────────────────────
  // Discovery with genre chips + pagination
  // ─────────────────────────────────────────────────

  List<Widget> _buildDiscovery() {
    return [
      _PaginatedSection(
        title: 'Movies',
        provider: paginatedMoviesProvider,
        genresProvider: movieGenresProvider,
        selectedGenreProvider: selectedMovieGenreProvider,
        loadMore: () =>
            ref.read(paginatedMoviesProvider.notifier).loadMore(),
        cardWidth: 140,
      ),
      _PaginatedSection(
        title: 'TV Shows',
        provider: paginatedTvProvider,
        genresProvider: tvGenresProvider,
        selectedGenreProvider: selectedTvGenreProvider,
        loadMore: () =>
            ref.read(paginatedTvProvider.notifier).loadMore(),
      ),
      _PaginatedSection(
        title: 'Anime',
        provider: paginatedAnimeProvider,
        genresProvider: animeGenresProvider,
        selectedGenreProvider: selectedAnimeGenreProvider,
        loadMore: () =>
            ref.read(paginatedAnimeProvider.notifier).loadMore(),
      ),
      _SimpleSection(
        title: 'Books',
        provider: paginatedBooksProvider,
        loadMore: () =>
            ref.read(paginatedBooksProvider.notifier).loadMore(),
      ),
      _PaginatedSection(
        title: 'Games',
        provider: paginatedGamesProvider,
        genresProvider: gameGenresProvider,
        selectedGenreProvider: selectedGameGenreProvider,
        loadMore: () =>
            ref.read(paginatedGamesProvider.notifier).loadMore(),
      ),
    ];
  }
}

// ─────────────────────────────────────────────────
// Search type section
// ─────────────────────────────────────────────────

class _SearchTypeSection extends StatelessWidget {
  final MediaType type;
  final List<DiscoveryMedia> items;
  const _SearchTypeSection({required this.type, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              type.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) => DiscoveryPosterCard(
                item: items[i],
                onTap: () => Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) => MediaDetailScreen(media: items[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Paginated section with genre chips
// ─────────────────────────────────────────────────

class _PaginatedSection extends ConsumerStatefulWidget {
  final String title;
  final NotifierProvider<Notifier<PaginatedState>, PaginatedState> provider;
  final FutureProvider<List<Genre>> genresProvider;
  final NotifierProvider<GenreNotifier, Genre?> selectedGenreProvider;
  final VoidCallback loadMore;
  final double cardWidth;

  const _PaginatedSection({
    required this.title,
    required this.provider,
    required this.genresProvider,
    required this.selectedGenreProvider,
    required this.loadMore,
    this.cardWidth = 120,
  });

  @override
  ConsumerState<_PaginatedSection> createState() =>
      _PaginatedSectionState();
}

class _PaginatedSectionState extends ConsumerState<_PaginatedSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pState = ref.watch(widget.provider);
    final genres = ref.watch(widget.genresProvider);
    final selectedGenre = ref.watch(widget.selectedGenreProvider);
    final theme = Theme.of(context);
    final height = widget.cardWidth / (2 / 3);

    if (pState.isInitialLoading) {
      return SliverToBoxAdapter(child: _shimmer(height));
    }

    if (pState.items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    _fadeCtrl.forward();

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              // Genre chips
              genres.when(
                loading: () => const SizedBox(height: 8),
                error: (_, _) => const SizedBox(height: 8),
                data: (genreList) {
                  if (genreList.isEmpty) return const SizedBox(height: 8);
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: genreList.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return _genreChip(
                              'All',
                              selectedGenre == null,
                              () => ref
                                  .read(widget.selectedGenreProvider.notifier)
                                  .select(null),
                            );
                          }
                          final g = genreList[i - 1];
                          return _genreChip(
                            g.name,
                            selectedGenre == g,
                            () => ref
                                .read(widget.selectedGenreProvider.notifier)
                                .select(g),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: height,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scroll) {
                    if (scroll is ScrollEndNotification &&
                        scroll.metrics.extentAfter < 200) {
                      widget.loadMore();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: pState.items.length +
                        (pState.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (ctx, i) {
                      if (i == pState.items.length) {
                        return const SizedBox(
                          width: 40,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        );
                      }
                      final item = pState.items[i];
                      return DiscoveryPosterCard(
                        item: item,
                        width: widget.cardWidth,
                        onTap: () => Navigator.of(ctx).push(
                          MaterialPageRoute(
                            builder: (_) => MediaDetailScreen(media: item),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genreChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _shimmer(double height) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: AppColors.surface,
              highlightColor: AppColors.surfaceLight,
              child: Container(
                width: 120,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: height,
            child: Shimmer.fromColors(
              baseColor: AppColors.surface,
              highlightColor: AppColors.surfaceLight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, _) => Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Simple section (no genres, e.g. books)
// ─────────────────────────────────────────────────

class _SimpleSection extends ConsumerStatefulWidget {
  final String title;
  final NotifierProvider<Notifier<PaginatedState>, PaginatedState> provider;
  final VoidCallback loadMore;

  const _SimpleSection({
    required this.title,
    required this.provider,
    required this.loadMore,
  });

  @override
  ConsumerState<_SimpleSection> createState() => _SimpleSectionState();
}

class _SimpleSectionState extends ConsumerState<_SimpleSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pState = ref.watch(widget.provider);
    final theme = Theme.of(context);

    if (pState.isInitialLoading) {
      return SliverToBoxAdapter(child: _shimmer());
    }

    if (pState.items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    _fadeCtrl.forward();

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scroll) {
                    if (scroll is ScrollEndNotification &&
                        scroll.metrics.extentAfter < 200) {
                      widget.loadMore();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: pState.items.length +
                        (pState.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (ctx, i) {
                      if (i == pState.items.length) {
                        return const SizedBox(
                          width: 40,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        );
                      }
                      final item = pState.items[i];
                      return DiscoveryPosterCard(
                        item: item,
                        onTap: () => Navigator.of(ctx).push(
                          MaterialPageRoute(
                            builder: (_) => MediaDetailScreen(media: item),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmer() {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: AppColors.surface,
              highlightColor: AppColors.surfaceLight,
              child: Container(
                width: 120,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: Shimmer.fromColors(
              baseColor: AppColors.surface,
              highlightColor: AppColors.surfaceLight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, _) => Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
