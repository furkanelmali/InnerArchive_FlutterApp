import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/enums/media_status.dart';
import '../../../core/services/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../media/data/remote_data_source.dart';
import '../../media/models/media_item.dart';
import '../models/profile_model.dart';
import '../repository/profile_repository.dart';

final _publicProfileProvider = FutureProvider.family<_PublicData?, String>(
  (ref, username) async {
    final repo = ProfileRepository();
    final profile = await repo.getByUsername(username);
    if (profile == null) return null;

    // Fetch public media items
    final client = SupabaseClientProvider.client;
    final rows = await client
        .from('media_items')
        .select()
        .eq('user_id', profile.id)
        .order('rating', ascending: false)
        .limit(20);

    final items = (rows as List)
        .map((r) => RemoteDataSource.rowToMediaItem(r as Map<String, dynamic>))
        .toList();

    return _PublicData(profile: profile, items: items);
  },
);

class _PublicData {
  final UserProfile profile;
  final List<MediaItem> items;
  const _PublicData({required this.profile, required this.items});
}

class PublicProfileScreen extends ConsumerWidget {
  final String username;
  const PublicProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_publicProfileProvider(username));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('@$username')),
      body: dataAsync.when(
        loading: () => _shimmerBody(),
        error: (_, _) => const Center(child: Text('Failed to load profile')),
        data: (data) {
          if (data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off,
                      size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text('Profile not found or is private',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }

          final profile = data.profile;
          final items = data.items;
          final completed =
              items.where((e) => e.status == MediaStatus.completed).toList();
          final topRated =
              items.where((e) => e.rating != null && e.rating! >= 7).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Avatar + Name
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 36)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.displayName ?? profile.username,
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(
                      '@${profile.username}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.textTertiary),
                    ),
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        profile.bio!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat(theme, '${items.length}', 'Items'),
                    _stat(theme, '${completed.length}', 'Completed'),
                    _stat(theme, '${topRated.length}', 'Top Rated'),
                  ],
                ),
              ),

              if (topRated.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Top Rated', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                ...topRated.take(5).map(
                      (item) => _publicItem(theme, item),
                    ),
              ],

              if (completed.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Recently Completed', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                ...completed.take(5).map(
                      (item) => _publicItem(theme, item),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _stat(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(color: AppColors.primaryLight)),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }

  Widget _publicItem(ThemeData theme, MediaItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.bodyMedium,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(item.type.label, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          if (item.rating != null)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${item.rating}',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _shimmerBody() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceLight,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: CircleAvatar(radius: 40, backgroundColor: AppColors.surface),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 120, height: 20,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ),
    );
  }
}
