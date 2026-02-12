import 'package:flutter/foundation.dart';

@immutable
class TasteSummary {
  final String summary;
  final List<String> topGenres;
  final String suggestedFocus;
  final DateTime generatedAt;

  const TasteSummary({
    required this.summary,
    required this.topGenres,
    required this.suggestedFocus,
    required this.generatedAt,
  });

  factory TasteSummary.fromJson(Map<String, dynamic> json) {
    return TasteSummary(
      summary: json['summary'] as String? ?? '',
      topGenres: (json['topGenres'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      suggestedFocus: json['suggestedFocus'] as String? ?? '',
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'topGenres': topGenres,
      'suggestedFocus': suggestedFocus,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
