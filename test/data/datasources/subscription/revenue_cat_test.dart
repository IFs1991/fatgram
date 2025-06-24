import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fatgram/data/datasources/subscription/revenue_cat_datasource.dart';
import 'package:fatgram/domain/entities/subscription.dart';
import 'package:fatgram/core/error/failures.dart';
import '../../../test_helper.dart';

// Mock classes
class MockRevenueCat extends Mock {
  // 初期化メソッド
  Future<void> setup(String apiKey, String userId) => throw UnimplementedError();
  void setLogLevel(String level) => throw UnimplementedError();
  Future<dynamic> logIn(String userId) => throw UnimplementedError();
  Future<dynamic> logOut() => throw UnimplementedError();

  // オファリング関連
  Future<Map<String, dynamic>> getOfferings() => throw UnimplementedError();

  // 購入関連
  Future<Map<String, dynamic>> purchasePackage(String packageId) => throw UnimplementedError();
  Future<dynamic> getCustomerInfo() => throw UnimplementedError();
  Future<dynamic> restorePurchases() => throw UnimplementedError();

  // プロモーション
  Future<void> presentCodeRedemptionSheet() => throw UnimplementedError();
}

class MockCustomerInfo extends Mock {
  Map<String, dynamic>? get entitlements => throw UnimplementedError();
  String? get originalAppUserId => throw UnimplementedError();
  List<String>? get activeSubscriptions => throw UnimplementedError();
}

class MockOffering extends Mock {
  String? get identifier => throw UnimplementedError();
  String? get serverDescription => throw UnimplementedError();
  List<dynamic>? get availablePackages => throw UnimplementedError();
}

class MockPackage extends Mock {
  String? get identifier => throw UnimplementedError();
  String? get packageType => throw UnimplementedError();
  Map<String, dynamic>? get product => throw UnimplementedError();
}

class MockPurchaserInfo extends Mock {}

