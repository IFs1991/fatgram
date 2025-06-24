import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:fatgram/presentation/widgets/charts/fat_burn_chart.dart';
import 'package:fatgram/domain/models/weekly_activity_stats.dart';

void main() {
  group('FatBurnChart', () {
    // テストデータ作成
    WeeklyActivityStats createMockWeeklyStats({
      double totalFatBurned = 84.0,
    }) {
      final weekStart = DateTime(2024, 1, 1); // 月曜日
      final weekEnd = DateTime(2024, 1, 7);   // 日曜日

      final dailyStats = List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        return DailyStats(
          date: date,
          fatGramsBurned: 10.0 + (index * 2.0), // 10, 12, 14, 16, 18, 20, 22
          caloriesBurned: 300.0 + (index * 50.0),
          totalDurationInSeconds: 1800 + (index * 300),
          activityCount: 1 + (index % 3),
        );
      });

      return WeeklyActivityStats(
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        dailyStats: dailyStats,
        totalFatGramsBurned: totalFatBurned,
        totalCaloriesBurned: 2100.0,
        totalDurationInSeconds: 16200,
        totalActivityCount: 14,
      );
    }

    Widget createTestWidget({
      required WeeklyActivityStats weeklyStats,
      int period = 1,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FatBurnChart(
            weeklyStats: weeklyStats,
            period: period,
          ),
        ),
      );
    }

    testWidgets('基本的なチャート要素が表示される', (WidgetTester tester) async {
      // Arrange
      final weeklyStats = createMockWeeklyStats();

      // Act
      await tester.pumpWidget(createTestWidget(weeklyStats: weeklyStats));
      await tester.pumpAndSettle(); // アニメーション完了まで待機

      // Assert
      expect(find.text('Fat Burning Progress'), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('期間に応じてタイトルが変わる', (WidgetTester tester) async {
      // Arrange
      final weeklyStats = createMockWeeklyStats();

      // Today
      await tester.pumpWidget(createTestWidget(
        weeklyStats: weeklyStats,
        period: 0,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Today\'s Progress'), findsOneWidget);

      // This Week
      await tester.pumpWidget(createTestWidget(
        weeklyStats: weeklyStats,
        period: 1,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Jan 01 - Jan 07'), findsOneWidget);

      // This Month
      await tester.pumpWidget(createTestWidget(
        weeklyStats: weeklyStats,
        period: 2,
      ));
      await tester.pumpAndSettle();
      expect(find.text('This Month'), findsOneWidget);
    });

    testWidgets('総脂肪燃焼量が正しく表示される', (WidgetTester tester) async {
      // Arrange
      final weeklyStats = createMockWeeklyStats(totalFatBurned: 84.0);

      // Act
      await tester.pumpWidget(createTestWidget(weeklyStats: weeklyStats));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('84.0g'), findsOneWidget);
    });

    testWidgets('凡例が表示される', (WidgetTester tester) async {
      // Arrange
      final weeklyStats = createMockWeeklyStats();

      // Act
      await tester.pumpWidget(createTestWidget(weeklyStats: weeklyStats));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('High Activity'), findsOneWidget);
      expect(find.text('Medium Activity'), findsOneWidget);
      expect(find.text('Low Activity'), findsOneWidget);
    });

    testWidgets('アニメーションが正しく動作する', (WidgetTester tester) async {
      // Arrange
      final weeklyStats = createMockWeeklyStats();

      // Act
      await tester.pumpWidget(createTestWidget(weeklyStats: weeklyStats));

      // アニメーション中にチャートが存在することを確認
      expect(find.byType(BarChart), findsOneWidget);

      // アニメーション完了まで待機
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('空のデータでもクラッシュしない', (WidgetTester tester) async {
      // Arrange
      final emptyStats = WeeklyActivityStats(
        weekStartDate: DateTime(2024, 1, 1),
        weekEndDate: DateTime(2024, 1, 7),
        dailyStats: [],
        totalFatGramsBurned: 0.0,
        totalCaloriesBurned: 0.0,
        totalDurationInSeconds: 0,
        totalActivityCount: 0,
      );

      // Act & Assert
      await tester.pumpWidget(createTestWidget(weeklyStats: emptyStats));
      await tester.pumpAndSettle();

      expect(find.text('Fat Burning Progress'), findsOneWidget);
      expect(find.text('0.0g'), findsOneWidget);
    });

    testWidgets('すべてゼロの日のデータを処理できる', (WidgetTester tester) async {
      // Arrange
      final weekStart = DateTime(2024, 1, 1);
      final weekEnd = DateTime(2024, 1, 7);

      final zeroStats = List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        return DailyStats(
          date: date,
          fatGramsBurned: 0.0,
          caloriesBurned: 0.0,
          totalDurationInSeconds: 0,
          activityCount: 0,
        );
      });

      final weeklyStats = WeeklyActivityStats(
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        dailyStats: zeroStats,
        totalFatGramsBurned: 0.0,
        totalCaloriesBurned: 0.0,
        totalDurationInSeconds: 0,
        totalActivityCount: 0,
      );

      // Act & Assert
      await tester.pumpWidget(createTestWidget(weeklyStats: weeklyStats));
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('0.0g'), findsOneWidget);
    });

    testWidgets('大きな値でも正しく表示される', (WidgetTester tester) async {
      // Arrange
      final largeStats = createMockWeeklyStats(totalFatBurned: 999.5);

      // Act
      await tester.pumpWidget(createTestWidget(weeklyStats: largeStats));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('999.5g'), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('カードの装飾が適用される', (WidgetTester tester) async {
      // Arrange
      final weeklyStats = createMockWeeklyStats();

      // Act
      await tester.pumpWidget(createTestWidget(weeklyStats: weeklyStats));
      await tester.pumpAndSettle();

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 4);
      expect(card.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('バッジコンテナの装飾が適用される', (WidgetTester tester) async {
      // Arrange
      final weeklyStats = createMockWeeklyStats();

      // Act
      await tester.pumpWidget(createTestWidget(weeklyStats: weeklyStats));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('84.0g'), findsOneWidget);

      // コンテナの装飾を確認
      final containerFinder = find.ancestor(
        of: find.text('84.0g'),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('週間統計に基づく正確なデータ表示', (WidgetTester tester) async {
      // Arrange
      final weekStart = DateTime(2024, 1, 1);
      final weekEnd = DateTime(2024, 1, 7);

      // 特定の値でテストデータを作成
      final specificStats = [
        DailyStats(date: weekStart, fatGramsBurned: 5.0, caloriesBurned: 100, totalDurationInSeconds: 600, activityCount: 1),
        DailyStats(date: weekStart.add(const Duration(days: 1)), fatGramsBurned: 10.0, caloriesBurned: 200, totalDurationInSeconds: 1200, activityCount: 1),
        DailyStats(date: weekStart.add(const Duration(days: 2)), fatGramsBurned: 15.0, caloriesBurned: 300, totalDurationInSeconds: 1800, activityCount: 2),
        DailyStats(date: weekStart.add(const Duration(days: 3)), fatGramsBurned: 20.0, caloriesBurned: 400, totalDurationInSeconds: 2400, activityCount: 2),
        DailyStats(date: weekStart.add(const Duration(days: 4)), fatGramsBurned: 25.0, caloriesBurned: 500, totalDurationInSeconds: 3000, activityCount: 3),
        DailyStats(date: weekStart.add(const Duration(days: 5)), fatGramsBurned: 30.0, caloriesBurned: 600, totalDurationInSeconds: 3600, activityCount: 3),
        DailyStats(date: weekStart.add(const Duration(days: 6)), fatGramsBurned: 35.0, caloriesBurned: 700, totalDurationInSeconds: 4200, activityCount: 4),
      ];

      final weeklyStats = WeeklyActivityStats(
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        dailyStats: specificStats,
        totalFatGramsBurned: 140.0, // 5+10+15+20+25+30+35
        totalCaloriesBurned: 2800.0,
        totalDurationInSeconds: 16800,
        totalActivityCount: 16,
      );

      // Act
      await tester.pumpWidget(createTestWidget(weeklyStats: weeklyStats));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('140.0g'), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('Fat Burning Progress'), findsOneWidget);
    });
  });
}