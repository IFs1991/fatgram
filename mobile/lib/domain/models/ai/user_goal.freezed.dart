// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_goal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserGoal _$UserGoalFromJson(Map<String, dynamic> json) {
  return _UserGoal.fromJson(json);
}

/// @nodoc
mixin _$UserGoal {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  GoalType get type => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get targetDate => throw _privateConstructorUsedError;
  GoalStatus get status => throw _privateConstructorUsedError;
  double get targetValue => throw _privateConstructorUsedError;
  double get currentValue => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;
  List<GoalMilestone>? get milestones => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserGoalCopyWith<UserGoal> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserGoalCopyWith<$Res> {
  factory $UserGoalCopyWith(UserGoal value, $Res Function(UserGoal) then) =
      _$UserGoalCopyWithImpl<$Res, UserGoal>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      GoalType type,
      DateTime createdAt,
      DateTime targetDate,
      GoalStatus status,
      double targetValue,
      double currentValue,
      String? unit,
      List<GoalMilestone>? milestones,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$UserGoalCopyWithImpl<$Res, $Val extends UserGoal>
    implements $UserGoalCopyWith<$Res> {
  _$UserGoalCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? createdAt = null,
    Object? targetDate = null,
    Object? status = null,
    Object? targetValue = null,
    Object? currentValue = null,
    Object? unit = freezed,
    Object? milestones = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as GoalType,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      targetDate: null == targetDate
          ? _value.targetDate
          : targetDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GoalStatus,
      targetValue: null == targetValue
          ? _value.targetValue
          : targetValue // ignore: cast_nullable_to_non_nullable
              as double,
      currentValue: null == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      milestones: freezed == milestones
          ? _value.milestones
          : milestones // ignore: cast_nullable_to_non_nullable
              as List<GoalMilestone>?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserGoalImplCopyWith<$Res>
    implements $UserGoalCopyWith<$Res> {
  factory _$$UserGoalImplCopyWith(
          _$UserGoalImpl value, $Res Function(_$UserGoalImpl) then) =
      __$$UserGoalImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      GoalType type,
      DateTime createdAt,
      DateTime targetDate,
      GoalStatus status,
      double targetValue,
      double currentValue,
      String? unit,
      List<GoalMilestone>? milestones,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$UserGoalImplCopyWithImpl<$Res>
    extends _$UserGoalCopyWithImpl<$Res, _$UserGoalImpl>
    implements _$$UserGoalImplCopyWith<$Res> {
  __$$UserGoalImplCopyWithImpl(
      _$UserGoalImpl _value, $Res Function(_$UserGoalImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? createdAt = null,
    Object? targetDate = null,
    Object? status = null,
    Object? targetValue = null,
    Object? currentValue = null,
    Object? unit = freezed,
    Object? milestones = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$UserGoalImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as GoalType,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      targetDate: null == targetDate
          ? _value.targetDate
          : targetDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GoalStatus,
      targetValue: null == targetValue
          ? _value.targetValue
          : targetValue // ignore: cast_nullable_to_non_nullable
              as double,
      currentValue: null == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      milestones: freezed == milestones
          ? _value._milestones
          : milestones // ignore: cast_nullable_to_non_nullable
              as List<GoalMilestone>?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserGoalImpl with DiagnosticableTreeMixin implements _UserGoal {
  const _$UserGoalImpl(
      {required this.id,
      required this.title,
      required this.description,
      required this.type,
      required this.createdAt,
      required this.targetDate,
      required this.status,
      required this.targetValue,
      required this.currentValue,
      this.unit,
      final List<GoalMilestone>? milestones,
      final Map<String, dynamic>? metadata})
      : _milestones = milestones,
        _metadata = metadata;

  factory _$UserGoalImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserGoalImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final GoalType type;
  @override
  final DateTime createdAt;
  @override
  final DateTime targetDate;
  @override
  final GoalStatus status;
  @override
  final double targetValue;
  @override
  final double currentValue;
  @override
  final String? unit;
  final List<GoalMilestone>? _milestones;
  @override
  List<GoalMilestone>? get milestones {
    final value = _milestones;
    if (value == null) return null;
    if (_milestones is EqualUnmodifiableListView) return _milestones;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UserGoal(id: $id, title: $title, description: $description, type: $type, createdAt: $createdAt, targetDate: $targetDate, status: $status, targetValue: $targetValue, currentValue: $currentValue, unit: $unit, milestones: $milestones, metadata: $metadata)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'UserGoal'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('createdAt', createdAt))
      ..add(DiagnosticsProperty('targetDate', targetDate))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('targetValue', targetValue))
      ..add(DiagnosticsProperty('currentValue', currentValue))
      ..add(DiagnosticsProperty('unit', unit))
      ..add(DiagnosticsProperty('milestones', milestones))
      ..add(DiagnosticsProperty('metadata', metadata));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserGoalImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.targetDate, targetDate) ||
                other.targetDate == targetDate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.targetValue, targetValue) ||
                other.targetValue == targetValue) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            const DeepCollectionEquality()
                .equals(other._milestones, _milestones) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      type,
      createdAt,
      targetDate,
      status,
      targetValue,
      currentValue,
      unit,
      const DeepCollectionEquality().hash(_milestones),
      const DeepCollectionEquality().hash(_metadata));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserGoalImplCopyWith<_$UserGoalImpl> get copyWith =>
      __$$UserGoalImplCopyWithImpl<_$UserGoalImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserGoalImplToJson(
      this,
    );
  }
}

abstract class _UserGoal implements UserGoal {
  const factory _UserGoal(
      {required final String id,
      required final String title,
      required final String description,
      required final GoalType type,
      required final DateTime createdAt,
      required final DateTime targetDate,
      required final GoalStatus status,
      required final double targetValue,
      required final double currentValue,
      final String? unit,
      final List<GoalMilestone>? milestones,
      final Map<String, dynamic>? metadata}) = _$UserGoalImpl;

  factory _UserGoal.fromJson(Map<String, dynamic> json) =
      _$UserGoalImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  GoalType get type;
  @override
  DateTime get createdAt;
  @override
  DateTime get targetDate;
  @override
  GoalStatus get status;
  @override
  double get targetValue;
  @override
  double get currentValue;
  @override
  String? get unit;
  @override
  List<GoalMilestone>? get milestones;
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(ignore: true)
  _$$UserGoalImplCopyWith<_$UserGoalImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GoalMilestone _$GoalMilestoneFromJson(Map<String, dynamic> json) {
  return _GoalMilestone.fromJson(json);
}

/// @nodoc
mixin _$GoalMilestone {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  double get targetValue => throw _privateConstructorUsedError;
  GoalStatus get status => throw _privateConstructorUsedError;
  DateTime get targetDate => throw _privateConstructorUsedError;
  double? get currentValue => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GoalMilestoneCopyWith<GoalMilestone> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoalMilestoneCopyWith<$Res> {
  factory $GoalMilestoneCopyWith(
          GoalMilestone value, $Res Function(GoalMilestone) then) =
      _$GoalMilestoneCopyWithImpl<$Res, GoalMilestone>;
  @useResult
  $Res call(
      {String id,
      String title,
      double targetValue,
      GoalStatus status,
      DateTime targetDate,
      double? currentValue});
}

/// @nodoc
class _$GoalMilestoneCopyWithImpl<$Res, $Val extends GoalMilestone>
    implements $GoalMilestoneCopyWith<$Res> {
  _$GoalMilestoneCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? targetValue = null,
    Object? status = null,
    Object? targetDate = null,
    Object? currentValue = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      targetValue: null == targetValue
          ? _value.targetValue
          : targetValue // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GoalStatus,
      targetDate: null == targetDate
          ? _value.targetDate
          : targetDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      currentValue: freezed == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GoalMilestoneImplCopyWith<$Res>
    implements $GoalMilestoneCopyWith<$Res> {
  factory _$$GoalMilestoneImplCopyWith(
          _$GoalMilestoneImpl value, $Res Function(_$GoalMilestoneImpl) then) =
      __$$GoalMilestoneImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      double targetValue,
      GoalStatus status,
      DateTime targetDate,
      double? currentValue});
}

/// @nodoc
class __$$GoalMilestoneImplCopyWithImpl<$Res>
    extends _$GoalMilestoneCopyWithImpl<$Res, _$GoalMilestoneImpl>
    implements _$$GoalMilestoneImplCopyWith<$Res> {
  __$$GoalMilestoneImplCopyWithImpl(
      _$GoalMilestoneImpl _value, $Res Function(_$GoalMilestoneImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? targetValue = null,
    Object? status = null,
    Object? targetDate = null,
    Object? currentValue = freezed,
  }) {
    return _then(_$GoalMilestoneImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      targetValue: null == targetValue
          ? _value.targetValue
          : targetValue // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GoalStatus,
      targetDate: null == targetDate
          ? _value.targetDate
          : targetDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      currentValue: freezed == currentValue
          ? _value.currentValue
          : currentValue // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GoalMilestoneImpl
    with DiagnosticableTreeMixin
    implements _GoalMilestone {
  const _$GoalMilestoneImpl(
      {required this.id,
      required this.title,
      required this.targetValue,
      required this.status,
      required this.targetDate,
      this.currentValue});

  factory _$GoalMilestoneImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoalMilestoneImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final double targetValue;
  @override
  final GoalStatus status;
  @override
  final DateTime targetDate;
  @override
  final double? currentValue;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'GoalMilestone(id: $id, title: $title, targetValue: $targetValue, status: $status, targetDate: $targetDate, currentValue: $currentValue)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'GoalMilestone'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('targetValue', targetValue))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('targetDate', targetDate))
      ..add(DiagnosticsProperty('currentValue', currentValue));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalMilestoneImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.targetValue, targetValue) ||
                other.targetValue == targetValue) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.targetDate, targetDate) ||
                other.targetDate == targetDate) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, title, targetValue, status, targetDate, currentValue);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalMilestoneImplCopyWith<_$GoalMilestoneImpl> get copyWith =>
      __$$GoalMilestoneImplCopyWithImpl<_$GoalMilestoneImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GoalMilestoneImplToJson(
      this,
    );
  }
}

abstract class _GoalMilestone implements GoalMilestone {
  const factory _GoalMilestone(
      {required final String id,
      required final String title,
      required final double targetValue,
      required final GoalStatus status,
      required final DateTime targetDate,
      final double? currentValue}) = _$GoalMilestoneImpl;

  factory _GoalMilestone.fromJson(Map<String, dynamic> json) =
      _$GoalMilestoneImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  double get targetValue;
  @override
  GoalStatus get status;
  @override
  DateTime get targetDate;
  @override
  double? get currentValue;
  @override
  @JsonKey(ignore: true)
  _$$GoalMilestoneImplCopyWith<_$GoalMilestoneImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
