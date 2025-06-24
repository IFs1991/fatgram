import 'package:equatable/equatable.dart';

/// 基底失敗クラス
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const Failure({
    required this.message,
    this.code,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

/// サーバー失敗
class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );
}

/// キャッシュ失敗
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );
}

/// ネットワーク失敗
class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );
}

/// 認証失敗
class AuthFailure extends Failure {
  const AuthFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );
}

/// バリデーション失敗
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required String message,
    String? code,
    this.fieldErrors,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// 権限失敗
class PermissionFailure extends Failure {
  final List<String> missingPermissions;

  const PermissionFailure({
    required String message,
    String? code,
    required this.missingPermissions,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );

  @override
  List<Object?> get props => [message, code, missingPermissions];
}

// ===================
// サブスクリプション関連失敗
// ===================

/// サブスクリプション初期化失敗
class SubscriptionInitializationFailure extends Failure {
  const SubscriptionInitializationFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );

  factory SubscriptionInitializationFailure.apiKeyInvalid() {
    return const SubscriptionInitializationFailure(
      message: 'RevenueCat API key is invalid or missing',
      code: 'INVALID_API_KEY',
    );
  }

  factory SubscriptionInitializationFailure.networkError() {
    return const SubscriptionInitializationFailure(
      message: 'Failed to connect to RevenueCat servers',
      code: 'NETWORK_ERROR',
    );
  }

  factory SubscriptionInitializationFailure.configurationError() {
    return const SubscriptionInitializationFailure(
      message: 'RevenueCat configuration is incorrect',
      code: 'CONFIGURATION_ERROR',
    );
  }
}

/// サブスクリプション取得失敗
class SubscriptionFetchFailure extends Failure {
  const SubscriptionFetchFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );

  factory SubscriptionFetchFailure.networkError() {
    return const SubscriptionFetchFailure(
      message: 'Failed to fetch subscription offerings due to network error',
      code: 'NETWORK_ERROR',
    );
  }

  factory SubscriptionFetchFailure.noOfferings() {
    return const SubscriptionFetchFailure(
      message: 'No subscription offerings are available',
      code: 'NO_OFFERINGS',
    );
  }

  factory SubscriptionFetchFailure.serverError() {
    return const SubscriptionFetchFailure(
      message: 'Server error while fetching offerings',
      code: 'SERVER_ERROR',
    );
  }

  factory SubscriptionFetchFailure.parsingError() {
    return const SubscriptionFetchFailure(
      message: 'Failed to parse subscription offerings data',
      code: 'PARSING_ERROR',
    );
  }
}

/// サブスクリプション購入失敗
class SubscriptionPurchaseFailure extends Failure {
  const SubscriptionPurchaseFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );

  factory SubscriptionPurchaseFailure.userCancelled() {
    return const SubscriptionPurchaseFailure(
      message: 'User cancelled the purchase',
      code: 'USER_CANCELLED',
    );
  }

  factory SubscriptionPurchaseFailure.paymentMethodDeclined() {
    return const SubscriptionPurchaseFailure(
      message: 'Payment method was declined',
      code: 'PAYMENT_DECLINED',
    );
  }

  factory SubscriptionPurchaseFailure.itemUnavailable() {
    return const SubscriptionPurchaseFailure(
      message: 'The requested item is not available',
      code: 'ITEM_UNAVAILABLE',
    );
  }

  factory SubscriptionPurchaseFailure.billingUnavailable() {
    return const SubscriptionPurchaseFailure(
      message: 'Billing service is not available',
      code: 'BILLING_UNAVAILABLE',
    );
  }

  factory SubscriptionPurchaseFailure.duplicatePurchase() {
    return const SubscriptionPurchaseFailure(
      message: 'User already owns this product',
      code: 'DUPLICATE_PURCHASE',
    );
  }

  factory SubscriptionPurchaseFailure.unknownError(String details) {
    return SubscriptionPurchaseFailure(
      message: 'An unknown error occurred: $details',
      code: 'UNKNOWN_ERROR',
    );
  }
}

/// サブスクリプション復元失敗
class SubscriptionRestoreFailure extends Failure {
  const SubscriptionRestoreFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );

  factory SubscriptionRestoreFailure.noPurchasesToRestore() {
    return const SubscriptionRestoreFailure(
      message: 'No purchases found to restore',
      code: 'NO_PURCHASES',
    );
  }

  factory SubscriptionRestoreFailure.networkError() {
    return const SubscriptionRestoreFailure(
      message: 'Network error while restoring purchases',
      code: 'NETWORK_ERROR',
    );
  }

  factory SubscriptionRestoreFailure.invalidReceipt() {
    return const SubscriptionRestoreFailure(
      message: 'Invalid or expired receipt',
      code: 'INVALID_RECEIPT',
    );
  }
}

/// サブスクリプション情報取得失敗
class SubscriptionInfoFailure extends Failure {
  const SubscriptionInfoFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );

  factory SubscriptionInfoFailure.customerNotFound() {
    return const SubscriptionInfoFailure(
      message: 'Customer information not found',
      code: 'CUSTOMER_NOT_FOUND',
    );
  }

  factory SubscriptionInfoFailure.networkError() {
    return const SubscriptionInfoFailure(
      message: 'Network error while fetching customer info',
      code: 'NETWORK_ERROR',
    );
  }

  factory SubscriptionInfoFailure.dataParsingError() {
    return const SubscriptionInfoFailure(
      message: 'Failed to parse customer info data',
      code: 'DATA_PARSING_ERROR',
    );
  }
}

