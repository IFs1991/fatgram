// import 'dart:io'; // 未使用のため削除
import 'package:dio/dio.dart';
import 'package:fatgram/core/security/api_key_manager.dart';
import 'package:fatgram/core/error/exceptions.dart';
import 'package:logger/logger.dart';

/// APIリクエストログエントリ
class ApiRequestLog {
  final String url;
  final String method;
  final int? statusCode;
  final DateTime timestamp;
  final Duration duration;
  final String? error;
  final ApiProvider provider;

  const ApiRequestLog({
    required this.url,
    required this.method,
    required this.timestamp,
    required this.duration,
    required this.provider,
    this.statusCode,
    this.error,
  });

  @override
  String toString() {
    final maskedUrl = _maskSensitiveInfo(url);
    return 'ApiRequestLog(url: $maskedUrl, method: $method, '
           'status: $statusCode, duration: ${duration.inMilliseconds}ms, '
           'provider: ${provider.name}, error: $error)';
  }

  /// センシティブ情報をマスク
  String _maskSensitiveInfo(String input) {
    // APIキーやトークンなどをマスク
    return input
        .replaceAllMapped(RegExp(r'(api[_-]?key|token|secret)=([^&\s]+)', caseSensitive: false),
          (match) => '${match.group(1)}=***')
        .replaceAllMapped(RegExp(r'Bearer\s+([^\s]+)', caseSensitive: false),
          (match) => 'Bearer ***');
  }
}

/// レート制限管理クラス
class RateLimiter {
  final Map<ApiProvider, List<DateTime>> _requestTimes = {};
  final Map<ApiProvider, int> _rateLimits = {};

  /// レート制限を設定
  void setRateLimit(ApiProvider provider, int requestsPerMinute) {
    _rateLimits[provider] = requestsPerMinute;
    _requestTimes[provider] = [];
  }

  /// レート制限をチェック
  bool canMakeRequest(ApiProvider provider) {
    final rateLimit = _rateLimits[provider];
    if (rateLimit == null) return true;

    final now = DateTime.now();
    final requests = _requestTimes[provider] ?? [];

    // 1分以内のリクエストをフィルタ
    final recentRequests = requests
        .where((time) => now.difference(time).inMinutes < 1)
        .toList();

    return recentRequests.length < rateLimit;
  }

  /// リクエストを記録
  void recordRequest(ApiProvider provider) {
    final now = DateTime.now();
    _requestTimes[provider] = (_requestTimes[provider] ?? [])..add(now);

    // 古いリクエスト記録を削除（メモリ効率のため）
    _requestTimes[provider] = _requestTimes[provider]!
        .where((time) => now.difference(time).inMinutes < 2)
        .toList();
  }

  /// レート制限をリセット
  void resetRateLimit(ApiProvider provider) {
    _requestTimes[provider] = [];
  }
}

/// セキュアAPIクライアント
class SecureApiClient {
  final Dio _dio;
  final ApiKeyManager _apiKeyManager;
  final Logger _logger;
  final RateLimiter _rateLimiter;

  // ログ保持設定
  static const int _maxLogsPerProvider = 100;
  final Map<ApiProvider, List<ApiRequestLog>> _requestLogs = {};

  bool _isInitialized = false;

  SecureApiClient({
    required Dio dio,
    required ApiKeyManager apiKeyManager,
    Logger? logger,
  }) : _dio = dio,
       _apiKeyManager = apiKeyManager,
       _logger = logger ?? Logger(),
       _rateLimiter = RateLimiter() {
    _setupInterceptors();
  }

  /// 初期化状態
  bool get isInitialized => _isInitialized;

  /// SecureApiClientの初期化
  Future<void> initialize() async {
    try {
      await _apiKeyManager.initialize();
      _isInitialized = true;
      _logger.i('SecureApiClient: Initialized successfully');
    } catch (e) {
      _logger.e('SecureApiClient: Initialization failed: $e');
      rethrow;
    }
  }

  /// APIキーを設定
  Future<void> setApiKey(ApiProvider provider, String apiKey) async {
    _checkInitialized();

    if (apiKey.isEmpty) {
      throw const ValidationException(
        message: 'API key cannot be empty',
        code: 'EMPTY_API_KEY',
      );
    }

    await _apiKeyManager.storeApiKey(provider, apiKey);
  }

  /// APIキーを取得
  Future<String> getApiKey(ApiProvider provider) async {
    _checkInitialized();
    return await _apiKeyManager.getApiKey(provider);
  }

  /// レート制限を設定
  void setRateLimit(ApiProvider provider, int requestsPerMinute) {
    _rateLimiter.setRateLimit(provider, requestsPerMinute);
  }

