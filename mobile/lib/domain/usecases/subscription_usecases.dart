import '../repositories/subscription_repository.dart';

/// サブスクリプション状態取得ユースケース
class GetSubscriptionStatus {
  final SubscriptionRepository repository;

  GetSubscriptionStatus(this.repository);

  Future<Map<String, dynamic>> call() {
    return repository.getSubscriptionStatus();
  }
}

/// サブスクリプション検証ユースケース
class VerifySubscription {
  final SubscriptionRepository repository;

  VerifySubscription(this.repository);

  Future<Map<String, dynamic>> call({
    required String receipt,
    required String platform,
  }) {
    return repository.verifySubscription(
      receipt: receipt,
      platform: platform,
    );
  }
}

/// サブスクリプション購入ユースケース
class PurchaseSubscription {
  final SubscriptionRepository repository;

  PurchaseSubscription(this.repository);

  Future<Map<String, dynamic>> call({
    required String productId,
  }) {
    return repository.purchaseSubscription(
      productId: productId,
    );
  }
}

/// 購入復元ユースケース
class RestorePurchases {
  final SubscriptionRepository repository;

  RestorePurchases(this.repository);

  Future<Map<String, dynamic>> call() {
    return repository.restorePurchases();
  }
}

/// 機能使用許可確認ユースケース
class IsFeatureEnabled {
  final SubscriptionRepository repository;

  IsFeatureEnabled(this.repository);

  Future<bool> call(String featureId) {
    return repository.isFeatureEnabled(featureId);
  }
}

/// 価格情報取得ユースケース
class GetProductPrices {
  final SubscriptionRepository repository;

  GetProductPrices(this.repository);

  Future<Map<String, dynamic>> call() {
    return repository.getProductPrices();
  }
}

/// 自動更新設定ユースケース
class SetAutoRenewStatus {
  final SubscriptionRepository repository;

  SetAutoRenewStatus(this.repository);

  Future<void> call({
    required bool autoRenew,
  }) {
    return repository.setAutoRenewStatus(
      autoRenew: autoRenew,
    );
  }
}
