import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'user_recommendation.freezed.dart';
part 'user_recommendation.g.dart';

enum RecommendationType {
  workout,
  nutrition,
  lifestyle,
  goal,
}

@freezed
class UserRecommendation with _$UserRecommendation {
  const factory UserRecommendation({
    required String id,
    required String title,
    required String description,
    required RecommendationType type,
    required DateTime createdAt,
    required double confidenceScore,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    List<RecommendationAction>? actions,
  }) = _UserRecommendation;

  factory UserRecommendation.fromJson(Map<String, dynamic> json) => _$UserRecommendationFromJson(json);
}

@freezed
class RecommendationAction with _$RecommendationAction {
  const factory RecommendationAction({
    required String id,
    required String title,
    required String actionType,
    Map<String, dynamic>? parameters,
  }) = _RecommendationAction;

  factory RecommendationAction.fromJson(Map<String, dynamic> json) => _$RecommendationActionFromJson(json);
}