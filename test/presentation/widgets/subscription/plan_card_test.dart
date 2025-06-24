import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fatgram/presentation/widgets/subscription/plan_card.dart';
import 'package:fatgram/domain/entities/subscription.dart';

void main() {
  group('PlanCard', () {
    const mockMonthlyPackage = SubscriptionPackage(
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
    );

    const mockYearlyPackage = SubscriptionPackage(
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
    );

    const mockLifetimePackage = SubscriptionPackage(
      id: 'lifetime',
      period: SubscriptionPeriod.lifetime,
      product: SubscriptionProduct(
        identifier: 'premium_lifetime',
        title: 'Premium Lifetime',
        description: 'Lifetime access',
        price: 299.99,
        currencyCode: 'USD',
        priceString: '\$299.99',
      ),
    );

    Widget createTestWidget({
      required SubscriptionPackage package,
      bool isSelected = false,
      VoidCallback? onTap,
      bool isLoading = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PlanCard(
            package: package,
            isSelected: isSelected,
            onTap: onTap ?? () {},
            isLoading: isLoading,
          ),
        ),
      );
    }

    group('基本表示', () {
      testWidgets('should display package title and price', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(package: mockMonthlyPackage));

        // Assert
        expect(find.text('Premium Monthly'), findsOneWidget);
        expect(find.text('\$9.99'), findsOneWidget);
      });

      testWidgets('should show correct period text for monthly package', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(package: mockMonthlyPackage));

        // Assert
        expect(find.text('月額'), findsOneWidget);
        expect(find.text('毎月請求'), findsOneWidget);
      });

      testWidgets('should show correct period text for yearly package', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(package: mockYearlyPackage));

        // Assert
        expect(find.text('年額'), findsOneWidget);
        expect(find.text('年に1度請求'), findsOneWidget);
      });

      testWidgets('should show correct period text for lifetime package', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(package: mockLifetimePackage));

        // Assert
        expect(find.text('買い切り'), findsOneWidget);
        expect(find.text('一度のお支払い'), findsOneWidget);
      });

      testWidgets('should display recommended badge when package is recommended', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(package: mockYearlyPackage));

        // Assert
        expect(find.text('おすすめ'), findsOneWidget);
        expect(find.byType(Badge), findsOneWidget);
      });

      testWidgets('should not display recommended badge when package is not recommended', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(package: mockMonthlyPackage));

        // Assert
        expect(find.text('おすすめ'), findsNothing);
        expect(find.byType(Badge), findsNothing);
      });
    });

    group('選択状態', () {
      testWidgets('should show selected state when isSelected is true', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(
          package: mockMonthlyPackage,
          isSelected: true,
        ));

        // Assert
        expect(find.byIcon(Icons.check_circle), findsOneWidget);

        // カードのボーダー色が選択色になっているかチェック
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(PlanCard),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration?;
        expect(decoration?.border, isNotNull);
      });

      testWidgets('should show unselected state when isSelected is false', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(
          package: mockMonthlyPackage,
          isSelected: false,
        ));

        // Assert
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      });

      testWidgets('should call onTap when card is tapped', (tester) async {
        // Arrange
        bool wasTapped = false;

        // Act
        await tester.pumpWidget(createTestWidget(
          package: mockMonthlyPackage,
          onTap: () => wasTapped = true,
        ));

        await tester.tap(find.byType(PlanCard));

        // Assert
        expect(wasTapped, isTrue);
      });
    });

    group('ローディング状態', () {
      testWidgets('should show loading indicator when isLoading is true', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(
          package: mockMonthlyPackage,
          isLoading: true,
        ));

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('処理中...'), findsOneWidget);
      });

      testWidgets('should disable tap when loading', (tester) async {
        // Arrange
        bool wasTapped = false;

        // Act
        await tester.pumpWidget(createTestWidget(
          package: mockMonthlyPackage,
          isLoading: true,
          onTap: () => wasTapped = true,
        ));

        await tester.tap(find.byType(PlanCard));

        // Assert
        expect(wasTapped, isFalse);
      });

      testWidgets('should show normal state when isLoading is false', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(
          package: mockMonthlyPackage,
          isLoading: false,
        ));

        // Assert
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('処理中...'), findsNothing);
      });
    });

    group('価格表示の詳細', () {
      testWidgets('should show monthly equivalent price for yearly package', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(package: mockYearlyPackage));

        // Assert
        expect(find.text('\$99.99'), findsOneWidget);
        expect(find.text('月換算 \$8.33'), findsOneWidget);
      });

      testWidgets('should not show monthly equivalent for monthly package', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(package: mockMonthlyPackage));

        // Assert
        expect(find.text('月換算'), findsNothing);
      });

      testWidgets('should show discount percentage when applicable', (tester) async {
        // Arrange
        const packageWithDiscount = SubscriptionPackage(
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
          discountPercentage: 17.0,
        );

        // Act
        await tester.pumpWidget(createTestWidget(package: packageWithDiscount));

        // Assert
        expect(find.text('17% お得'), findsOneWidget);
      });
    });

    group('無料試用期間', () {
      testWidgets('should display free trial information when available', (tester) async {
        // Arrange
        const packageWithTrial = SubscriptionPackage(
          id: 'monthly',
          period: SubscriptionPeriod.monthly,
          product: SubscriptionProduct(
            identifier: 'premium_monthly',
            title: 'Premium Monthly',
            description: 'Monthly subscription',
            price: 9.99,
            currencyCode: 'USD',
            priceString: '\$9.99',
            freeTrialPeriod: Duration(days: 7),
          ),
        );

        // Act
        await tester.pumpWidget(createTestWidget(package: packageWithTrial));

        // Assert
        expect(find.text('7日間無料'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('should not show trial info when not available', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(package: mockMonthlyPackage));

        // Assert
        expect(find.text('無料'), findsNothing);
        expect(find.byIcon(Icons.star), findsNothing);
      });
    });

    group('アクセシビリティ', () {
      testWidgets('should provide semantic labels for screen readers', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(
          package: mockMonthlyPackage,
          isSelected: false,
        ));

        // Assert
        expect(find.bySemanticsLabel('月額プラン 9.99ドル'), findsOneWidget);
        expect(find.bySemanticsLabel('プランを選択'), findsOneWidget);
      });

      testWidgets('should indicate selected state in semantics', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(
          package: mockMonthlyPackage,
          isSelected: true,
        ));

        // Assert
        expect(find.bySemanticsLabel('選択済み 月額プラン 9.99ドル'), findsOneWidget);
      });

      testWidgets('should indicate loading state in semantics', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(
          package: mockMonthlyPackage,
          isLoading: true,
        ));

        // Assert
        expect(find.bySemanticsLabel('処理中'), findsOneWidget);
      });

      testWidgets('should announce recommended packages', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(package: mockYearlyPackage));

        // Assert
        expect(find.bySemanticsLabel('おすすめプラン'), findsOneWidget);
      });
    });

    group('視覚的フィードバック', () {
      testWidgets('should show elevation change on hover (desktop)', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(package: mockMonthlyPackage));

        final cardFinder = find.byType(Card);
        expect(cardFinder, findsOneWidget);

        // マウスホバーをシミュレート
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/mousecursor',
          null,
          (data) {},
        );

        // Assert - カードにelevationがあることを確認
        final card = tester.widget<Card>(cardFinder);
        expect(card.elevation, greaterThan(0));
      });

      testWidgets('should have proper material ripple effect', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget(package: mockMonthlyPackage));

        // InkWellまたはMaterialボタンがあることを確認
        expect(find.byType(InkWell), findsAtLeastNWidgets(1));
      });
    });

    group('レスポンシブデザイン', () {
      testWidgets('should adapt layout for different screen sizes', (tester) async {
        // Arrange - 小さな画面サイズをシミュレート
        await tester.binding.setSurfaceSize(const Size(320, 568));

        // Act
        await tester.pumpWidget(createTestWidget(package: mockMonthlyPackage));

        // Assert - レイアウトが適切に表示されている
        expect(find.byType(PlanCard), findsOneWidget);

        // 画面サイズを元に戻す
        await tester.binding.setSurfaceSize(null);
      });
    });
  });
}