import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/stats_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final recommendations = ref.watch(recommendationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(theme, stats),
          const SizedBox(height: 24),
          Text('Media Breakdown', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...MediaType.values.map((type) {
            final typeStats = stats.byType[type];
            if (typeStats == null) return const SizedBox.shrink();
            return _buildTypeSection(theme, type.label, typeStats);
          }),
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('For You', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...recommendations.map(
              (rec) => _buildRecommendation(theme, rec),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, MediaStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inner Archive', style: theme.textTheme.titleLarge),
                  Text(
                    '${stats.totalItems} items tracked',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat(theme, '${stats.completedCount}', 'Done'),
              _miniStat(theme, '${stats.watchlistCount}', 'Queued'),
              _miniStat(theme, '${stats.inProgressCount}', 'Active'),
              _miniStat(
                theme,
                stats.averageRating > 0
                    ? stats.averageRating.toStringAsFixed(1)
                    : '—',
                'Avg',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }

  Widget _buildTypeSection(ThemeData theme, String label, TypeStats stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
                Text(label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _badge(theme, '${stats.total}', 'Total'),
                    const SizedBox(width: 12),
                    _badge(theme, '${stats.completed}', 'Done'),
                    const SizedBox(width: 12),
                    _badge(theme, '${stats.watchlist}', 'Queued'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                stats.averageRating > 0
                    ? stats.averageRating.toStringAsFixed(1)
                    : '—',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        )),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _buildRecommendation(ThemeData theme, Recommendation rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rec.reason, style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.primaryLight,
          )),
          const SizedBox(height: 8),
          ...rec.items.take(3).map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${item.title}',
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
