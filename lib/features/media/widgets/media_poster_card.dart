import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/enums/media_status.dart';
import '../../../core/theme/app_colors.dart';
import '../models/media_item.dart';

class MediaPosterCard extends StatefulWidget {
  final MediaItem item;
  final VoidCallback onTap;
  final double width;
  final double aspectRatio;

  const MediaPosterCard({
    super.key,
    required this.item,
    required this.onTap,
    this.width = 120,
    this.aspectRatio = 2 / 3,
  });

  @override
  State<MediaPosterCard> createState() => _MediaPosterCardState();
}

class _MediaPosterCardState extends State<MediaPosterCard> {
  double _scale = 1.0;

  Color _statusColor(MediaStatus status) {
    switch (status) {
      case MediaStatus.inProgress:
        return AppColors.primary;
      case MediaStatus.completed:
        return AppColors.success;
      case MediaStatus.watchlist:
        return AppColors.accent;
      case MediaStatus.dropped:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.width / widget.aspectRatio;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: widget.width,
          height: height,
          child: Stack(
            children: [
              // Poster
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.6),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Hero(
                      tag: 'poster_${widget.item.id}',
                      child: widget.item.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.item.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                color: AppColors.surfaceLight,
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, _, _) => _fallback(),
                            )
                          : _fallback(),
                    ),
                  ),
                ),
              ),

              // Rating badge
              if (widget.item.rating != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 11,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.item.rating}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Status dot
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor(widget.item.status),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor(widget.item.status)
                            .withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.surfaceLight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined,
              color: AppColors.textTertiary, size: 28),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              widget.item.title,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
