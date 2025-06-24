import 'package:equatable/equatable.dart';

/// サブスクリプション期間タイプ
enum SubscriptionPeriod {
  monthly,
  quarterly,
  yearly,
  lifetime,
  weekly,
  unknown,
}

/// サブスクリプションストア
enum SubscriptionStore {
  appStore,
  playStore,
  stripe,
  promotional,
  unknown,
}

/// 権利の状態
enum EntitlementStatus {
  active,
  expired,
  inGracePeriod,
  inBillingRetryPeriod,
  unknown,
}

/// サブスクリプションオファリング
class SubscriptionOffering extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<SubscriptionPackage> packages;
  final Map<String, dynamic>? metadata;

  const SubscriptionOffering({
    required this.id,
    required this.name,
    required this.description,
    required this.packages,
    this.metadata,
  });

  /// 特定期間のパッケージを取得
  SubscriptionPackage? getPackage(SubscriptionPeriod period) {
    try {
      return packages.firstWhere((package) => package.period == period);
    } catch (e) {
      return null;
    }
  }

  /// 最も人気のパッケージを取得
  SubscriptionPackage? get popularPackage {
    // 通常は年間プランが人気
    return getPackage(SubscriptionPeriod.yearly) ??
           getPackage(SubscriptionPeriod.monthly);
  }

  @override
  List<Object?> get props => [id, name, description, packages, metadata];

  @override
  String toString() => 'SubscriptionOffering{id: $id, name: $name, packages: ${packages.length}}';
}

/// サブスクリプションパッケージ
class SubscriptionPackage extends Equatable {
  final String id;
  final SubscriptionPeriod period;
  final SubscriptionProduct product;
  final bool isRecommended;
  final double? discountPercentage;
  final String? promoText;

  const SubscriptionPackage({
    required this.id,
    required this.period,
    required this.product,
    this.isRecommended = false,
    this.discountPercentage,
    this.promoText,
  });

  /// 月額換算価格を計算
  double get monthlyEquivalentPrice {
    switch (period) {
      case SubscriptionPeriod.monthly:
        return product.price;
      case SubscriptionPeriod.quarterly:
        return product.price / 3;
      case SubscriptionPeriod.yearly:
        return product.price / 12;
      case SubscriptionPeriod.weekly:
        return product.price * 4.33; // 1ヶ月 ≈ 4.33週
      case SubscriptionPeriod.lifetime:
        return 0; // 一回払い
      default:
        return product.price;
    }
  }

  /// 年間割引額を計算
  double calculateYearlyDiscount(double monthlyPrice) {
    if (period == SubscriptionPeriod.yearly) {
      final yearlyAsMonthly = monthlyPrice * 12;
      return yearlyAsMonthly - product.price;
    }
    return 0;
  }

  @override
  List<Object?> get props => [
    id, period, product, isRecommended, discountPercentage, promoText
  ];

  @override
  String toString() => 'SubscriptionPackage{id: $id, period: $period, price: ${product.priceString}}';
}

/// サブスクリプション商品
class SubscriptionProduct extends Equatable {
  final String identifier;
  final String title;
  final String description;
  final double price;
  final String currencyCode;
  final String priceString;
  final String? introductoryPrice;
  final Duration? introductoryPeriod;
  final Duration? freeTrialPeriod;

  const SubscriptionProduct({
    required this.identifier,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    required this.priceString,
    this.introductoryPrice,
    this.introductoryPeriod,
    this.freeTrialPeriod,
  });

  /// 無料トライアルがあるかチェック
  bool get hasFreeTrial => freeTrialPeriod != null && freeTrialPeriod!.inDays > 0;

  /// 導入価格があるかチェック
  bool get hasIntroductoryOffer => introductoryPrice != null;

  /// 無料トライアル日数を取得
  int get freeTrialDays => freeTrialPeriod?.inDays ?? 0;

  @override
  List<Object?> get props => [
    identifier, title, description, price, currencyCode, priceString,
    introductoryPrice, introductoryPeriod, freeTrialPeriod
  ];

  @override
  String toString() => 'SubscriptionProduct{identifier: $identifier, price: $priceString}';
}

