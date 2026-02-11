import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/media_item.dart';
import 'status_chip.dart';

class MediaCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onTap;
  final VoidCallback? onDismissed;

  const MediaCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 74,
                  child: item.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              Container(color: AppColors.surfaceLight),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          item.type.label,
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(width: 10),
                        StatusChip(status: item.status),
                      ],
                    ),
                  ],
                ),
              ),
              if (item.rating != null) ...[
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${item.rating}',
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _posterFallback() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textTertiary,
        size: 22,
      ),
    );
  }
}
