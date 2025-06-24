import 'package:dartz/dartz.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/entities/subscription.dart';
import '../../core/error/failures.dart';
import '../datasources/subscription/revenue_cat_datasource.dart';

/// サブスクリプションリポジトリの実装
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final RevenueCatDataSource revenueCatDataSource;

  const SubscriptionRepositoryImpl({
    required this.revenueCatDataSource,
  });

  @override
  Future<Either<Failure, void>> initialize({
    required String apiKey,
    required String userId,
  }) async {
    try {
      await revenueCatDataSource.initialize(apiKey: apiKey, userId: userId);
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SubscriptionOffering>>> getOfferings() async {
    try {
      final offerings = await revenueCatDataSource.getOfferings();
      return Right(offerings);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseResult>> purchasePackage(String packageId) async {
    try {
      final result = await revenueCatDataSource.purchasePackage(packageId);
      return Right(result);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RestoreResult>> restorePurchases() async {
    try {
      final result = await revenueCatDataSource.restorePurchases();
      return Right(result);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerInfo>> getCustomerInfo() async {
    try {
      final customerInfo = await revenueCatDataSource.getCustomerInfo();
      return Right(customerInfo);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasActiveSubscription() async {
    try {
      final hasActive = await revenueCatDataSource.hasActiveSubscription();
      return Right(hasActive);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> validateReceipt(String receiptData) async {
    try {
      final isValid = await revenueCatDataSource.validateReceipt(receiptData);
      return Right(isValid);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PromoCodeResult>> redeemPromotionalCode(String promoCode) async {
    try {
      final result = await revenueCatDataSource.redeemPromotionalCode(promoCode);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setUserId(String userId) async {
    try {
      await revenueCatDataSource.setUserId(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logOut() async {
    try {
      await revenueCatDataSource.logOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}