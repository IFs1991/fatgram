import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fatgram/presentation/screens/subscription/subscription_screen.dart';
import 'package:fatgram/domain/entities/subscription.dart';
import 'package:fatgram/domain/repositories/subscription_repository.dart';
import 'package:fatgram/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../../../test_helper.dart';

// Mock classes
class MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

void main() {
  late MockSubscriptionRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
    registerFallbackValue(const Duration(seconds: 1));
  });

  setUp(() {
    mockRepository = MockSubscriptionRepository();
  });

  Widget createTestWidget({SubscriptionRepository? repository}) {
    return MaterialApp(
      home: SubscriptionScreen(
        repository: repository ?? mockRepository,
      ),
    );
  }

  group('SubscriptionScreen', () {
    group('初期化とローディング状態', () {
      testWidgets('should show loading indicator when fetching offerings', (tester) async {
        // Arrange
        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => Future.delayed(
                const Duration(milliseconds: 100),
                () => const Right(<SubscriptionOffering>[]),
              ));

        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('FatGram Premium'), findsOneWidget);
        expect(find.text('プランを読み込み中...'), findsOneWidget);
      });

      testWidgets('should show app bar with title and close button', (tester) async {
        // Arrange
        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => const Right(<SubscriptionOffering>[]));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('FatGram Premium'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should close screen when close button is tapped', (tester) async {
        // Arrange
        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => const Right(<SubscriptionOffering>[]));

        bool screenClosed = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubscriptionScreen(repository: mockRepository),
                      ),
                    );
                    if (result == null) screenClosed = true;
                  },
                  child: const Text('Open Subscription'),
                ),
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Open Subscription'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Assert
        expect(screenClosed, isTrue);
      });
    });

    group('プラン表示', () {
      testWidgets('should display subscription offerings when loaded', (tester) async {
        // Arrange
        final offerings = [
          const SubscriptionOffering(
            id: 'premium',
            name: 'Premium プラン',
            description: 'すべての機能にアクセス',
            packages: [
              SubscriptionPackage(
                id: 'monthly',
                period: SubscriptionPeriod.monthly,
                product: SubscriptionProduct(
                  identifier: 'premium_monthly',
                  title: 'Premium Monthly',
                  description: 'Monthly subscription',
                  price: 9.99,
                  currencyCode: 'USD',
                  priceString: '\$9.99',
                ),
              ),
              SubscriptionPackage(
                id: 'yearly',
                period: SubscriptionPeriod.yearly,
                product: SubscriptionProduct(
                  identifier: 'premium_yearly',
                  title: 'Premium Yearly',
                  description: 'Yearly subscription',
                  price: 99.99,
                  currencyCode: 'USD',
                  priceString: '\$99.99',
                ),
                isRecommended: true,
              ),
            ],
          ),
        ];

        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => Right(offerings));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Premium プラン'), findsOneWidget);
        expect(find.text('すべての機能にアクセス'), findsOneWidget);
        expect(find.text('\$9.99'), findsOneWidget);
        expect(find.text('\$99.99'), findsOneWidget);
        expect(find.text('おすすめ'), findsOneWidget);
      });

      testWidgets('should show monthly and yearly package options', (tester) async {
        // Arrange
        final offerings = [
          const SubscriptionOffering(
            id: 'premium',
            name: 'Premium プラン',
            description: 'すべての機能にアクセス',
            packages: [
              SubscriptionPackage(
                id: 'monthly',
                period: SubscriptionPeriod.monthly,
                product: SubscriptionProduct(
                  identifier: 'premium_monthly',
                  title: 'Premium Monthly',
                  description: 'Monthly subscription',
                  price: 9.99,
                  currencyCode: 'USD',
                  priceString: '\$9.99',
                ),
              ),
              SubscriptionPackage(
                id: 'yearly',
                period: SubscriptionPeriod.yearly,
                product: SubscriptionProduct(
                  identifier: 'premium_yearly',
                  title: 'Premium Yearly',
                  description: 'Yearly subscription',
                  price: 99.99,
                  currencyCode: 'USD',
                  priceString: '\$99.99',
                ),
              ),
            ],
          ),
        ];

        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => Right(offerings));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('月額'), findsOneWidget);
        expect(find.text('年額'), findsOneWidget);
        expect(find.text('毎月請求'), findsOneWidget);
        expect(find.text('年に1度請求'), findsOneWidget);
      });

      testWidgets('should highlight recommended package', (tester) async {
        // Arrange
        final offerings = [
          const SubscriptionOffering(
            id: 'premium',
            name: 'Premium プラン',
            description: 'すべての機能にアクセス',
            packages: [
              SubscriptionPackage(
                id: 'yearly',
                period: SubscriptionPeriod.yearly,
                product: SubscriptionProduct(
                  identifier: 'premium_yearly',
                  title: 'Premium Yearly',
                  description: 'Yearly subscription',
                  price: 99.99,
                  currencyCode: 'USD',
                  priceString: '\$99.99',
                ),
                isRecommended: true,
              ),
            ],
          ),
        ];

        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => Right(offerings));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('おすすめ'), findsOneWidget);
        expect(find.byType(Badge), findsOneWidget);
      });

      testWidgets('should show empty state when no offerings available', (tester) async {
        // Arrange
        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => const Right(<SubscriptionOffering>[]));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('現在利用可能なプランはありません'), findsOneWidget);
        expect(find.text('後でもう一度お試しください'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });
    });

    group('購入ボタンの動作', () {
      testWidgets('should show purchase button for each package', (tester) async {
        // Arrange
        final offerings = [
          const SubscriptionOffering(
            id: 'premium',
            name: 'Premium プラン',
            description: 'すべての機能にアクセス',
            packages: [
              SubscriptionPackage(
                id: 'monthly',
                period: SubscriptionPeriod.monthly,
                product: SubscriptionProduct(
                  identifier: 'premium_monthly',
                  title: 'Premium Monthly',
                  description: 'Monthly subscription',
                  price: 9.99,
                  currencyCode: 'USD',
                  priceString: '\$9.99',
                ),
              ),
            ],
          ),
        ];

        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => Right(offerings));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('購入する'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
      });

      testWidgets('should trigger purchase when purchase button is tapped', (tester) async {
        // Arrange
        final offerings = [
          const SubscriptionOffering(
            id: 'premium',
            name: 'Premium プラン',
            description: 'すべての機能にアクセス',
            packages: [
              SubscriptionPackage(
                id: 'monthly',
                period: SubscriptionPeriod.monthly,
                product: SubscriptionProduct(
                  identifier: 'premium_monthly',
                  title: 'Premium Monthly',
                  description: 'Monthly subscription',
                  price: 9.99,
                  currencyCode: 'USD',
                  priceString: '\$9.99',
                ),
              ),
            ],
          ),
        ];

        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => Right(offerings));

        when(() => mockRepository.purchasePackage('monthly'))
            .thenAnswer((_) async => const Right(
              PurchaseResult(
                isSuccess: true,
                userCancelled: false,
              ),
            ));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.text('購入する'));
        await tester.pump();

        // Assert
        verify(() => mockRepository.purchasePackage('monthly')).called(1);
      });

      testWidgets('should show loading state during purchase', (tester) async {
        // Arrange
        final offerings = [
          const SubscriptionOffering(
            id: 'premium',
            name: 'Premium プラン',
            description: 'すべての機能にアクセス',
            packages: [
              SubscriptionPackage(
                id: 'monthly',
                period: SubscriptionPeriod.monthly,
                product: SubscriptionProduct(
                  identifier: 'premium_monthly',
                  title: 'Premium Monthly',
                  description: 'Monthly subscription',
                  price: 9.99,
                  currencyCode: 'USD',
                  priceString: '\$9.99',
                ),
              ),
            ],
          ),
        ];

        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => Right(offerings));

        when(() => mockRepository.purchasePackage('monthly'))
            .thenAnswer((_) => Future.delayed(
              const Duration(milliseconds: 100),
              () => const Right(PurchaseResult(isSuccess: true, userCancelled: false)),
            ));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.text('購入する'));
        await tester.pump();

        // Assert
        expect(find.text('購入中...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      });

      testWidgets('should show success message after successful purchase', (tester) async {
        // Arrange
        final offerings = [
          const SubscriptionOffering(
            id: 'premium',
            name: 'Premium プラン',
            description: 'すべての機能にアクセス',
            packages: [
              SubscriptionPackage(
                id: 'monthly',
                period: SubscriptionPeriod.monthly,
                product: SubscriptionProduct(
                  identifier: 'premium_monthly',
                  title: 'Premium Monthly',
                  description: 'Monthly subscription',
                  price: 9.99,
                  currencyCode: 'USD',
                  priceString: '\$9.99',
                ),
              ),
            ],
          ),
        ];

        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => Right(offerings));

        when(() => mockRepository.purchasePackage('monthly'))
            .thenAnswer((_) async => const Right(
              PurchaseResult(
                isSuccess: true,
                userCancelled: false,
              ),
            ));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.text('購入する'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('購入が完了しました！'), findsOneWidget);
        expect(find.text('FatGram Premiumをお楽しみください'), findsOneWidget);
      });
    });

    group('エラーハンドリング', () {
      testWidgets('should show error when failing to load offerings', (tester) async {
        // Arrange
        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => const Left(
              NetworkFailure(message: 'インターネット接続を確認してください'),
            ));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('エラーが発生しました'), findsOneWidget);
        expect(find.text('インターネット接続を確認してください'), findsOneWidget);
        expect(find.text('再試行'), findsOneWidget);
      });

      testWidgets('should retry loading when retry button is tapped', (tester) async {
        // Arrange
        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => const Left(
              NetworkFailure(message: 'インターネット接続を確認してください'),
            ));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.text('再試行'));
        await tester.pump();

        // Assert
        verify(() => mockRepository.getOfferings()).called(2);
      });

      testWidgets('should show error dialog when purchase fails', (tester) async {
        // Arrange
        final offerings = [
          const SubscriptionOffering(
            id: 'premium',
            name: 'Premium プラン',
            description: 'すべての機能にアクセス',
            packages: [
              SubscriptionPackage(
                id: 'monthly',
                period: SubscriptionPeriod.monthly,
                product: SubscriptionProduct(
                  identifier: 'premium_monthly',
                  title: 'Premium Monthly',
                  description: 'Monthly subscription',
                  price: 9.99,
                  currencyCode: 'USD',
                  priceString: '\$9.99',
                ),
              ),
            ],
          ),
        ];

        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => Right(offerings));

        when(() => mockRepository.purchasePackage('monthly'))
            .thenAnswer((_) async => const Left(
              SubscriptionPurchaseFailure(message: '支払い方法が拒否されました'),
            ));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.text('購入する'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('購入エラー'), findsOneWidget);
        expect(find.text('支払い方法が拒否されました'), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);
      });

      testWidgets('should handle user cancellation gracefully', (tester) async {
        // Arrange
        final offerings = [
          const SubscriptionOffering(
            id: 'premium',
            name: 'Premium プラン',
            description: 'すべての機能にアクセス',
            packages: [
              SubscriptionPackage(
                id: 'monthly',
                period: SubscriptionPeriod.monthly,
                product: SubscriptionProduct(
                  identifier: 'premium_monthly',
                  title: 'Premium Monthly',
                  description: 'Monthly subscription',
                  price: 9.99,
                  currencyCode: 'USD',
                  priceString: '\$9.99',
                ),
              ),
            ],
          ),
        ];

        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => Right(offerings));

        when(() => mockRepository.purchasePackage('monthly'))
            .thenAnswer((_) async => const Right(
              PurchaseResult(
                isSuccess: false,
                userCancelled: true,
                errorMessage: 'User cancelled the purchase',
              ),
            ));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.text('購入する'));
        await tester.pumpAndSettle();

        // Assert
        // ユーザーキャンセルの場合はエラーダイアログを表示しない
        expect(find.text('購入エラー'), findsNothing);
      });
    });

    group('復元機能', () {
      testWidgets('should show restore purchases button', (tester) async {
        // Arrange
        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => const Right(<SubscriptionOffering>[]));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('購入を復元'), findsOneWidget);
      });

      testWidgets('should trigger restore when restore button is tapped', (tester) async {
        // Arrange
        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => const Right(<SubscriptionOffering>[]));

        when(() => mockRepository.restorePurchases())
            .thenAnswer((_) async => const Right(
              RestoreResult(
                isSuccess: true,
                restoredProducts: ['premium_monthly'],
              ),
            ));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.text('購入を復元'));
        await tester.pump();

        // Assert
        verify(() => mockRepository.restorePurchases()).called(1);
      });

      testWidgets('should show success message after successful restore', (tester) async {
        // Arrange
        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => const Right(<SubscriptionOffering>[]));

        when(() => mockRepository.restorePurchases())
            .thenAnswer((_) async => const Right(
              RestoreResult(
                isSuccess: true,
                restoredProducts: ['premium_monthly'],
              ),
            ));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.text('購入を復元'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('復元完了'), findsOneWidget);
        expect(find.text('1つの購入を復元しました'), findsOneWidget);
      });
    });

    group('アクセシビリティ', () {
      testWidgets('should provide semantic labels for screen readers', (tester) async {
        // Arrange
        final offerings = [
          const SubscriptionOffering(
            id: 'premium',
            name: 'Premium プラン',
            description: 'すべての機能にアクセス',
            packages: [
              SubscriptionPackage(
                id: 'monthly',
                period: SubscriptionPeriod.monthly,
                product: SubscriptionProduct(
                  identifier: 'premium_monthly',
                  title: 'Premium Monthly',
                  description: 'Monthly subscription',
                  price: 9.99,
                  currencyCode: 'USD',
                  priceString: '\$9.99',
                ),
              ),
            ],
          ),
        ];

        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => Right(offerings));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.bySemanticsLabel('Premium プラン'), findsOneWidget);
        expect(find.bySemanticsLabel('月額プラン 9.99ドル'), findsOneWidget);
        expect(find.bySemanticsLabel('プランを購入'), findsOneWidget);
      });

      testWidgets('should support keyboard navigation', (tester) async {
        // Arrange
        when(() => mockRepository.getOfferings())
            .thenAnswer((_) async => const Right(<SubscriptionOffering>[]));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Focus), findsAtLeastNWidgets(1));
      });
    });
  });
}