// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_recommendation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserRecommendation _$UserRecommendationFromJson(Map<String, dynamic> json) {
  return _UserRecommendation.fromJson(json);
}

/// @nodoc
mixin _$UserRecommendation {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  RecommendationType get type => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  double get confidenceScore => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  List<String>? get tags => throw _privateConstructorUsedError;
  List<RecommendationAction>? get actions => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserRecommendationCopyWith<UserRecommendation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserRecommendationCopyWith<$Res> {
  factory $UserRecommendationCopyWith(
          UserRecommendation value, $Res Function(UserRecommendation) then) =
      _$UserRecommendationCopyWithImpl<$Res, UserRecommendation>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      RecommendationType type,
      DateTime createdAt,
      double confidenceScore,
      String? imageUrl,
      Map<String, dynamic>? metadata,
      List<String>? tags,
      List<RecommendationAction>? actions});
}

/// @nodoc
class _$UserRecommendationCopyWithImpl<$Res, $Val extends UserRecommendation>
    implements $UserRecommendationCopyWith<$Res> {
  _$UserRecommendationCopyWithImpl(this._value, this._then);

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
    Object? confidenceScore = null,
    Object? imageUrl = freezed,
    Object? metadata = freezed,
    Object? tags = freezed,
    Object? actions = freezed,
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
              as RecommendationType,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      confidenceScore: null == confidenceScore
          ? _value.confidenceScore
          : confidenceScore // ignore: cast_nullable_to_non_nullable
              as double,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      tags: freezed == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      actions: freezed == actions
          ? _value.actions
          : actions // ignore: cast_nullable_to_non_nullable
              as List<RecommendationAction>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserRecommendationImplCopyWith<$Res>
    implements $UserRecommendationCopyWith<$Res> {
  factory _$$UserRecommendationImplCopyWith(_$UserRecommendationImpl value,
          $Res Function(_$UserRecommendationImpl) then) =
      __$$UserRecommendationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      RecommendationType type,
      DateTime createdAt,
      double confidenceScore,
      String? imageUrl,
      Map<String, dynamic>? metadata,
      List<String>? tags,
      List<RecommendationAction>? actions});
}

/// @nodoc
class __$$UserRecommendationImplCopyWithImpl<$Res>
    extends _$UserRecommendationCopyWithImpl<$Res, _$UserRecommendationImpl>
    implements _$$UserRecommendationImplCopyWith<$Res> {
  __$$UserRecommendationImplCopyWithImpl(_$UserRecommendationImpl _value,
      $Res Function(_$UserRecommendationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? type = null,
    Object? createdAt = null,
    Object? confidenceScore = null,
    Object? imageUrl = freezed,
    Object? metadata = freezed,
    Object? tags = freezed,
    Object? actions = freezed,
  }) {
    return _then(_$UserRecommendationImpl(
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
              as RecommendationType,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      confidenceScore: null == confidenceScore
          ? _value.confidenceScore
          : confidenceScore // ignore: cast_nullable_to_non_nullable
              as double,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      tags: freezed == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      actions: freezed == actions
          ? _value._actions
          : actions // ignore: cast_nullable_to_non_nullable
              as List<RecommendationAction>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserRecommendationImpl
    with DiagnosticableTreeMixin
    implements _UserRecommendation {
  const _$UserRecommendationImpl(
      {required this.id,
      required this.title,
      required this.description,
      required this.type,
      required this.createdAt,
      required this.confidenceScore,
      this.imageUrl,
      final Map<String, dynamic>? metadata,
      final List<String>? tags,
      final List<RecommendationAction>? actions})
      : _metadata = metadata,
        _tags = tags,
        _actions = actions;

  factory _$UserRecommendationImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserRecommendationImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final RecommendationType type;
  @override
  final DateTime createdAt;
  @override
  final double confidenceScore;
  @override
  final String? imageUrl;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<RecommendationAction>? _actions;
  @override
  List<RecommendationAction>? get actions {
    final value = _actions;
    if (value == null) return null;
    if (_actions is EqualUnmodifiableListView) return _actions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'UserRecommendation(id: $id, title: $title, description: $description, type: $type, createdAt: $createdAt, confidenceScore: $confidenceScore, imageUrl: $imageUrl, metadata: $metadata, tags: $tags, actions: $actions)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'UserRecommendation'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('createdAt', createdAt))
      ..add(DiagnosticsProperty('confidenceScore', confidenceScore))
      ..add(DiagnosticsProperty('imageUrl', imageUrl))
      ..add(DiagnosticsProperty('metadata', metadata))
      ..add(DiagnosticsProperty('tags', tags))
      ..add(DiagnosticsProperty('actions', actions));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserRecommendationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.confidenceScore, confidenceScore) ||
                other.confidenceScore == confidenceScore) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality().equals(other._actions, _actions));
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
      confidenceScore,
      imageUrl,
      const DeepCollectionEquality().hash(_metadata),
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_actions));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserRecommendationImplCopyWith<_$UserRecommendationImpl> get copyWith =>
      __$$UserRecommendationImplCopyWithImpl<_$UserRecommendationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserRecommendationImplToJson(
      this,
    );
  }
}

