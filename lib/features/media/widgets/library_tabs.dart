import 'package:flutter/material.dart';
import '../../../core/enums/media_status.dart';
import '../../../core/theme/app_colors.dart';

class LibraryTabs extends StatelessWidget {
  final MediaStatus? selectedStatus;
  final ValueChanged<MediaStatus?> onStatusChanged;

  const LibraryTabs({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  static const _tabs = [
    (null, 'All'),
    (MediaStatus.watchlist, 'Watchlist'),
    (MediaStatus.inProgress, 'In Progress'),
    (MediaStatus.completed, 'Completed'),
    (MediaStatus.dropped, 'Dropped'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: _tabs.map((tab) {
          final (status, label) = tab;
          final selected = selectedStatus == status;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onStatusChanged(status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.primaryLight : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