/// サブスクリプションレート制限失敗
class SubscriptionRateLimitFailure extends Failure {
  final Duration retryAfter;

  const SubscriptionRateLimitFailure({
    required String message,
    String? code,
    required this.retryAfter,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );

  factory SubscriptionRateLimitFailure.tooManyRequests({
    Duration? retryAfter,
  }) {
    return SubscriptionRateLimitFailure(
      message: 'Too many requests. Please try again later.',
      code: 'RATE_LIMIT_EXCEEDED',
      retryAfter: retryAfter ?? const Duration(minutes: 5),
    );
  }

  @override
  List<Object?> get props => [message, code, retryAfter];
}

/// サブスクリプション検証失敗
class SubscriptionValidationFailure extends Failure {
  const SubscriptionValidationFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );

  factory SubscriptionValidationFailure.invalidReceipt() {
    return const SubscriptionValidationFailure(
      message: 'Receipt validation failed',
      code: 'INVALID_RECEIPT',
    );
  }

  factory SubscriptionValidationFailure.receiptExpired() {
    return const SubscriptionValidationFailure(
      message: 'Receipt has expired',
      code: 'RECEIPT_EXPIRED',
    );
  }

  factory SubscriptionValidationFailure.serverError() {
    return const SubscriptionValidationFailure(
      message: 'Server error during receipt validation',
      code: 'SERVER_ERROR',
    );
  }
}

/// プロモーションコード失敗
class PromoCodeFailure extends Failure {
  const PromoCodeFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );

  factory PromoCodeFailure.invalidCode() {
    return const PromoCodeFailure(
      message: 'Promotional code is invalid or expired',
      code: 'INVALID_PROMO_CODE',
    );
  }

  factory PromoCodeFailure.alreadyUsed() {
    return const PromoCodeFailure(
      message: 'Promotional code has already been used',
      code: 'PROMO_CODE_USED',
    );
  }

  factory PromoCodeFailure.notEligible() {
    return const PromoCodeFailure(
      message: 'User is not eligible for this promotional code',
      code: 'NOT_ELIGIBLE',
    );
  }
}

// ===================
// ヘルス関連失敗（既存から拡張）
// ===================

/// ヘルスデータ失敗
class HealthDataFailure extends Failure {
  const HealthDataFailure({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          stackTrace: stackTrace,
        );

  factory HealthDataFailure.permissionDenied() {
    return const HealthDataFailure(
      message: 'Health data access permission denied',
      code: 'PERMISSION_DENIED',
    );
  }

  factory HealthDataFailure.dataNotAvailable() {
    return const HealthDataFailure(
      message: 'Health data is not available',
      code: 'DATA_NOT_AVAILABLE',
    );
  }

  factory HealthDataFailure.platformNotSupported() {
    return const HealthDataFailure(
      message: 'Health platform is not supported',
      code: 'PLATFORM_NOT_SUPPORTED',
    );
  }
}

// ===================
// ユーティリティ関数
// ===================

/// 例外をFailureに変換する
Failure mapExceptionToFailure(Exception exception) {
  final message = exception.toString();

  // RevenueCat関連エラーの判定
  if (message.contains('BILLING_UNAVAILABLE')) {
    return SubscriptionPurchaseFailure.billingUnavailable();
  } else if (message.contains('USER_CANCELLED')) {
    return SubscriptionPurchaseFailure.userCancelled();
  } else if (message.contains('ITEM_UNAVAILABLE')) {
    return SubscriptionPurchaseFailure.itemUnavailable();
  } else if (message.contains('PAYMENT_DECLINED')) {
    return SubscriptionPurchaseFailure.paymentMethodDeclined();
  } else if (message.contains('RATE_LIMIT')) {
    return SubscriptionRateLimitFailure.tooManyRequests();
  }

  // ネットワーク関連エラーの判定
  if (message.contains('network') ||
      message.contains('connection') ||
      message.contains('timeout')) {
    return NetworkFailure(message: message);
  }

  // 権限関連エラーの判定
  if (message.contains('permission') ||
      message.contains('unauthorized')) {
    return PermissionFailure(
      message: message,
      missingPermissions: ['subscription_access'],
    );
  }

  // デフォルトはサーバー失敗
  return ServerFailure(message: message);
}

/// エラーコードから適切なFailureを作成
Failure createFailureFromCode(String code, String message) {
  switch (code) {
    case 'INVALID_API_KEY':
      return SubscriptionInitializationFailure.apiKeyInvalid();
    case 'NETWORK_ERROR':
      return NetworkFailure(message: message, code: code);
    case 'USER_CANCELLED':
      return SubscriptionPurchaseFailure.userCancelled();
    case 'PAYMENT_DECLINED':
      return SubscriptionPurchaseFailure.paymentMethodDeclined();
    case 'RATE_LIMIT_EXCEEDED':
      return SubscriptionRateLimitFailure.tooManyRequests();
    case 'INVALID_RECEIPT':
      return SubscriptionValidationFailure.invalidReceipt();
    case 'PERMISSION_DENIED':
      return PermissionFailure(
        message: message,
        code: code,
        missingPermissions: ['required_permission'],
      );
    default:
      return ServerFailure(message: message, code: code);
  }
}