  /// レート制限をリセット
  void resetRateLimit(ApiProvider provider) {
    _rateLimiter.resetRateLimit(provider);
  }

  /// APIキーをリフレッシュ
  Future<String> refreshApiKey(ApiProvider provider) async {
    _checkInitialized();
    return await _apiKeyManager.refreshApiKey(provider);
  }

  /// GETリクエスト
  Future<Response<dynamic>> get(
    String path, {
    required ApiProvider apiProvider,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool enableAutoRefresh = false,
  }) async {
    return await _makeRequest(
      () => _dio.get(path, queryParameters: queryParameters, options: options),
      apiProvider,
      'GET',
      path,
      enableAutoRefresh: enableAutoRefresh,
    );
  }

  /// POSTリクエスト
  Future<Response<dynamic>> post(
    String path, {
    required ApiProvider apiProvider,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool enableAutoRefresh = false,
  }) async {
    return await _makeRequest(
      () => _dio.post(path, data: data, queryParameters: queryParameters, options: options),
      apiProvider,
      'POST',
      path,
      enableAutoRefresh: enableAutoRefresh,
    );
  }

  /// PUTリクエスト
  Future<Response<dynamic>> put(
    String path, {
    required ApiProvider apiProvider,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool enableAutoRefresh = false,
  }) async {
    return await _makeRequest(
      () => _dio.put(path, data: data, queryParameters: queryParameters, options: options),
      apiProvider,
      'PUT',
      path,
      enableAutoRefresh: enableAutoRefresh,
    );
  }

  /// DELETEリクエスト
  Future<Response<dynamic>> delete(
    String path, {
    required ApiProvider apiProvider,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool enableAutoRefresh = false,
  }) async {
    return await _makeRequest(
      () => _dio.delete(path, data: data, queryParameters: queryParameters, options: options),
      apiProvider,
      'DELETE',
      path,
      enableAutoRefresh: enableAutoRefresh,
    );
  }

  /// リクエストログを取得
  List<ApiRequestLog> getRequestLogs(ApiProvider provider) {
    return _requestLogs[provider] ?? [];
  }

  /// 全てのログをクリア
  void clearLogs() {
    _requestLogs.clear();
    _logger.d('SecureApiClient: All request logs cleared');
  }

  // ===================
  // プライベートメソッド
  // ===================

