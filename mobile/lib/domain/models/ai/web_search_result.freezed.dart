// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'web_search_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WebSearchResult _$WebSearchResultFromJson(Map<String, dynamic> json) {
  return _WebSearchResult.fromJson(json);
}

/// @nodoc
mixin _$WebSearchResult {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get snippet => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  DateTime? get publishedDate => throw _privateConstructorUsedError;
  String? get sourceDisplayName => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WebSearchResultCopyWith<WebSearchResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WebSearchResultCopyWith<$Res> {
  factory $WebSearchResultCopyWith(
          WebSearchResult value, $Res Function(WebSearchResult) then) =
      _$WebSearchResultCopyWithImpl<$Res, WebSearchResult>;
  @useResult
  $Res call(
      {String id,
      String title,
      String snippet,
      String url,
      DateTime? publishedDate,
      String? sourceDisplayName,
      String? imageUrl,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$WebSearchResultCopyWithImpl<$Res, $Val extends WebSearchResult>
    implements $WebSearchResultCopyWith<$Res> {
  _$WebSearchResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? snippet = null,
    Object? url = null,
    Object? publishedDate = freezed,
    Object? sourceDisplayName = freezed,
    Object? imageUrl = freezed,
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
      snippet: null == snippet
          ? _value.snippet
          : snippet // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      publishedDate: freezed == publishedDate
          ? _value.publishedDate
          : publishedDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sourceDisplayName: freezed == sourceDisplayName
          ? _value.sourceDisplayName
          : sourceDisplayName // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WebSearchResultImplCopyWith<$Res>
    implements $WebSearchResultCopyWith<$Res> {
  factory _$$WebSearchResultImplCopyWith(_$WebSearchResultImpl value,
          $Res Function(_$WebSearchResultImpl) then) =
      __$$WebSearchResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String snippet,
      String url,
      DateTime? publishedDate,
      String? sourceDisplayName,
      String? imageUrl,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$WebSearchResultImplCopyWithImpl<$Res>
    extends _$WebSearchResultCopyWithImpl<$Res, _$WebSearchResultImpl>
    implements _$$WebSearchResultImplCopyWith<$Res> {
  __$$WebSearchResultImplCopyWithImpl(
      _$WebSearchResultImpl _value, $Res Function(_$WebSearchResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? snippet = null,
    Object? url = null,
    Object? publishedDate = freezed,
    Object? sourceDisplayName = freezed,
    Object? imageUrl = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$WebSearchResultImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      snippet: null == snippet
          ? _value.snippet
          : snippet // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      publishedDate: freezed == publishedDate
          ? _value.publishedDate
          : publishedDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sourceDisplayName: freezed == sourceDisplayName
          ? _value.sourceDisplayName
          : sourceDisplayName // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WebSearchResultImpl
    with DiagnosticableTreeMixin
    implements _WebSearchResult {
  const _$WebSearchResultImpl(
      {required this.id,
      required this.title,
      required this.snippet,
      required this.url,
      this.publishedDate,
      this.sourceDisplayName,
      this.imageUrl,
      final Map<String, dynamic>? metadata})
      : _metadata = metadata;

  factory _$WebSearchResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$WebSearchResultImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String snippet;
  @override
  final String url;
  @override
  final DateTime? publishedDate;
  @override
  final String? sourceDisplayName;
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

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'WebSearchResult(id: $id, title: $title, snippet: $snippet, url: $url, publishedDate: $publishedDate, sourceDisplayName: $sourceDisplayName, imageUrl: $imageUrl, metadata: $metadata)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'WebSearchResult'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('snippet', snippet))
      ..add(DiagnosticsProperty('url', url))
      ..add(DiagnosticsProperty('publishedDate', publishedDate))
      ..add(DiagnosticsProperty('sourceDisplayName', sourceDisplayName))
      ..add(DiagnosticsProperty('imageUrl', imageUrl))
      ..add(DiagnosticsProperty('metadata', metadata));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WebSearchResultImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.snippet, snippet) || other.snippet == snippet) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.publishedDate, publishedDate) ||
                other.publishedDate == publishedDate) &&
            (identical(other.sourceDisplayName, sourceDisplayName) ||
                other.sourceDisplayName == sourceDisplayName) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      snippet,
      url,
      publishedDate,
      sourceDisplayName,
      imageUrl,
      const DeepCollectionEquality().hash(_metadata));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WebSearchResultImplCopyWith<_$WebSearchResultImpl> get copyWith =>
      __$$WebSearchResultImplCopyWithImpl<_$WebSearchResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WebSearchResultImplToJson(
      this,
    );
  }
}

abstract class _WebSearchResult implements WebSearchResult {
  const factory _WebSearchResult(
      {required final String id,
      required final String title,
      required final String snippet,
      required final String url,
      final DateTime? publishedDate,
      final String? sourceDisplayName,
      final String? imageUrl,
      final Map<String, dynamic>? metadata}) = _$WebSearchResultImpl;

  factory _WebSearchResult.fromJson(Map<String, dynamic> json) =
      _$WebSearchResultImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get snippet;
  @override
  String get url;
  @override
  DateTime? get publishedDate;
  @override
  String? get sourceDisplayName;
  @override
  String? get imageUrl;
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(ignore: true)
  _$$WebSearchResultImplCopyWith<_$WebSearchResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WebSearchResponse _$WebSearchResponseFromJson(Map<String, dynamic> json) {
  return _WebSearchResponse.fromJson(json);
}

/// @nodoc
mixin _$WebSearchResponse {
  String get query => throw _privateConstructorUsedError;
  List<WebSearchResult> get results => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WebSearchResponseCopyWith<WebSearchResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WebSearchResponseCopyWith<$Res> {
  factory $WebSearchResponseCopyWith(
          WebSearchResponse value, $Res Function(WebSearchResponse) then) =
      _$WebSearchResponseCopyWithImpl<$Res, WebSearchResponse>;
  @useResult
  $Res call(
      {String query,
      List<WebSearchResult> results,
      DateTime timestamp,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$WebSearchResponseCopyWithImpl<$Res, $Val extends WebSearchResponse>
    implements $WebSearchResponseCopyWith<$Res> {
  _$WebSearchResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? results = null,
    Object? timestamp = null,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      results: null == results
          ? _value.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<WebSearchResult>,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WebSearchResponseImplCopyWith<$Res>
    implements $WebSearchResponseCopyWith<$Res> {
  factory _$$WebSearchResponseImplCopyWith(_$WebSearchResponseImpl value,
          $Res Function(_$WebSearchResponseImpl) then) =
      __$$WebSearchResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String query,
      List<WebSearchResult> results,
      DateTime timestamp,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$WebSearchResponseImplCopyWithImpl<$Res>
    extends _$WebSearchResponseCopyWithImpl<$Res, _$WebSearchResponseImpl>
    implements _$$WebSearchResponseImplCopyWith<$Res> {
  __$$WebSearchResponseImplCopyWithImpl(_$WebSearchResponseImpl _value,
      $Res Function(_$WebSearchResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? results = null,
    Object? timestamp = null,
    Object? metadata = freezed,
  }) {
    return _then(_$WebSearchResponseImpl(
      query: null == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String,
      results: null == results
          ? _value._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<WebSearchResult>,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WebSearchResponseImpl
    with DiagnosticableTreeMixin
    implements _WebSearchResponse {
  const _$WebSearchResponseImpl(
      {required this.query,
      required final List<WebSearchResult> results,
      required this.timestamp,
      final Map<String, dynamic>? metadata})
      : _results = results,
        _metadata = metadata;

  factory _$WebSearchResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$WebSearchResponseImplFromJson(json);

  @override
  final String query;
  final List<WebSearchResult> _results;
  @override
  List<WebSearchResult> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  final DateTime timestamp;
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
    return 'WebSearchResponse(query: $query, results: $results, timestamp: $timestamp, metadata: $metadata)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'WebSearchResponse'))
      ..add(DiagnosticsProperty('query', query))
      ..add(DiagnosticsProperty('results', results))
      ..add(DiagnosticsProperty('timestamp', timestamp))
      ..add(DiagnosticsProperty('metadata', metadata));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WebSearchResponseImpl &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      query,
      const DeepCollectionEquality().hash(_results),
      timestamp,
      const DeepCollectionEquality().hash(_metadata));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WebSearchResponseImplCopyWith<_$WebSearchResponseImpl> get copyWith =>
      __$$WebSearchResponseImplCopyWithImpl<_$WebSearchResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WebSearchResponseImplToJson(
      this,
    );
  }
}

abstract class _WebSearchResponse implements WebSearchResponse {
  const factory _WebSearchResponse(
      {required final String query,
      required final List<WebSearchResult> results,
      required final DateTime timestamp,
      final Map<String, dynamic>? metadata}) = _$WebSearchResponseImpl;

  factory _WebSearchResponse.fromJson(Map<String, dynamic> json) =
      _$WebSearchResponseImpl.fromJson;

  @override
  String get query;
  @override
  List<WebSearchResult> get results;
  @override
  DateTime get timestamp;
  @override
  Map<String, dynamic>? get metadata;
  @override
  @JsonKey(ignore: true)
  _$$WebSearchResponseImplCopyWith<_$WebSearchResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
