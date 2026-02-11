import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/stats_provider.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: stats.totalItems == 0
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart, size: 64,
                      color: AppColors.textTertiary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('No data yet', style: theme.textTheme.bodyMedium),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildOverviewCards(theme, stats),
                const SizedBox(height: 24),
                Text('By Type', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                ...stats.byType.entries.map(
                  (entry) => _buildTypeCard(theme, entry.key.label, entry.value),
                ),
                if (stats.recentlyAdded.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Recently Added', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...stats.recentlyAdded.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildRecentItem(theme, item.title, item.type.label),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildOverviewCards(ThemeData theme, MediaStats stats) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard(theme, 'Total', '${stats.totalItems}', Icons.layers),
        _statCard(theme, 'Completed',
            '${stats.completionRate.toStringAsFixed(0)}%', Icons.check_circle_outline),
        _statCard(theme, 'Avg Rating',
            stats.averageRating > 0
                ? stats.averageRating.toStringAsFixed(1)
                : '—',
            Icons.star_outline),
        _statCard(theme, 'Top Type',
            stats.mostConsumedType?.label ?? '—', Icons.trending_up),
      ],
    );
  }

  Widget _statCard(ThemeData theme, String label, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryLight),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildTypeCard(ThemeData theme, String label, TypeStats stats) {
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
                const SizedBox(height: 4),
                Text(
                  '${stats.total} total · ${stats.completed} done · ${stats.watchlist} queued',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              stats.averageRating > 0
                  ? stats.averageRating.toStringAsFixed(1)
                  : '—',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItem(ThemeData theme, String title, String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: theme.textTheme.bodyLarge,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text(type, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