  /// 初期化状態をチェック
  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('SecureApiClient is not initialized. Call initialize() first.');
    }
  }

  /// Dioインターセプターを設定
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // リクエストヘッダーにユーザーエージェントを追加
          options.headers['User-Agent'] = 'FatGram/1.0.0';
          handler.next(options);
        },
        onError: (error, handler) async {
          _logger.e('SecureApiClient: HTTP Error - ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  /// 統一的なリクエスト実行
  Future<Response<dynamic>> _makeRequest(
    Future<Response<dynamic>> Function() requestFunction,
    ApiProvider apiProvider,
    String method,
    String path, {
    bool enableAutoRefresh = false,
  }) async {
    _checkInitialized();

    // レート制限チェック
    if (!_rateLimiter.canMakeRequest(apiProvider)) {
      throw RateLimitException.tooManyRequests();
    }

    final stopwatch = Stopwatch()..start();
    Response<dynamic>? response;
    String? errorMessage;

    try {
      // APIキーを取得してヘッダーに設定
      final apiKey = await _apiKeyManager.getApiKey(apiProvider);
      _setAuthHeader(apiProvider, apiKey);

      // レート制限を記録
      _rateLimiter.recordRequest(apiProvider);

      // リクエスト実行
      response = await requestFunction();

      // レスポンス検証
      if (response.data == null && response.statusCode == 200) {
        throw const ServerException(
          message: 'Response data is null',
          code: 'NULL_RESPONSE_DATA',
        );
      }

      stopwatch.stop();
      _logRequest(apiProvider, method, path, stopwatch.elapsed, response.statusCode);

      return response;

    } on DioException catch (e) {
      stopwatch.stop();
      errorMessage = e.message ?? 'Unknown DioException';

      // 401エラーの場合、自動リフレッシュを試行
      if (e.response?.statusCode == 401 && enableAutoRefresh) {
        try {
          _logger.w('SecureApiClient: Attempting to refresh API key for ${apiProvider.name}');
          await refreshApiKey(apiProvider);

          // リフレッシュ後にリクエストを再試行
          return await _makeRequest(requestFunction, apiProvider, method, path, enableAutoRefresh: false);
        } catch (refreshError) {
          _logger.e('SecureApiClient: API key refresh failed: $refreshError');
          // リフレッシュに失敗した場合は元のエラーを投げる
        }
      }

      _logRequest(apiProvider, method, path, stopwatch.elapsed, e.response?.statusCode, errorMessage);
      _handleDioException(e);

    } catch (e) {
      stopwatch.stop();
      errorMessage = e.toString();
      _logRequest(apiProvider, method, path, stopwatch.elapsed, null, errorMessage);

      _logger.e('SecureApiClient: Unexpected error: $e');
      throw ServerException(
        message: 'Unexpected error occurred: ${e.toString()}',
        code: 'UNEXPECTED_ERROR',
      );
    }

    throw StateError('This should never be reached');
  }

  /// APIプロバイダーに応じてAuthヘッダーを設定
  void _setAuthHeader(ApiProvider provider, String apiKey) {
    switch (provider) {
      case ApiProvider.openai:
        _dio.options.headers['Authorization'] = 'Bearer $apiKey';
        break;
      case ApiProvider.gemini:
        _dio.options.headers['x-api-key'] = apiKey;
        break;
      case ApiProvider.webSearch:
        // クエリパラメータとして設定される場合が多い
        break;
      case ApiProvider.revenueCat:
        _dio.options.headers['Authorization'] = 'Bearer $apiKey';
        break;
      case ApiProvider.firebase:
        _dio.options.headers['Authorization'] = 'Bearer $apiKey';
        break;
    }
  }

  /// DioExceptionを適切な例外に変換
  void _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw NetworkException(
          message: 'Request timeout: ${e.message}',
          code: 'TIMEOUT',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode != null) {
          switch (statusCode) {
            case 400:
              throw ValidationException(
                message: 'Bad request: ${responseData?['message'] ?? e.message}',
                code: 'BAD_REQUEST',
              );
            case 401:
              throw AuthException(
                message: 'Unauthorized: ${responseData?['message'] ?? e.message}',
                code: 'UNAUTHORIZED',
              );
            case 403:
              throw AuthException(
                message: 'Forbidden: ${responseData?['message'] ?? e.message}',
                code: 'FORBIDDEN',
              );
            case 404:
              throw ServerException(
                message: 'Not found: ${responseData?['message'] ?? e.message}',
                code: 'NOT_FOUND',
              );
            case 429:
              throw RateLimitException(
                message: 'Rate limit exceeded: ${responseData?['message'] ?? e.message}',
                code: 'RATE_LIMIT_EXCEEDED',
                retryAfter: const Duration(minutes: 1),
              );
            case 500:
            case 502:
            case 503:
              throw ServerException(
                message: 'Server error: ${responseData?['message'] ?? e.message}',
                code: 'SERVER_ERROR',
              );
            default:
              throw ServerException(
                message: 'HTTP error $statusCode: ${responseData?['message'] ?? e.message}',
                code: 'HTTP_ERROR',
              );
          }
        }
        break;

      case DioExceptionType.cancel:
        throw NetworkException(
          message: 'Request was cancelled',
          code: 'REQUEST_CANCELLED',
        );

      case DioExceptionType.connectionError:
        throw NetworkException(
          message: 'Connection error: ${e.message}',
          code: 'CONNECTION_ERROR',
        );

      case DioExceptionType.badCertificate:
        throw NetworkException(
          message: 'Certificate error: ${e.message}',
          code: 'CERTIFICATE_ERROR',
        );

      case DioExceptionType.unknown:
      default:
        throw ServerException(
          message: 'Unknown error: ${e.message}',
          code: 'UNKNOWN_ERROR',
        );
    }
  }

  /// リクエストをログに記録
  void _logRequest(
    ApiProvider provider,
    String method,
    String path,
    Duration duration,
    int? statusCode, [
    String? error,
  ]) {
    final log = ApiRequestLog(
      url: path,
      method: method,
      timestamp: DateTime.now(),
      duration: duration,
      provider: provider,
      statusCode: statusCode,
      error: error,
    );

    // プロバイダー別のログリストを初期化
    _requestLogs[provider] ??= [];

    // ログを追加
    _requestLogs[provider]!.add(log);

    // 最大ログ数を超えた場合、古いログを削除
    if (_requestLogs[provider]!.length > _maxLogsPerProvider) {
      _requestLogs[provider]!.removeAt(0);
    }

    // ログレベルに応じてログ出力
    if (error != null) {
      _logger.e('SecureApiClient: $log');
    } else if (statusCode != null && statusCode >= 400) {
      _logger.w('SecureApiClient: $log');
    } else {
      _logger.d('SecureApiClient: $log');
    }
  }
}