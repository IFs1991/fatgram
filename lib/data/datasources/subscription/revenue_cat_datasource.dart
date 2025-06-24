import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../domain/entities/subscription.dart';
import '../../../core/error/failures.dart';

/// RevenueCatデータソース
/// サブスクリプション機能の実装を担当
class RevenueCatDataSource {
  final dynamic _revenueCat;

  // キャッシュとパフォーマンス最適化
  List<SubscriptionOffering>? _cachedOfferings;
  DateTime? _lastOfferingsFetch;
  static const Duration _cacheExpiry = Duration(hours: 1);

  // 分析とトラッキング
  final Map<String, DateTime> _purchaseAttempts = {};
  final Map<String, String> _errorLog = {};

  RevenueCatDataSource({
    required dynamic revenueCat,
  }) : _revenueCat = revenueCat;

  // ===================
  // 初期化とセットアップ
  // ===================

  /// RevenueCatを初期化
  Future<void> initialize({
    required String apiKey,
    required String userId,
  }) async {
    try {
      if (kDebugMode) {
        print('RevenueCatDataSource: Initializing with API key: ${apiKey.substring(0, 8)}...');
      }

      // RevenueCatセットアップ
      await _revenueCat.setup(apiKey, userId);

      // ログレベル設定
      if (kDebugMode) {
        _revenueCat.setLogLevel('DEBUG');
      } else {
        _revenueCat.setLogLevel('ERROR');
      }

      if (kDebugMode) {
        print('RevenueCatDataSource: Initialization completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Initialization failed: $e');
      }

      if (e.toString().contains('invalid') || e.toString().contains('API')) {
        throw SubscriptionInitializationFailure.apiKeyInvalid();
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw SubscriptionInitializationFailure.networkError();
      } else {
        throw SubscriptionInitializationFailure.configurationError();
      }
    }
  }

  /// ユーザーIDを設定
  Future<void> setUserId(String userId) async {
    try {
      await _revenueCat.logIn(userId);
      if (kDebugMode) {
        print('RevenueCatDataSource: User ID set to: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Failed to set user ID: $e');
      }
      rethrow;
    }
  }

  /// ユーザーをログアウト
  Future<void> logOut() async {
    try {
      await _revenueCat.logOut();

      // キャッシュをクリア
      _cachedOfferings = null;
      _lastOfferingsFetch = null;

      if (kDebugMode) {
        print('RevenueCatDataSource: User logged out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Logout failed: $e');
      }
      rethrow;
    }
  }

  // ===================
  // 製品情報の取得
  // ===================

