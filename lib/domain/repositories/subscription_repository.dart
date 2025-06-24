import 'package:dartz/dartz.dart';
import '../entities/subscription.dart';
import '../../core/error/failures.dart';

/// サブスクリプションリポジトリのインターフェース
abstract class SubscriptionRepository {
  /// RevenueCatを初期化
  Future<Either<Failure, void>> initialize({
    required String apiKey,
    required String userId,
  });

  /// 利用可能なサブスクリプションオファリングを取得
  Future<Either<Failure, List<SubscriptionOffering>>> getOfferings();

  /// パッケージを購入
  Future<Either<Failure, PurchaseResult>> purchasePackage(String packageId);

  /// 購入を復元
  Future<Either<Failure, RestoreResult>> restorePurchases();

  /// 顧客情報を取得
  Future<Either<Failure, CustomerInfo>> getCustomerInfo();

  /// アクティブなサブスクリプションがあるかチェック
  Future<Either<Failure, bool>> hasActiveSubscription();

  /// レシートを検証
  Future<Either<Failure, bool>> validateReceipt(String receiptData);

  /// プロモーションコードを適用
  Future<Either<Failure, PromoCodeResult>> redeemPromotionalCode(String promoCode);

  /// ユーザーIDを設定
  Future<Either<Failure, void>> setUserId(String userId);

  /// ユーザーをログアウト
  Future<Either<Failure, void>> logOut();
}