/// サブスクリプションリポジトリインターフェース
abstract class SubscriptionRepository {
  /// サブスクリプション状態取得
  Future<Map<String, dynamic>> getSubscriptionStatus();

  /// サブスクリプション検証
  Future<Map<String, dynamic>> verifySubscription({
    required String receipt,
    required String platform,
  });

  /// サブスクリプション購入
  Future<Map<String, dynamic>> purchaseSubscription({
    required String productId,
  });

  /// 購入の復元
  Future<Map<String, dynamic>> restorePurchases();

  /// 機能使用許可確認
  ///
  /// 指定された機能が現在のサブスクリプションで利用可能か確認します
  Future<bool> isFeatureEnabled(String featureId);

  /// 価格情報の取得
  Future<Map<String, dynamic>> getProductPrices();

  /// サブスクリプションの更新状態変更
  Future<void> setAutoRenewStatus({
    required bool autoRenew,
  });
}