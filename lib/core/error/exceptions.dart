/// アプリケーション全体で使用する基本的な例外クラス
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic data;

  const AppException({
    required this.message,
    this.code,
    this.data,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

/// サーバー関連の例外
class ServerException extends AppException {
  const ServerException({
    required String message,
    String? code,
    dynamic data,
  }) : super(
          message: message,
          code: code,
          data: data,
        );
}

/// ネットワーク関連の例外
class NetworkException extends AppException {
  const NetworkException({
    required String message,
    String? code,
    dynamic data,
  }) : super(
          message: message,
          code: code,
          data: data,
        );
}

/// キャッシュ関連の例外
class CacheException extends AppException {
  const CacheException({
    required String message,
    String? code,
    dynamic data,
  }) : super(
          message: message,
          code: code,
          data: data,
        );
}

/// 認証関連の例外
class AuthException extends AppException {
  const AuthException({
    required String message,
    String? code,
    dynamic data,
  }) : super(
          message: message,
          code: code,
          data: data,
        );
}

/// 入力検証関連の例外
class ValidationException extends AppException {
  const ValidationException({
    required String message,
    String? code,
    dynamic data,
  }) : super(
          message: message,
          code: code,
          data: data,
        );
}

/// AI機能関連の例外
class AIException extends AppException {
  const AIException({
    required String message,
    String? code,
    dynamic data,
  }) : super(
          message: message,
          code: code,
          data: data,
        );
}

/// 認証失敗例外
class UnauthorizedException extends AppException {
  UnauthorizedException({required String message}) : super(message: message);
}

/// 不正リクエスト例外
class BadRequestException extends AppException {
  BadRequestException({required String message}) : super(message: message);
}

/// リソース未検出例外
class NotFoundException extends AppException {
  NotFoundException({required String message}) : super(message: message);
}

/// 競合エラー例外
class ConflictException extends AppException {
  ConflictException({required String message}) : super(message: message);
}

/// アクセス禁止例外
class ForbiddenException extends AppException {
  ForbiddenException({required String message}) : super(message: message);
}

/// 支払い要求例外
class PaymentRequiredException extends AppException {
  PaymentRequiredException({required String message}) : super(message: message);
}

/// スマートウォッチ連携エラー例外
class WatchConnectivityException extends AppException {
  WatchConnectivityException({required String message}) : super(message: message);
}

/// 購読関連エラー例外
class SubscriptionException extends AppException {
  SubscriptionException({required String message}) : super(message: message);
}

/// レート制限例外
class RateLimitException extends AppException {
  final Duration retryAfter;

  const RateLimitException({
    required String message,
    String? code,
    required this.retryAfter,
    dynamic data,
  }) : super(
          message: message,
          code: code,
          data: data,
        );

  factory RateLimitException.tooManyRequests({
    Duration? retryAfter,
  }) {
    return RateLimitException(
      message: 'Too many requests. Please try again later.',
      code: 'RATE_LIMIT_EXCEEDED',
      retryAfter: retryAfter ?? const Duration(minutes: 1),
    );
  }
}