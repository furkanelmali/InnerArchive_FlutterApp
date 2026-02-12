import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../models/media_item.dart';
import '../providers/home_provider.dart';
import '../providers/media_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/media_poster_card.dart';
import 'edit_media_screen.dart';
import 'search_media_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(mediaProvider);
    final syncState = ref.watch(syncProvider);

    return Scaffold(
      body: itemsAsync.when(
        loading: () => _ShimmerHome(),
        error: (_, _) => Center(
          child: Text('Something went wrong',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        data: (_) => _HomeBody(syncState: syncState),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchMediaScreen()),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  final SyncState syncState;
  const _HomeBody({required this.syncState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);

    if (home.isEmpty) return const _EmptyHome();

    return RefreshIndicator(
      onRefresh: () => ref.read(syncProvider.notifier).sync(),
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            title: const Text('Inner Archive'),
            actions: [
              _SyncDot(status: syncState.status),
              const SizedBox(width: 8),
            ],
          ),

          // Continue Watching
          if (home.continueWatching.isNotEmpty)
            _SectionSliver(
              title: 'Continue',
              items: home.continueWatching,
              cardWidth: 140,
            ),

          // Recently Added
          if (home.recentlyAdded.isNotEmpty)
            _SectionSliver(
              title: 'Recently Added',
              items: home.recentlyAdded,
            ),

          // Movies
          if (home.movies.isNotEmpty)
            _SectionSliver(
              title: 'Movies',
              items: home.movies,
            ),

          // TV Shows
          if (home.tvShows.isNotEmpty)
            _SectionSliver(
              title: 'TV Shows',
              items: home.tvShows,
            ),

          // Anime
          if (home.anime.isNotEmpty)
            _SectionSliver(
              title: 'Anime',
              items: home.anime,
            ),

          // Books
          if (home.books.isNotEmpty)
            _SectionSliver(
              title: 'Books',
              items: home.books,
            ),

          // Games
          if (home.games.isNotEmpty)
            _SectionSliver(
              title: 'Games',
              items: home.games,
            ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Section sliver
// ─────────────────────────────────────────────────

class _SectionSliver extends StatefulWidget {
  final String title;
  final List<MediaItem> items;
  final double cardWidth;

  const _SectionSliver({
    required this.title,
    required this.items,
    this.cardWidth = 120,
  });

  @override
  State<_SectionSliver> createState() => _SectionSliverState();
}

class _SectionSliverState extends State<_SectionSliver>
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
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = widget.cardWidth / (2 / 3);

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
              const SizedBox(height: 14),

              // Horizontal list
              SizedBox(
                height: height,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return MediaPosterCard(
                      item: item,
                      width: widget.cardWidth,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditMediaScreen(itemId: item.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Sync indicator
// ─────────────────────────────────────────────────

class _SyncDot extends StatelessWidget {
  final SyncStatus status;
  const _SyncDot({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.idle) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Center(
        child: status == SyncStatus.syncing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.primary,
                ),
              )
            : Icon(
                status == SyncStatus.success
                    ? Icons.cloud_done
                    : Icons.cloud_off,
                size: 18,
                color: status == SyncStatus.success
                    ? AppColors.success
                    : AppColors.error,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────

class _EmptyHome extends StatelessWidget {
  const _EmptyHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 72,
              color: AppColors.textTertiary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'Your library is empty',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding something.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Shimmer loading
// ─────────────────────────────────────────────────

class _ShimmerHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceLight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 140,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
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
              const SizedBox(height: 32),
              Container(
                width: 100,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
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
            ],
          ),
        ),
      ),
    );
  }
}