/// 顧客情報
class CustomerInfo extends Equatable {
  final String userId;
  final List<String> activeSubscriptions;
  final Map<String, Entitlement> entitlements;
  final DateTime? originalPurchaseDate;
  final DateTime? latestExpirationDate;
  final SubscriptionStore? firstSeen;

  const CustomerInfo({
    required this.userId,
    required this.activeSubscriptions,
    required this.entitlements,
    this.originalPurchaseDate,
    this.latestExpirationDate,
    this.firstSeen,
  });

  /// アクティブなサブスクリプションがあるかチェック
  bool get hasActiveSubscription => activeSubscriptions.isNotEmpty;

  /// プレミアム権利を取得
  Entitlement? get premiumEntitlement => entitlements['premium'];

  /// プレミアムが有効かチェック
  bool get isPremiumActive => premiumEntitlement?.isActive ?? false;

  /// サブスクリプション期限までの日数
  int? get daysUntilExpiration {
    final expiration = latestExpirationDate;
    if (expiration == null) return null;

    final now = DateTime.now();
    if (expiration.isBefore(now)) return 0;

    return expiration.difference(now).inDays;
  }

  /// 顧客ライフタイム値を計算（仮想）
  double calculateLifetimeValue() {
    if (originalPurchaseDate == null) return 0;

    final daysSinceFirstPurchase = DateTime.now().difference(originalPurchaseDate!).inDays;
    final monthsSinceFirstPurchase = daysSinceFirstPurchase / 30.0;

    // 仮定: 月額9.99ドル
    return monthsSinceFirstPurchase * 9.99;
  }

  @override
  List<Object?> get props => [
    userId, activeSubscriptions, entitlements,
    originalPurchaseDate, latestExpirationDate, firstSeen
  ];

  @override
  String toString() => 'CustomerInfo{userId: $userId, active: ${activeSubscriptions.length}}';
}

/// 権利（Entitlement）
class Entitlement extends Equatable {
  final String identifier;
  final bool isActive;
  final bool willRenew;
  final EntitlementStatus status;
  final DateTime? latestPurchaseDate;
  final DateTime? originalPurchaseDate;
  final DateTime? expirationDate;
  final SubscriptionStore store;
  final String productIdentifier;
  final bool isSandbox;

  const Entitlement({
    required this.identifier,
    required this.isActive,
    required this.willRenew,
    required this.status,
    this.latestPurchaseDate,
    this.originalPurchaseDate,
    this.expirationDate,
    required this.store,
    required this.productIdentifier,
    required this.isSandbox,
  });

  /// 期限切れかチェック
  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  /// 有効期限まで何日あるかチェック
  int? get daysUntilExpiration {
    if (expirationDate == null) return null;
    final now = DateTime.now();
    if (expirationDate!.isBefore(now)) return 0;
    return expirationDate!.difference(now).inDays;
  }

  /// グレースピリオドかチェック
  bool get isInGracePeriod => status == EntitlementStatus.inGracePeriod;

  /// 請求リトライ期間かチェック
  bool get isInBillingRetryPeriod => status == EntitlementStatus.inBillingRetryPeriod;

  @override
  List<Object?> get props => [
    identifier, isActive, willRenew, status,
    latestPurchaseDate, originalPurchaseDate, expirationDate,
    store, productIdentifier, isSandbox
  ];

  @override
  String toString() => 'Entitlement{identifier: $identifier, isActive: $isActive, expires: $expirationDate}';
}

/// 購入結果
class PurchaseResult extends Equatable {
  final bool isSuccess;
  final CustomerInfo? customerInfo;
  final bool userCancelled;
  final String? errorMessage;
  final String? errorCode;
  final String? transactionId;

  const PurchaseResult({
    required this.isSuccess,
    this.customerInfo,
    required this.userCancelled,
    this.errorMessage,
    this.errorCode,
    this.transactionId,
  });

  /// 成功した購入結果を作成
  factory PurchaseResult.success({
    required CustomerInfo customerInfo,
    String? transactionId,
  }) {
    return PurchaseResult(
      isSuccess: true,
      customerInfo: customerInfo,
      userCancelled: false,
      transactionId: transactionId,
    );
  }

