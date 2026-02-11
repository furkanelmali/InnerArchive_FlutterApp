import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/enums/media_status.dart';
import '../models/media_item.dart';

enum SortField { title, rating, createdAt, updatedAt }

enum SortDirection { asc, desc }

class FilterState {
  final MediaType? type;
  final MediaStatus? status;
  final SortField sortField;
  final SortDirection sortDirection;

  const FilterState({
    this.type,
    this.status,
    this.sortField = SortField.updatedAt,
    this.sortDirection = SortDirection.desc,
  });

  FilterState copyWith({
    MediaType? Function()? type,
    MediaStatus? Function()? status,
    SortField? sortField,
    SortDirection? sortDirection,
  }) {
    return FilterState(
      type: type != null ? type() : this.type,
      status: status != null ? status() : this.status,
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(
  FilterNotifier.new,
);

class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  void setType(MediaType? type) {
    state = state.copyWith(type: () => type);
  }

  void setStatus(MediaStatus? status) {
    state = state.copyWith(status: () => status);
  }

  void setSort(SortField field) {
    if (state.sortField == field) {
      state = state.copyWith(
        sortDirection: state.sortDirection == SortDirection.asc
            ? SortDirection.desc
            : SortDirection.asc,
      );
    } else {
      state = state.copyWith(
        sortField: field,
        sortDirection: SortDirection.desc,
      );
    }
  }
}

List<MediaItem> applyFilters(List<MediaItem> items, FilterState filter) {
  var result = [...items];

  if (filter.type != null) {
    result = result.where((e) => e.type == filter.type).toList();
  }
  if (filter.status != null) {
    result = result.where((e) => e.status == filter.status).toList();
  }

  result.sort((a, b) {
    int compare;
    switch (filter.sortField) {
      case SortField.title:
        compare = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        break;
      case SortField.rating:
        compare = (a.rating ?? 0).compareTo(b.rating ?? 0);
        break;
      case SortField.createdAt:
        compare = a.createdAt.compareTo(b.createdAt);
        break;
      case SortField.updatedAt:
        compare = a.updatedAt.compareTo(b.updatedAt);
        break;
    }
    return filter.sortDirection == SortDirection.asc ? compare : -compare;
  });

  return result;
}
