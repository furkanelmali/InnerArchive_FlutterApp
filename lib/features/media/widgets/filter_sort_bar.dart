import 'package:flutter/material.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/filter_provider.dart';

class FilterSortBar extends StatelessWidget {
  final FilterState filter;
  final ValueChanged<MediaType?> onTypeChanged;
  final ValueChanged<SortField> onSortChanged;

  const FilterSortBar({
    super.key,
    required this.filter,
    required this.onTypeChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          _chip(
            label: 'All',
            selected: filter.type == null,
            onTap: () => onTypeChanged(null),
          ),
          const SizedBox(width: 6),
          ...MediaType.values.map((type) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _chip(
              label: type.label,
              selected: filter.type == type,
              onTap: () => onTypeChanged(type),
            ),
          )),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: AppColors.border),
          const SizedBox(width: 8),
          ...SortField.values.map((field) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _sortChip(field),
          )),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _sortChip(SortField field) {
    final selected = filter.sortField == field;
    final label = switch (field) {
      SortField.title => 'A–Z',
      SortField.rating => 'Rating',
      SortField.createdAt => 'Added',
      SortField.updatedAt => 'Updated',
    };

    return GestureDetector(
      onTap: () => onSortChanged(field),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryLight.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primaryLight : AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              Icon(
                filter.sortDirection == SortDirection.asc
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 14,
                color: AppColors.primaryLight,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
