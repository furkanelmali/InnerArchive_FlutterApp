import 'package:flutter/material.dart';
import '../../../core/enums/media_status.dart';
import '../../../core/theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  final MediaStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color get _color {
    switch (status) {
      case MediaStatus.watchlist:
        return AppColors.primaryLight;
      case MediaStatus.inProgress:
        return const Color(0xFFFBBF24);
      case MediaStatus.completed:
        return const Color(0xFF34D399);
      case MediaStatus.dropped:
        return const Color(0xFFF87171);
    }
  }
}
