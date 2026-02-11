import 'package:flutter/foundation.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/enums/media_status.dart';

@immutable
class MediaItem {
  final String id;
  final String? externalId;
  final String title;
  final String? description;
  final String? imageUrl;
  final DateTime? releaseDate;
  final MediaType type;
  final MediaStatus status;
  final int? rating;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MediaItem({
    required this.id,
    this.externalId,
    required this.title,
    this.description,
    this.imageUrl,
    this.releaseDate,
    required this.type,
    this.status = MediaStatus.watchlist,
    this.rating,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  MediaItem copyWith({
    String? title,
    String? externalId,
    String? description,
    String? imageUrl,
    DateTime? releaseDate,
    MediaType? type,
    MediaStatus? status,
    int? rating,
    String? note,
    DateTime? updatedAt,
  }) {
    return MediaItem(
      id: id,
      externalId: externalId ?? this.externalId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      type: type ?? this.type,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'externalId': externalId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'releaseDate': releaseDate?.toIso8601String(),
      'type': type.name,
      'status': status.name,
      'rating': rating,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      externalId: json['externalId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      releaseDate: json['releaseDate'] != null
          ? DateTime.parse(json['releaseDate'] as String)
          : null,
      type: MediaType.values.byName(json['type'] as String),
      status: MediaStatus.values.byName(json['status'] as String),
      rating: json['rating'] as int?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
