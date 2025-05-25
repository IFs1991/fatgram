// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_recommendation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserRecommendationImpl _$$UserRecommendationImplFromJson(
        Map<String, dynamic> json) =>
    _$UserRecommendationImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$RecommendationTypeEnumMap, json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => RecommendationAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$UserRecommendationImplToJson(
        _$UserRecommendationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': _$RecommendationTypeEnumMap[instance.type]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'confidenceScore': instance.confidenceScore,
      'imageUrl': instance.imageUrl,
      'metadata': instance.metadata,
      'tags': instance.tags,
      'actions': instance.actions,
    };

const _$RecommendationTypeEnumMap = {
  RecommendationType.workout: 'workout',
  RecommendationType.nutrition: 'nutrition',
  RecommendationType.lifestyle: 'lifestyle',
  RecommendationType.goal: 'goal',
};

_$RecommendationActionImpl _$$RecommendationActionImplFromJson(
        Map<String, dynamic> json) =>
    _$RecommendationActionImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      actionType: json['actionType'] as String,
      parameters: json['parameters'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$RecommendationActionImplToJson(
        _$RecommendationActionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'actionType': instance.actionType,
      'parameters': instance.parameters,
    };
