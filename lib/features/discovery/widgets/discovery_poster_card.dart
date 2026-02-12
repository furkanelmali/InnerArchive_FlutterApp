import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/discovery_media_model.dart';

class DiscoveryPosterCard extends StatefulWidget {
  final DiscoveryMedia item;
  final VoidCallback onTap;
  final double width;

  const DiscoveryPosterCard({
    super.key,
    required this.item,
    required this.onTap,
    this.width = 120,
  });

  @override
  State<DiscoveryPosterCard> createState() => _DiscoveryPosterCardState();
}

class _DiscoveryPosterCardState extends State<DiscoveryPosterCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final height = widget.width / (2 / 3);

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
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Hero(
                      tag: 'disc_${widget.item.type.name}_${widget.item.externalId}',
                      child: widget.item.posterUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.item.posterUrl!,
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
              if (widget.item.apiRating != null && widget.item.apiRating! > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 11, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          widget.item.apiRating!.toStringAsFixed(1),
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