void main() {
  late RevenueCatDataSource revenueCatDataSource;
  late MockRevenueCat mockRevenueCat;
  late MockCustomerInfo mockCustomerInfo;
  late MockOffering mockOffering;
  late MockPackage mockPackage;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
    registerFallbackValue(Duration.zero);
    registerFallbackValue(<String>[]);
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRevenueCat = MockRevenueCat();
    mockCustomerInfo = MockCustomerInfo();
    mockOffering = MockOffering();
    mockPackage = MockPackage();

    revenueCatDataSource = RevenueCatDataSource(
      revenueCat: mockRevenueCat,
    );
  });

  group('RevenueCatDataSource', () {
    group('初期化とセットアップ', () {
      test('should initialize RevenueCat with API key', () async {
        // Arrange
        const apiKey = 'test_api_key';
        const userId = 'test_user_123';

        when(() => mockRevenueCat.setup(any(), any())).thenAnswer((_) async => null);
        when(() => mockRevenueCat.setLogLevel(any())).thenReturn(null);

        // Act
        await revenueCatDataSource.initialize(apiKey: apiKey, userId: userId);

        // Assert
        verify(() => mockRevenueCat.setup(apiKey, userId)).called(1);
        verify(() => mockRevenueCat.setLogLevel(any())).called(1);
      });

      test('should handle initialization failure gracefully', () async {
        // Arrange
        const apiKey = 'invalid_key';
        const userId = 'test_user_123';

        when(() => mockRevenueCat.setup(any(), any()))
            .thenThrow(Exception('RevenueCat initialization failed'));

        // Act & Assert
        expect(
          () => revenueCatDataSource.initialize(apiKey: apiKey, userId: userId),
          throwsA(isA<SubscriptionInitializationFailure>()),
        );
      });

      test('should set user ID for existing users', () async {
        // Arrange
        const userId = 'existing_user_456';

        when(() => mockRevenueCat.logIn(any())).thenAnswer((_) async => mockCustomerInfo);

        // Act
        await revenueCatDataSource.setUserId(userId);

        // Assert
        verify(() => mockRevenueCat.logIn(userId)).called(1);
      });

      test('should log out user properly', () async {
        // Arrange
        when(() => mockRevenueCat.logOut()).thenAnswer((_) async => mockCustomerInfo);

        // Act
        await revenueCatDataSource.logOut();

        // Assert
        verify(() => mockRevenueCat.logOut()).called(1);
      });
    });

    group('製品情報の取得', () {
      test('should retrieve available subscription offerings', () async {
        // Arrange
        final mockOfferings = {
          'premium': mockOffering,
        };

        when(() => mockRevenueCat.getOfferings())
            .thenAnswer((_) async => mockOfferings);

        when(() => mockOffering.identifier).thenReturn('premium');
        when(() => mockOffering.serverDescription).thenReturn('Premium Plan');
        when(() => mockOffering.availablePackages).thenReturn([mockPackage]);

        when(() => mockPackage.identifier).thenReturn('monthly');
        when(() => mockPackage.packageType).thenReturn('monthly');
        when(() => mockPackage.product).thenReturn({
          'identifier': 'fatgram_premium_monthly',
          'description': 'FatGram Premium Monthly',
          'title': 'Premium Monthly Subscription',
          'price': 9.99,
          'currencyCode': 'USD',
          'priceString': '\$9.99',
        });

        // Act
        final offerings = await revenueCatDataSource.getOfferings();

        // Assert
        expect(offerings, isNotEmpty);
        expect(offerings.first.id, equals('premium'));
        expect(offerings.first.name, equals('Premium Plan'));
        expect(offerings.first.packages, hasLength(1));

        final package = offerings.first.packages.first;
        expect(package.id, equals('monthly'));
        expect(package.product.price, equals(9.99));
        expect(package.product.currencyCode, equals('USD'));

        verify(() => mockRevenueCat.getOfferings()).called(1);
      });

      test('should return empty list when no offerings available', () async {
        // Arrange
        when(() => mockRevenueCat.getOfferings())
            .thenAnswer((_) async => <String, dynamic>{});

        // Act
        final offerings = await revenueCatDataSource.getOfferings();

        // Assert
        expect(offerings, isEmpty);
      });

      test('should handle API errors when fetching offerings', () async {
        // Arrange
        when(() => mockRevenueCat.getOfferings())
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => revenueCatDataSource.getOfferings(),
          throwsA(isA<SubscriptionFetchFailure>()),
        );
      });

      test('should cache offerings for performance', () async {
        // Arrange
        final mockOfferings = {
          'premium': mockOffering,
        };

        when(() => mockRevenueCat.getOfferings())
            .thenAnswer((_) async => mockOfferings);

        when(() => mockOffering.identifier).thenReturn('premium');
        when(() => mockOffering.serverDescription).thenReturn('Premium Plan');
        when(() => mockOffering.availablePackages).thenReturn([]);

        // Act
        await revenueCatDataSource.getOfferings();
        await revenueCatDataSource.getOfferings(); // Second call

        // Assert
        verify(() => mockRevenueCat.getOfferings()).called(1); // Only once due to caching
      });

      test('should refresh offerings when cache is expired', () async {
        // Arrange
        final mockOfferings = {
          'premium': mockOffering,
        };

        when(() => mockRevenueCat.getOfferings())
            .thenAnswer((_) async => mockOfferings);

        when(() => mockOffering.identifier).thenReturn('premium');
        when(() => mockOffering.serverDescription).thenReturn('Premium Plan');
        when(() => mockOffering.availablePackages).thenReturn([]);

        // Act
        await revenueCatDataSource.getOfferings();
        await revenueCatDataSource.refreshOfferings(); // Force refresh
        await revenueCatDataSource.getOfferings();

        // Assert
        verify(() => mockRevenueCat.getOfferings()).called(2);
      });
    });

    group('購入フローの実装', () {
      test('should successfully purchase a subscription package', () async {
        // Arrange
        const packageId = 'monthly';
        final mockPurchaseResult = {
          'customerInfo': mockCustomerInfo,
          'userCancelled': false,
        };

        when(() => mockRevenueCat.purchasePackage(any()))
            .thenAnswer((_) async => mockPurchaseResult);

        when(() => mockCustomerInfo.entitlements).thenReturn({
          'premium': {
            'isActive': true,
            'willRenew': true,
            'periodType': 'normal',
            'latestPurchaseDate': DateTime.now().millisecondsSinceEpoch,
            'originalPurchaseDate': DateTime.now().millisecondsSinceEpoch,
            'expirationDate': DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch,
            'store': 'app_store',
            'productIdentifier': 'fatgram_premium_monthly',
            'isSandbox': true,
          }
        });

        // Act
        final result = await revenueCatDataSource.purchasePackage(packageId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.customerInfo, isNotNull);
        expect(result.customerInfo!.hasActiveSubscription, isTrue);
        expect(result.userCancelled, isFalse);

        verify(() => mockRevenueCat.purchasePackage(packageId)).called(1);
      });

      test('should handle user cancellation during purchase', () async {
        // Arrange
        const packageId = 'monthly';
        final mockPurchaseResult = {
          'customerInfo': null,
          'userCancelled': true,
        };

        when(() => mockRevenueCat.purchasePackage(any()))
            .thenAnswer((_) async => mockPurchaseResult);

        // Act
        final result = await revenueCatDataSource.purchasePackage(packageId);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.userCancelled, isTrue);
        expect(result.errorMessage, contains('User cancelled'));
      });

      test('should handle purchase errors properly', () async {
        // Arrange
        const packageId = 'monthly';

        when(() => mockRevenueCat.purchasePackage(any()))
            .thenThrow(Exception('Purchase failed: Payment method declined'));

        // Act
        final result = await revenueCatDataSource.purchasePackage(packageId);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.userCancelled, isFalse);
        expect(result.errorMessage, contains('Payment method declined'));
      });

      test('should validate purchase with receipt verification', () async {
        // Arrange
        const packageId = 'monthly';
        const receiptData = 'mock_receipt_data';

        final mockPurchaseResult = {
          'customerInfo': mockCustomerInfo,
          'userCancelled': false,
        };

        when(() => mockRevenueCat.purchasePackage(any()))
            .thenAnswer((_) async => mockPurchaseResult);

        when(() => mockRevenueCat.getCustomerInfo())
            .thenAnswer((_) async => mockCustomerInfo);

        when(() => mockCustomerInfo.entitlements).thenReturn({
          'premium': {
            'isActive': true,
            'willRenew': true,
            'store': 'app_store',
            'productIdentifier': 'fatgram_premium_monthly',
          }
        });

        // Act
        final result = await revenueCatDataSource.purchasePackage(packageId);
        final isValid = await revenueCatDataSource.validateReceipt(receiptData);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(isValid, isTrue);
      });

      test('should handle duplicate purchase attempts', () async {
        // Arrange
        const packageId = 'monthly';

        when(() => mockRevenueCat.purchasePackage(any()))
            .thenThrow(Exception('User already owns this product'));

        // Act
        final result = await revenueCatDataSource.purchasePackage(packageId);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('already owns'));
      });
    });

    group('レシート検証', () {
      test('should validate legitimate receipts', () async {
        // Arrange
        const receiptData = 'valid_receipt_data';

        when(() => mockRevenueCat.getCustomerInfo())
            .thenAnswer((_) async => mockCustomerInfo);

        when(() => mockCustomerInfo.entitlements).thenReturn({
          'premium': {
            'isActive': true,
            'store': 'app_store',
            'productIdentifier': 'fatgram_premium_monthly',
          }
        });

        // Act
        final isValid = await revenueCatDataSource.validateReceipt(receiptData);

        // Assert
        expect(isValid, isTrue);
        verify(() => mockRevenueCat.getCustomerInfo()).called(1);
      });

      test('should reject invalid receipts', () async {
        // Arrange
        const receiptData = 'invalid_receipt_data';

        when(() => mockRevenueCat.getCustomerInfo())
            .thenThrow(Exception('Invalid receipt'));

        // Act
        final isValid = await revenueCatDataSource.validateReceipt(receiptData);

        // Assert
        expect(isValid, isFalse);
      });

      test('should handle network errors during validation', () async {
        // Arrange
        const receiptData = 'some_receipt_data';

        when(() => mockRevenueCat.getCustomerInfo())
            .thenThrow(Exception('Network timeout'));

        // Act
        final isValid = await revenueCatDataSource.validateReceipt(receiptData);

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('復元処理', () {
      test('should restore purchases successfully', () async {
        // Arrange
        when(() => mockRevenueCat.restorePurchases())
            .thenAnswer((_) async => mockCustomerInfo);

        when(() => mockCustomerInfo.entitlements).thenReturn({
          'premium': {
            'isActive': true,
            'willRenew': true,
            'store': 'app_store',
            'productIdentifier': 'fatgram_premium_monthly',
            'latestPurchaseDate': DateTime.now().subtract(Duration(days: 15)).millisecondsSinceEpoch,
            'originalPurchaseDate': DateTime.now().subtract(Duration(days: 15)).millisecondsSinceEpoch,
            'expirationDate': DateTime.now().add(Duration(days: 15)).millisecondsSinceEpoch,
          }
        });

        // Act
        final result = await revenueCatDataSource.restorePurchases();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.customerInfo, isNotNull);
        expect(result.customerInfo!.hasActiveSubscription, isTrue);
        expect(result.restoredProducts, hasLength(1));
        expect(result.restoredProducts.first, equals('fatgram_premium_monthly'));

        verify(() => mockRevenueCat.restorePurchases()).called(1);
      });

      test('should handle no purchases to restore', () async {
        // Arrange
        when(() => mockRevenueCat.restorePurchases())
            .thenAnswer((_) async => mockCustomerInfo);

        when(() => mockCustomerInfo.entitlements).thenReturn({});

        // Act
        final result = await revenueCatDataSource.restorePurchases();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.restoredProducts, isEmpty);
      });

      test('should handle restore failures', () async {
        // Arrange
        when(() => mockRevenueCat.restorePurchases())
            .thenThrow(Exception('Restore failed: No internet connection'));

        // Act
        final result = await revenueCatDataSource.restorePurchases();

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('No internet connection'));
      });

      test('should handle expired subscriptions during restore', () async {
        // Arrange
        when(() => mockRevenueCat.restorePurchases())
            .thenAnswer((_) async => mockCustomerInfo);

        when(() => mockCustomerInfo.entitlements).thenReturn({
          'premium': {
            'isActive': false,
            'willRenew': false,
            'store': 'app_store',
            'productIdentifier': 'fatgram_premium_monthly',
            'expirationDate': DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch,
          }
        });

        // Act
        final result = await revenueCatDataSource.restorePurchases();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.customerInfo!.hasActiveSubscription, isFalse);
        expect(result.restoredProducts, isEmpty); // Expired products not counted
      });
    });

    group('顧客情報の管理', () {
      test('should get current customer info', () async {
        // Arrange
        when(() => mockRevenueCat.getCustomerInfo())
            .thenAnswer((_) async => mockCustomerInfo);

        when(() => mockCustomerInfo.entitlements).thenReturn({
          'premium': {
            'isActive': true,
            'willRenew': true,
            'periodType': 'normal',
            'store': 'app_store',
            'productIdentifier': 'fatgram_premium_monthly',
            'latestPurchaseDate': DateTime.now().millisecondsSinceEpoch,
            'originalPurchaseDate': DateTime.now().subtract(Duration(days: 5)).millisecondsSinceEpoch,
            'expirationDate': DateTime.now().add(Duration(days: 25)).millisecondsSinceEpoch,
          }
        });

        when(() => mockCustomerInfo.originalAppUserId).thenReturn('test_user_123');
        when(() => mockCustomerInfo.activeSubscriptions).thenReturn(['fatgram_premium_monthly']);

        // Act
        final customerInfo = await revenueCatDataSource.getCustomerInfo();

        // Assert
        expect(customerInfo, isNotNull);
        expect(customerInfo.hasActiveSubscription, isTrue);
        expect(customerInfo.userId, equals('test_user_123'));
        expect(customerInfo.activeSubscriptions, hasLength(1));
        expect(customerInfo.premiumEntitlement?.isActive, isTrue);
        expect(customerInfo.premiumEntitlement?.willRenew, isTrue);

        verify(() => mockRevenueCat.getCustomerInfo()).called(1);
      });

      test('should handle customer info fetch errors', () async {
        // Arrange
        when(() => mockRevenueCat.getCustomerInfo())
            .thenThrow(Exception('Failed to fetch customer info'));

        // Act & Assert
        expect(
          () => revenueCatDataSource.getCustomerInfo(),
          throwsA(isA<SubscriptionInfoFailure>()),
        );
      });

      test('should check subscription status correctly', () async {
        // Arrange
        when(() => mockRevenueCat.getCustomerInfo())
            .thenAnswer((_) async => mockCustomerInfo);

        when(() => mockCustomerInfo.entitlements).thenReturn({
          'premium': {
            'isActive': true,
            'willRenew': true,
            'expirationDate': DateTime.now().add(Duration(days: 15)).millisecondsSinceEpoch,
          }
        });

        // Act
        final hasSubscription = await revenueCatDataSource.hasActiveSubscription();
        final daysRemaining = await revenueCatDataSource.getDaysUntilExpiration();

        // Assert
        expect(hasSubscription, isTrue);
        expect(daysRemaining, equals(15));
      });

      test('should handle subscription expiration warnings', () async {
        // Arrange
        when(() => mockRevenueCat.getCustomerInfo())
            .thenAnswer((_) async => mockCustomerInfo);

        when(() => mockCustomerInfo.entitlements).thenReturn({
          'premium': {
            'isActive': true,
            'willRenew': false, // Will not renew
            'expirationDate': DateTime.now().add(Duration(days: 2)).millisecondsSinceEpoch,
          }
        });

        // Act
        final needsRenewal = await revenueCatDataSource.shouldShowRenewalWarning();

        // Assert
        expect(needsRenewal, isTrue);
      });
    });

    group('エラーハンドリングとログ', () {
      test('should log purchase events for analytics', () async {
        // Arrange
        const packageId = 'monthly';
        final mockPurchaseResult = {
          'customerInfo': mockCustomerInfo,
          'userCancelled': false,
        };

        when(() => mockRevenueCat.purchasePackage(any()))
            .thenAnswer((_) async => mockPurchaseResult);

        when(() => mockCustomerInfo.entitlements).thenReturn({
          'premium': {'isActive': true}
        });

        // Act
        final result = await revenueCatDataSource.purchasePackage(packageId);

        // Assert
        expect(result.isSuccess, isTrue);
        // Log verification would be done in actual implementation
      });

      test('should handle rate limiting gracefully', () async {
        // Arrange
        when(() => mockRevenueCat.getOfferings())
            .thenThrow(Exception('Rate limit exceeded'));

        // Act & Assert
        expect(
          () => revenueCatDataSource.getOfferings(),
          throwsA(isA<SubscriptionRateLimitFailure>()),
        );
      });

      test('should provide detailed error messages', () async {
        // Arrange
        const packageId = 'monthly';

        when(() => mockRevenueCat.purchasePackage(any()))
            .thenThrow(Exception('BILLING_UNAVAILABLE: Google Play billing service is not available'));

        // Act
        final result = await revenueCatDataSource.purchasePackage(packageId);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Google Play billing service'));
        expect(result.errorCode, equals('BILLING_UNAVAILABLE'));
      });
    });

    group('プロモーション機能', () {
      test('should apply promotional codes', () async {
        // Arrange
        const promoCode = 'FREEMONTH2024';

        when(() => mockRevenueCat.presentCodeRedemptionSheet())
            .thenAnswer((_) async => null);

        // Act
        final result = await revenueCatDataSource.redeemPromotionalCode(promoCode);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockRevenueCat.presentCodeRedemptionSheet()).called(1);
      });

      test('should handle invalid promotional codes', () async {
        // Arrange
        const promoCode = 'INVALIDCODE';

        when(() => mockRevenueCat.presentCodeRedemptionSheet())
            .thenThrow(Exception('Invalid promotional code'));

        // Act
        final result = await revenueCatDataSource.redeemPromotionalCode(promoCode);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Invalid promotional code'));
      });
    });

    group('サブスクリプション分析', () {
      test('should track subscription conversion metrics', () async {
        // Arrange
        const packageId = 'monthly';
        final startTime = DateTime.now();

        // Act
        await revenueCatDataSource.trackPurchaseAttempt(packageId, startTime);

        // Assert
        // Verification would be done through analytics service
      });

      test('should calculate subscription lifetime value', () async {
        // Arrange
        when(() => mockRevenueCat.getCustomerInfo())
            .thenAnswer((_) async => mockCustomerInfo);

        when(() => mockCustomerInfo.entitlements).thenReturn({
          'premium': {
            'isActive': true,
            'originalPurchaseDate': DateTime.now().subtract(Duration(days: 90)).millisecondsSinceEpoch,
            'store': 'app_store',
            'productIdentifier': 'fatgram_premium_monthly',
          }
        });

        // Act
        final ltv = await revenueCatDataSource.calculateLifetimeValue();

        // Assert
        expect(ltv, greaterThan(0));
      });
    });
  });
}