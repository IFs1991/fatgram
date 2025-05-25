// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WebSearchResultImpl _$$WebSearchResultImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSearchResultImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      snippet: json['snippet'] as String,
      url: json['url'] as String,
      publishedDate: json['publishedDate'] == null
          ? null
          : DateTime.parse(json['publishedDate'] as String),
      sourceDisplayName: json['sourceDisplayName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$WebSearchResultImplToJson(
        _$WebSearchResultImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'snippet': instance.snippet,
      'url': instance.url,
      'publishedDate': instance.publishedDate?.toIso8601String(),
      'sourceDisplayName': instance.sourceDisplayName,
      'imageUrl': instance.imageUrl,
      'metadata': instance.metadata,
    };

_$WebSearchResponseImpl _$$WebSearchResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$WebSearchResponseImpl(
      query: json['query'] as String,
      results: (json['results'] as List<dynamic>)
          .map((e) => WebSearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$WebSearchResponseImplToJson(
        _$WebSearchResponseImpl instance) =>
    <String, dynamic>{
      'query': instance.query,
      'results': instance.results,
      'timestamp': instance.timestamp.toIso8601String(),
      'metadata': instance.metadata,
    };