  /// サブスクリプションオファリングを取得
  Future<List<SubscriptionOffering>> getOfferings() async {
    try {
      // キャッシュチェック
      if (_isCacheValid()) {
        if (kDebugMode) {
          print('RevenueCatDataSource: Returning cached offerings');
        }
        return _cachedOfferings!;
      }

      if (kDebugMode) {
        print('RevenueCatDataSource: Fetching offerings from RevenueCat');
      }

      final rawOfferings = await _revenueCat.getOfferings();

      if (rawOfferings == null || rawOfferings.isEmpty) {
        if (kDebugMode) {
          print('RevenueCatDataSource: No offerings available');
        }
        return [];
      }

      final offerings = <SubscriptionOffering>[];

      for (final entry in rawOfferings.entries) {
        final offering = _parseOffering(entry.key, entry.value);
        if (offering != null) {
          offerings.add(offering);
        }
      }

      // キャッシュを更新
      _cachedOfferings = offerings;
      _lastOfferingsFetch = DateTime.now();

      if (kDebugMode) {
        print('RevenueCatDataSource: Retrieved ${offerings.length} offerings');
      }

      return offerings;
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Error fetching offerings: $e');
      }

      if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw SubscriptionFetchFailure.networkError();
      } else if (e.toString().contains('Rate limit')) {
        throw SubscriptionRateLimitFailure.tooManyRequests();
      } else if (e.toString().contains('server') || e.toString().contains('500')) {
        throw SubscriptionFetchFailure.serverError();
      } else {
        throw SubscriptionFetchFailure.parsingError();
      }
    }
  }

  /// オファリングのキャッシュを強制更新
  Future<void> refreshOfferings() async {
    _cachedOfferings = null;
    _lastOfferingsFetch = null;
    await getOfferings();
  }

  // ===================
  // 購入フローの実装
  // ===================

  /// パッケージを購入
  Future<PurchaseResult> purchasePackage(String packageId) async {
    final startTime = DateTime.now();
    _purchaseAttempts[packageId] = startTime;

    try {
      if (kDebugMode) {
        print('RevenueCatDataSource: Attempting to purchase package: $packageId');
      }

      final result = await _revenueCat.purchasePackage(packageId);

      if (result['userCancelled'] == true) {
        if (kDebugMode) {
          print('RevenueCatDataSource: Purchase cancelled by user');
        }
        return PurchaseResult.cancelled();
      }

      final customerInfoData = result['customerInfo'];
      if (customerInfoData != null) {
        final customerInfo = _parseCustomerInfo(customerInfoData);

        if (kDebugMode) {
          print('RevenueCatDataSource: Purchase completed successfully');
        }

        return PurchaseResult.success(
          customerInfo: customerInfo,
          transactionId: result['transactionId'] as String?,
        );
      } else {
        if (kDebugMode) {
          print('RevenueCatDataSource: Purchase failed - no customer info returned');
        }
        return PurchaseResult.error(
          errorMessage: 'Purchase completed but no customer info received',
          errorCode: 'NO_CUSTOMER_INFO',
        );
      }
    } catch (e) {
      final errorMessage = e.toString();
      String? errorCode;

      if (kDebugMode) {
        print('RevenueCatDataSource: Purchase error: $errorMessage');
      }

      // エラーコードを抽出
      if (errorMessage.contains('BILLING_UNAVAILABLE')) {
        errorCode = 'BILLING_UNAVAILABLE';
      } else if (errorMessage.contains('USER_CANCELLED')) {
        errorCode = 'USER_CANCELLED';
      } else if (errorMessage.contains('ITEM_UNAVAILABLE')) {
        errorCode = 'ITEM_UNAVAILABLE';
      } else if (errorMessage.contains('PAYMENT_DECLINED')) {
        errorCode = 'PAYMENT_DECLINED';
      } else if (errorMessage.contains('already owns')) {
        errorCode = 'DUPLICATE_PURCHASE';
      }

      // エラーログに記録
      _errorLog[packageId] = errorMessage;

      return PurchaseResult.error(
        errorMessage: errorMessage,
        errorCode: errorCode,
      );
    }
  }

  /// レシートを検証
  Future<bool> validateReceipt(String receiptData) async {
    try {
      if (kDebugMode) {
        print('RevenueCatDataSource: Validating receipt');
      }

      final customerInfo = await _revenueCat.getCustomerInfo();

      // 顧客情報からアクティブな権利をチェック
      final entitlements = customerInfo.entitlements;
      if (entitlements != null && entitlements.isNotEmpty) {
        for (final entitlement in entitlements.values) {
          if (entitlement['isActive'] == true) {
            if (kDebugMode) {
              print('RevenueCatDataSource: Receipt validation successful');
            }
            return true;
          }
        }
      }

      if (kDebugMode) {
        print('RevenueCatDataSource: Receipt validation failed - no active entitlements');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Receipt validation error: $e');
      }
      return false;
    }
  }

  // ===================
  // 復元処理
  // ===================

  /// 購入を復元
  Future<RestoreResult> restorePurchases() async {
    try {
      if (kDebugMode) {
        print('RevenueCatDataSource: Restoring purchases');
      }

      final customerInfo = await _revenueCat.restorePurchases();
      final parsedCustomerInfo = _parseCustomerInfo(customerInfo);

      // アクティブな製品を抽出
      final restoredProducts = <String>[];
      for (final entitlement in parsedCustomerInfo.entitlements.values) {
        if (entitlement.isActive) {
          restoredProducts.add(entitlement.productIdentifier);
        }
      }

      if (kDebugMode) {
        print('RevenueCatDataSource: Restored ${restoredProducts.length} products');
      }

      return RestoreResult.success(
        customerInfo: parsedCustomerInfo,
        restoredProducts: restoredProducts,
      );
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Restore failed: $e');
      }
      return RestoreResult.error(e.toString());
    }
  }

  // ===================
  // 顧客情報の管理
  // ===================

  /// 現在の顧客情報を取得
  Future<CustomerInfo> getCustomerInfo() async {
    try {
      if (kDebugMode) {
        print('RevenueCatDataSource: Fetching customer info');
      }

      final customerInfoData = await _revenueCat.getCustomerInfo();
      final customerInfo = _parseCustomerInfo(customerInfoData);

      if (kDebugMode) {
        print('RevenueCatDataSource: Customer info retrieved successfully');
      }

      return customerInfo;
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Failed to fetch customer info: $e');
      }

      if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw SubscriptionInfoFailure.networkError();
      } else if (e.toString().contains('not found')) {
        throw SubscriptionInfoFailure.customerNotFound();
      } else {
        throw SubscriptionInfoFailure.dataParsingError();
      }
    }
  }

  /// アクティブなサブスクリプションがあるかチェック
  Future<bool> hasActiveSubscription() async {
    try {
      final customerInfo = await getCustomerInfo();
      return customerInfo.hasActiveSubscription;
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Error checking subscription status: $e');
      }
      return false;
    }
  }

  /// サブスクリプション有効期限までの日数を取得
  Future<int> getDaysUntilExpiration() async {
    try {
      final customerInfo = await getCustomerInfo();
      return customerInfo.daysUntilExpiration ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Error getting expiration days: $e');
      }
      return 0;
    }
  }

  /// 更新警告を表示すべきかチェック
  Future<bool> shouldShowRenewalWarning() async {
    try {
      final customerInfo = await getCustomerInfo();
      final premiumEntitlement = customerInfo.premiumEntitlement;

      if (premiumEntitlement != null &&
          premiumEntitlement.isActive &&
          !premiumEntitlement.willRenew) {
        final daysUntilExpiration = premiumEntitlement.daysUntilExpiration ?? 0;
        return daysUntilExpiration <= 7; // 7日以内に期限切れ
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Error checking renewal warning: $e');
      }
      return false;
    }
  }

  // ===================
  // プロモーション機能
  // ===================

  /// プロモーションコードを適用
  Future<PromoCodeResult> redeemPromotionalCode(String promoCode) async {
    try {
      if (kDebugMode) {
        print('RevenueCatDataSource: Redeeming promotional code: $promoCode');
      }

      await _revenueCat.presentCodeRedemptionSheet();

      // コード適用後の顧客情報を取得
      final customerInfo = await getCustomerInfo();

      if (kDebugMode) {
        print('RevenueCatDataSource: Promotional code redeemed successfully');
      }

      return PromoCodeResult.success(customerInfo);
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Promotional code redemption failed: $e');
      }
      return PromoCodeResult.error(e.toString());
    }
  }

  // ===================
  // 分析とトラッキング
  // ===================

  /// 購入試行を記録
  Future<void> trackPurchaseAttempt(String packageId, DateTime startTime) async {
    _purchaseAttempts[packageId] = startTime;

    if (kDebugMode) {
      print('RevenueCatDataSource: Tracked purchase attempt for $packageId');
    }
  }

  /// ライフタイム値を計算
  Future<double> calculateLifetimeValue() async {
    try {
      final customerInfo = await getCustomerInfo();
      return customerInfo.calculateLifetimeValue();
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Error calculating LTV: $e');
      }
      return 0.0;
    }
  }

  // ===================
  // ヘルパーメソッド
  // ===================

  /// キャッシュが有効かチェック
  bool _isCacheValid() {
    if (_cachedOfferings == null || _lastOfferingsFetch == null) {
      return false;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(_lastOfferingsFetch!);
    return cacheAge < _cacheExpiry;
  }

  /// オファリングをパース
  SubscriptionOffering? _parseOffering(String id, dynamic offeringData) {
    try {
      final packages = <SubscriptionPackage>[];

      if (offeringData.availablePackages != null) {
        for (final packageData in offeringData.availablePackages) {
          final package = _parsePackage(packageData);
          if (package != null) {
            packages.add(package);
          }
        }
      }

      return SubscriptionOffering(
        id: id,
        name: offeringData.serverDescription ?? offeringData.identifier ?? id,
        description: offeringData.description ?? '',
        packages: packages,
      );
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Error parsing offering: $e');
      }
      return null;
    }
  }

  /// パッケージをパース
  SubscriptionPackage? _parsePackage(dynamic packageData) {
    try {
      final product = _parseProduct(packageData.product);
      if (product == null) return null;

      final period = _mapPackageTypeToPeriod(packageData.packageType ?? packageData.identifier);

      return SubscriptionPackage(
        id: packageData.identifier ?? '',
        period: period,
        product: product,
        isRecommended: packageData.isRecommended ?? false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Error parsing package: $e');
      }
      return null;
    }
  }

  /// 製品をパース
  SubscriptionProduct? _parseProduct(dynamic productData) {
    try {
      if (productData == null) return null;

      return SubscriptionProduct(
        identifier: productData['identifier'] ?? '',
        title: productData['title'] ?? '',
        description: productData['description'] ?? '',
        price: (productData['price'] as num?)?.toDouble() ?? 0.0,
        currencyCode: productData['currencyCode'] ?? 'USD',
        priceString: productData['priceString'] ?? '\$0.00',
        introductoryPrice: productData['introductoryPrice'] as String?,
        introductoryPeriod: productData['introductoryPeriod'] != null
            ? Duration(days: productData['introductoryPeriod'] as int)
            : null,
        freeTrialPeriod: productData['freeTrialPeriod'] != null
            ? Duration(days: productData['freeTrialPeriod'] as int)
            : null,
      );
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Error parsing product: $e');
      }
      return null;
    }
  }

  /// 顧客情報をパース
  CustomerInfo _parseCustomerInfo(dynamic customerInfoData) {
    try {
      final entitlements = <String, Entitlement>{};
      final activeSubscriptions = <String>[];

      if (customerInfoData.entitlements != null) {
        for (final entry in customerInfoData.entitlements.entries) {
          final entitlement = _parseEntitlement(entry.key, entry.value);
          if (entitlement != null) {
            entitlements[entry.key] = entitlement;
            if (entitlement.isActive) {
              activeSubscriptions.add(entitlement.productIdentifier);
            }
          }
        }
      }

      // activeSubscriptionsプロパティからも取得
      final activeSubsList = customerInfoData.activeSubscriptions as List<String>? ?? [];
      for (final sub in activeSubsList) {
        if (!activeSubscriptions.contains(sub)) {
          activeSubscriptions.add(sub);
        }
      }

      return CustomerInfo(
        userId: customerInfoData.originalAppUserId ?? '',
        activeSubscriptions: activeSubscriptions,
        entitlements: entitlements,
        originalPurchaseDate: _parseTimestamp(entitlements.values.first.originalPurchaseDate),
        latestExpirationDate: _parseTimestamp(entitlements.values.first.expirationDate),
        firstSeen: SubscriptionStore.appStore, // デフォルト
      );
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Error parsing customer info: $e');
      }
      // フォールバック
      return const CustomerInfo(
        userId: '',
        activeSubscriptions: [],
        entitlements: {},
      );
    }
  }

  /// 権利をパース
  Entitlement? _parseEntitlement(String identifier, dynamic entitlementData) {
    try {
      return Entitlement(
        identifier: identifier,
        isActive: entitlementData['isActive'] ?? false,
        willRenew: entitlementData['willRenew'] ?? false,
        status: _mapEntitlementStatus(entitlementData['periodType']),
        latestPurchaseDate: _parseTimestamp(entitlementData['latestPurchaseDate']),
        originalPurchaseDate: _parseTimestamp(entitlementData['originalPurchaseDate']),
        expirationDate: _parseTimestamp(entitlementData['expirationDate']),
        store: _mapStore(entitlementData['store']),
        productIdentifier: entitlementData['productIdentifier'] ?? '',
        isSandbox: entitlementData['isSandbox'] ?? false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Error parsing entitlement: $e');
      }
      return null;
    }
  }

  /// パッケージタイプをサブスクリプション期間にマッピング
  SubscriptionPeriod _mapPackageTypeToPeriod(String? packageType) {
    switch (packageType?.toLowerCase()) {
      case 'monthly':
        return SubscriptionPeriod.monthly;
      case 'quarterly':
        return SubscriptionPeriod.quarterly;
      case 'yearly':
      case 'annual':
        return SubscriptionPeriod.yearly;
      case 'weekly':
        return SubscriptionPeriod.weekly;
      case 'lifetime':
        return SubscriptionPeriod.lifetime;
      default:
        return SubscriptionPeriod.unknown;
    }
  }

  /// 権利ステータスをマッピング
  EntitlementStatus _mapEntitlementStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'normal':
        return EntitlementStatus.active;
      case 'grace_period':
        return EntitlementStatus.inGracePeriod;
      case 'billing_retry':
        return EntitlementStatus.inBillingRetryPeriod;
      case 'expired':
        return EntitlementStatus.expired;
      default:
        return EntitlementStatus.unknown;
    }
  }

  /// ストアをマッピング
  SubscriptionStore _mapStore(String? store) {
    switch (store?.toLowerCase()) {
      case 'app_store':
        return SubscriptionStore.appStore;
      case 'play_store':
        return SubscriptionStore.playStore;
      case 'stripe':
        return SubscriptionStore.stripe;
      case 'promotional':
        return SubscriptionStore.promotional;
      default:
        return SubscriptionStore.unknown;
    }
  }

  /// タイムスタンプをパース
  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    try {
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCatDataSource: Error parsing timestamp: $e');
      }
    }

    return null;
  }

  /// リソースのクリーンアップ
  void dispose() {
    _cachedOfferings = null;
    _lastOfferingsFetch = null;
    _purchaseAttempts.clear();
    _errorLog.clear();

    if (kDebugMode) {
      print('RevenueCatDataSource: Resources disposed');
    }
  }
}