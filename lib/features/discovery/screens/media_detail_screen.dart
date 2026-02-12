import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../media/providers/media_provider.dart';
import '../models/discovery_media_model.dart';
import '../providers/discovery_provider.dart';
import '../widgets/discovery_poster_card.dart';
import 'add_to_library_sheet.dart';

class MediaDetailScreen extends ConsumerWidget {
  final DiscoveryMedia media;
  const MediaDetailScreen({super.key, required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Try fetching richer detail (for TMDB / Jikan / RAWG)
    final detailAsync = ref.watch(
      mediaDetailProvider((id: media.externalId, typeName: media.type.name)),
    );
    final similarAsync = ref.watch(
      similarMediaProvider((id: media.externalId, typeName: media.type.name)),
    );

    final detail = detailAsync.asData?.value ?? media;

    // Check if already in library
    final inLibrary = ref.watch(mediaProvider).asData?.value.any(
              (e) =>
                  e.externalId == media.externalId &&
                  e.type == media.type,
            ) ??
        false;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          _HeroAppBar(media: detail),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Title + year
                  Text(
                    detail.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _MetaRow(media: detail),

                  // Genres
                  if (detail.genres.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: detail.genres.take(5).map((g) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            g,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Rating bar
                  if (detail.apiRating != null && detail.apiRating! > 0) ...[
                    const SizedBox(height: 20),
                    _RatingBar(rating: detail.apiRating!),
                  ],

                  // Overview
                  if (detail.overview != null &&
                      detail.overview!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail.overview!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],

                  // Metadata
                  const SizedBox(height: 24),
                  _DetailMeta(media: detail),

                  // Add to library button
                  const SizedBox(height: 32),
                  _AddButton(
                    media: detail,
                    inLibrary: inLibrary,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Similar
          _SimilarSection(asyncItems: similarAsync),

          const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Hero sliver app bar with backdrop
// ─────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  final DiscoveryMedia media;
  const _HeroAppBar({required this.media});

  @override
  Widget build(BuildContext context) {
    final imageUrl = media.backdropUrl ?? media.posterUrl;

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Hero(
                tag: 'disc_${media.type.name}_${media.externalId}',
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(color: AppColors.surfaceLight),
                  errorWidget: (_, _, _) =>
                      Container(color: AppColors.surfaceLight),
                ),
              )
            else
              Container(color: AppColors.surfaceLight),

            // Gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background,
                  ],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Meta row: year · type · runtime
// ─────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final DiscoveryMedia media;
  const _MetaRow({required this.media});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (media.year != null) media.year!,
      media.type.label,
      if (media.runtime != null) '${media.runtime} min',
      if (media.episodeCount != null) '${media.episodeCount} ep',
      if (media.seasonCount != null) '${media.seasonCount} seasons',
    ];

    return Text(
      parts.join(' · '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.textTertiary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Visual rating bar
// ─────────────────────────────────────────────────

class _RatingBar extends StatelessWidget {
  final double rating;
  const _RatingBar({required this.rating});

  @override
  Widget build(BuildContext context) {
    final maxRating = rating > 5 ? 10.0 : 5.0;
    final percent = (rating / maxRating).clamp(0.0, 1.0);

    return Row(
      children: [
        const Icon(Icons.star_rounded, color: AppColors.warning, size: 22),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          ' / ${maxRating.toInt()}',
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppColors.surfaceLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.warning),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// Detail metadata chips
// ─────────────────────────────────────────────────

class _DetailMeta extends StatelessWidget {
  final DiscoveryMedia media;
  const _DetailMeta({required this.media});

  @override
  Widget build(BuildContext context) {
    final entries = <MapEntry<String, String>>[
      if (media.studio != null) MapEntry('Studio', media.studio!),
      if (media.author != null) MapEntry('Author', media.author!),
      if (media.status != null) MapEntry('Status', media.status!),
    ];

    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  e.key,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  e.value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────
// Add / In Library button
// ─────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final DiscoveryMedia media;
  final bool inLibrary;
  const _AddButton({required this.media, required this.inLibrary});

  @override
  Widget build(BuildContext context) {
    if (inLibrary) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check, color: AppColors.success),
          label: const Text(
            'In Your Library',
            style: TextStyle(color: AppColors.success, fontSize: 15),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.success),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddToLibrarySheet(media: media),
          );
        },
        icon: const Icon(Icons.add, size: 22),
        label: const Text(
          'Add to Library',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Similar media section
// ─────────────────────────────────────────────────

class _SimilarSection extends StatelessWidget {
  final AsyncValue<List<DiscoveryMedia>> asyncItems;
  const _SimilarSection({required this.asyncItems});

  @override
  Widget build(BuildContext context) {
    return asyncItems.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.surfaceLight,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
      error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (items) {
        if (items.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Similar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return DiscoveryPosterCard(
                        item: item,
                        onTap: () => Navigator.of(ctx).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MediaDetailScreen(media: item),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
