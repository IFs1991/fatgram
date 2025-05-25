import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'user_goal.freezed.dart';
part 'user_goal.g.dart';

enum GoalStatus {
  notStarted,
  inProgress,
  completed,
  cancelled,
}

enum GoalType {
  fatLoss,
  activityLevel,
  consistencyStreak,
  customMetric,
}

@freezed
class UserGoal with _$UserGoal {
  const factory UserGoal({
    required String id,
    required String title,
    required String description,
    required GoalType type,
    required DateTime createdAt,
    required DateTime targetDate,
    required GoalStatus status,
    required double targetValue,
    required double currentValue,
    String? unit,
    List<GoalMilestone>? milestones,
    Map<String, dynamic>? metadata,
  }) = _UserGoal;

  factory UserGoal.fromJson(Map<String, dynamic> json) => _$UserGoalFromJson(json);
}

@freezed
class GoalMilestone with _$GoalMilestone {
  const factory GoalMilestone({
    required String id,
    required String title,
    required double targetValue,
    required GoalStatus status,
    required DateTime targetDate,
    double? currentValue,
  }) = _GoalMilestone;

  factory GoalMilestone.fromJson(Map<String, dynamic> json) => _$GoalMilestoneFromJson(json);
}