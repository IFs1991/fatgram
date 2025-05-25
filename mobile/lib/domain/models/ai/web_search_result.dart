import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'web_search_result.freezed.dart';
part 'web_search_result.g.dart';

@freezed
class WebSearchResult with _$WebSearchResult {
  const factory WebSearchResult({
    required String id,
    required String title,
    required String snippet,
    required String url,
    DateTime? publishedDate,
    String? sourceDisplayName,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) = _WebSearchResult;

  factory WebSearchResult.fromJson(Map<String, dynamic> json) => _$WebSearchResultFromJson(json);
}

@freezed
class WebSearchResponse with _$WebSearchResponse {
  const factory WebSearchResponse({
    required String query,
    required List<WebSearchResult> results,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) = _WebSearchResponse;

  factory WebSearchResponse.fromJson(Map<String, dynamic> json) => _$WebSearchResponseFromJson(json);
}