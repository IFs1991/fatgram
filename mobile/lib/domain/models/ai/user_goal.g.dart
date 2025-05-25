// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserGoalImpl _$$UserGoalImplFromJson(Map<String, dynamic> json) =>
    _$UserGoalImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$GoalTypeEnumMap, json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      targetDate: DateTime.parse(json['targetDate'] as String),
      status: $enumDecode(_$GoalStatusEnumMap, json['status']),
      targetValue: (json['targetValue'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      unit: json['unit'] as String?,
      milestones: (json['milestones'] as List<dynamic>?)
          ?.map((e) => GoalMilestone.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$UserGoalImplToJson(_$UserGoalImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'type': _$GoalTypeEnumMap[instance.type]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'targetDate': instance.targetDate.toIso8601String(),
      'status': _$GoalStatusEnumMap[instance.status]!,
      'targetValue': instance.targetValue,
      'currentValue': instance.currentValue,
      'unit': instance.unit,
      'milestones': instance.milestones,
      'metadata': instance.metadata,
    };

const _$GoalTypeEnumMap = {
  GoalType.fatLoss: 'fatLoss',
  GoalType.activityLevel: 'activityLevel',
  GoalType.consistencyStreak: 'consistencyStreak',
  GoalType.customMetric: 'customMetric',
};

const _$GoalStatusEnumMap = {
  GoalStatus.notStarted: 'notStarted',
  GoalStatus.inProgress: 'inProgress',
  GoalStatus.completed: 'completed',
  GoalStatus.cancelled: 'cancelled',
};

_$GoalMilestoneImpl _$$GoalMilestoneImplFromJson(Map<String, dynamic> json) =>
    _$GoalMilestoneImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      targetValue: (json['targetValue'] as num).toDouble(),
      status: $enumDecode(_$GoalStatusEnumMap, json['status']),
      targetDate: DateTime.parse(json['targetDate'] as String),
      currentValue: (json['currentValue'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$GoalMilestoneImplToJson(_$GoalMilestoneImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'targetValue': instance.targetValue,
      'status': _$GoalStatusEnumMap[instance.status]!,
      'targetDate': instance.targetDate.toIso8601String(),
      'currentValue': instance.currentValue,
    };