  /// キャンセルされた購入結果を作成
  factory PurchaseResult.cancelled() {
    return const PurchaseResult(
      isSuccess: false,
      userCancelled: true,
      errorMessage: 'User cancelled the purchase',
    );
  }

  /// エラーの購入結果を作成
  factory PurchaseResult.error({
    required String errorMessage,
    String? errorCode,
  }) {
    return PurchaseResult(
      isSuccess: false,
      userCancelled: false,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }

  @override
  List<Object?> get props => [
    isSuccess, customerInfo, userCancelled,
    errorMessage, errorCode, transactionId
  ];

  @override
  String toString() => 'PurchaseResult{isSuccess: $isSuccess, userCancelled: $userCancelled}';
}

/// 復元結果
class RestoreResult extends Equatable {
  final bool isSuccess;
  final CustomerInfo? customerInfo;
  final List<String> restoredProducts;
  final String? errorMessage;

  const RestoreResult({
    required this.isSuccess,
    this.customerInfo,
    required this.restoredProducts,
    this.errorMessage,
  });

  /// 成功した復元結果を作成
  factory RestoreResult.success({
    required CustomerInfo customerInfo,
    required List<String> restoredProducts,
  }) {
    return RestoreResult(
      isSuccess: true,
      customerInfo: customerInfo,
      restoredProducts: restoredProducts,
    );
  }

  /// エラーの復元結果を作成
  factory RestoreResult.error(String errorMessage) {
    return RestoreResult(
      isSuccess: false,
      restoredProducts: [],
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isSuccess, customerInfo, restoredProducts, errorMessage];

  @override
  String toString() => 'RestoreResult{isSuccess: $isSuccess, restored: ${restoredProducts.length}}';
}

/// プロモーションコード結果
class PromoCodeResult extends Equatable {
  final bool isSuccess;
  final String? errorMessage;
  final CustomerInfo? customerInfo;

  const PromoCodeResult({
    required this.isSuccess,
    this.errorMessage,
    this.customerInfo,
  });

  /// 成功したプロモーションコード結果を作成
  factory PromoCodeResult.success(CustomerInfo customerInfo) {
    return PromoCodeResult(
      isSuccess: true,
      customerInfo: customerInfo,
    );
  }

  /// エラーのプロモーションコード結果を作成
  factory PromoCodeResult.error(String errorMessage) {
    return PromoCodeResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isSuccess, errorMessage, customerInfo];

  @override
  String toString() => 'PromoCodeResult{isSuccess: $isSuccess}';
}

/// サブスクリプション分析データ
class SubscriptionAnalytics extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final int totalPurchases;
  final int totalRefunds;
  final double totalRevenue;
  final double averageRevenuePerUser;
  final double conversionRate;
  final Map<SubscriptionPeriod, int> periodDistribution;
  final Map<String, int> productPerformance;

  const SubscriptionAnalytics({
    required this.startDate,
    required this.endDate,
    required this.totalPurchases,
    required this.totalRefunds,
    required this.totalRevenue,
    required this.averageRevenuePerUser,
    required this.conversionRate,
    required this.periodDistribution,
    required this.productPerformance,
  });

  /// チャーン率を計算
  double get churnRate {
    if (totalPurchases == 0) return 0;
    return totalRefunds / totalPurchases;
  }

  /// 最も人気の期間を取得
  SubscriptionPeriod? get mostPopularPeriod {
    if (periodDistribution.isEmpty) return null;

    var maxCount = 0;
    SubscriptionPeriod? mostPopular;

    periodDistribution.forEach((period, count) {
      if (count > maxCount) {
        maxCount = count;
        mostPopular = period;
      }
    });

    return mostPopular;
  }

  @override
  List<Object?> get props => [
    startDate, endDate, totalPurchases, totalRefunds, totalRevenue,
    averageRevenuePerUser, conversionRate, periodDistribution, productPerformance
  ];

  @override
  String toString() => 'SubscriptionAnalytics{revenue: \$${totalRevenue.toStringAsFixed(2)}, purchases: $totalPurchases}';
}