abstract class _UserRecommendation implements UserRecommendation {
  const factory _UserRecommendation(
      {required final String id,
      required final String title,
      required final String description,
      required final RecommendationType type,
      required final DateTime createdAt,
      required final double confidenceScore,
      final String? imageUrl,
      final Map<String, dynamic>? metadata,
      final List<String>? tags,
      final List<RecommendationAction>? actions}) = _$UserRecommendationImpl;

  factory _UserRecommendation.fromJson(Map<String, dynamic> json) =
      _$UserRecommendationImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  RecommendationType get type;
  @override
  DateTime get createdAt;
  @override
  double get confidenceScore;
  @override
  String? get imageUrl;
  @override
  Map<String, dynamic>? get metadata;
  @override
  List<String>? get tags;
  @override
  List<RecommendationAction>? get actions;
  @override
  @JsonKey(ignore: true)
  _$$UserRecommendationImplCopyWith<_$UserRecommendationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecommendationAction _$RecommendationActionFromJson(Map<String, dynamic> json) {
  return _RecommendationAction.fromJson(json);
}

/// @nodoc
mixin _$RecommendationAction {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get actionType => throw _privateConstructorUsedError;
  Map<String, dynamic>? get parameters => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecommendationActionCopyWith<RecommendationAction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecommendationActionCopyWith<$Res> {
  factory $RecommendationActionCopyWith(RecommendationAction value,
          $Res Function(RecommendationAction) then) =
      _$RecommendationActionCopyWithImpl<$Res, RecommendationAction>;
  @useResult
  $Res call(
      {String id,
      String title,
      String actionType,
      Map<String, dynamic>? parameters});
}

/// @nodoc
class _$RecommendationActionCopyWithImpl<$Res,
        $Val extends RecommendationAction>
    implements $RecommendationActionCopyWith<$Res> {
  _$RecommendationActionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? actionType = null,
    Object? parameters = freezed,
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
      actionType: null == actionType
          ? _value.actionType
          : actionType // ignore: cast_nullable_to_non_nullable
              as String,
      parameters: freezed == parameters
          ? _value.parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecommendationActionImplCopyWith<$Res>
    implements $RecommendationActionCopyWith<$Res> {
  factory _$$RecommendationActionImplCopyWith(_$RecommendationActionImpl value,
          $Res Function(_$RecommendationActionImpl) then) =
      __$$RecommendationActionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String actionType,
      Map<String, dynamic>? parameters});
}

/// @nodoc
class __$$RecommendationActionImplCopyWithImpl<$Res>
    extends _$RecommendationActionCopyWithImpl<$Res, _$RecommendationActionImpl>
    implements _$$RecommendationActionImplCopyWith<$Res> {
  __$$RecommendationActionImplCopyWithImpl(_$RecommendationActionImpl _value,
      $Res Function(_$RecommendationActionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? actionType = null,
    Object? parameters = freezed,
  }) {
    return _then(_$RecommendationActionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      actionType: null == actionType
          ? _value.actionType
          : actionType // ignore: cast_nullable_to_non_nullable
              as String,
      parameters: freezed == parameters
          ? _value._parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecommendationActionImpl
    with DiagnosticableTreeMixin
    implements _RecommendationAction {
  const _$RecommendationActionImpl(
      {required this.id,
      required this.title,
      required this.actionType,
      final Map<String, dynamic>? parameters})
      : _parameters = parameters;

  factory _$RecommendationActionImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecommendationActionImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String actionType;
  final Map<String, dynamic>? _parameters;
  @override
  Map<String, dynamic>? get parameters {
    final value = _parameters;
    if (value == null) return null;
    if (_parameters is EqualUnmodifiableMapView) return _parameters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'RecommendationAction(id: $id, title: $title, actionType: $actionType, parameters: $parameters)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'RecommendationAction'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('actionType', actionType))
      ..add(DiagnosticsProperty('parameters', parameters));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecommendationActionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.actionType, actionType) ||
                other.actionType == actionType) &&
            const DeepCollectionEquality()
                .equals(other._parameters, _parameters));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, actionType,
      const DeepCollectionEquality().hash(_parameters));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecommendationActionImplCopyWith<_$RecommendationActionImpl>
      get copyWith =>
          __$$RecommendationActionImplCopyWithImpl<_$RecommendationActionImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecommendationActionImplToJson(
      this,
    );
  }
}

abstract class _RecommendationAction implements RecommendationAction {
  const factory _RecommendationAction(
      {required final String id,
      required final String title,
      required final String actionType,
      final Map<String, dynamic>? parameters}) = _$RecommendationActionImpl;

  factory _RecommendationAction.fromJson(Map<String, dynamic> json) =
      _$RecommendationActionImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get actionType;
  @override
  Map<String, dynamic>? get parameters;
  @override
  @JsonKey(ignore: true)
  _$$RecommendationActionImplCopyWith<_$RecommendationActionImpl>
      get copyWith => throw _privateConstructorUsedError;
}
