import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/ai_recommendation_provider.dart';
import '../screens/media_detail_screen.dart';
import '../widgets/discovery_poster_card.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recsAsync = ref.watch(recommendationsProvider);

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
            title: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ).createShader(bounds),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                const Text('For You'),
              ],
            ),
          ),
          recsAsync.when(
            loading: () => SliverToBoxAdapter(child: _buildShimmer()),
            error: (_, _) => SliverToBoxAdapter(
              child: _buildEmpty(
                Icons.error_outline,
                'Something went wrong.\nPull to refresh.',
              ),
            ),
            data: (sections) {
              if (sections.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildEmpty(
                    Icons.star_outline_rounded,
                    'Rate some items in your library\nto get personalized recommendations.',
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Based on your favorites',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                  ...sections.map((section) => _SimilarSection(
                        section: section,
                      )),
                  const SizedBox(height: 40),
                  // Refresh button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ref.invalidate(recommendationsProvider),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Center(
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ).createShader(bounds),
              child: Icon(icon, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Shimmer.fromColors(
              baseColor: AppColors.surface,
              highlightColor: AppColors.surfaceLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 200,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Section: "Because you liked [Title]"
// ─────────────────────────────────────────────────

class _SimilarSection extends StatelessWidget {
  final RecommendationSection section;
  const _SimilarSection({required this.section});

  String _typeEmoji(String typeName) {
    switch (typeName) {
      case 'movie':
        return '🎬';
      case 'tv':
        return '📺';
      case 'anime':
        return '🎌';
      case 'game':
        return '🎮';
      default:
        return '📀';
    }
  }

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
            child: Row(
              children: [
                Text(
                  _typeEmoji(section.sourceType.name),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Because you liked ',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextSpan(
                          text: section.sourceTitle,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: section.recommendations.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) {
                final item = section.recommendations[i];
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
        ],
      ),
    );
  }
}
