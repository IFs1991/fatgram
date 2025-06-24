import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fatgram/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:fatgram/domain/repositories/activity_repository.dart';
import 'package:fatgram/domain/models/weekly_activity_stats.dart';
import 'package:fatgram/domain/models/activity_model.dart';

// Mocksクラス
class MockActivityRepository extends Mock implements ActivityRepository {}

void main() {
  group('DashboardScreen', () {
    late MockActivityRepository mockActivityRepository;

    setUp(() {
      mockActivityRepository = MockActivityRepository();
    });

    // テストデータ作成
    WeeklyActivityStats createMockWeeklyStats() {
      final weekStart = DateTime.now().subtract(const Duration(days: 7));
      final weekEnd = DateTime.now();

      final dailyStats = List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        return DailyStats(
          date: date,
          fatGramsBurned: 10.0 + (index * 2.0),
          caloriesBurned: 300.0 + (index * 50.0),
          totalDurationInSeconds: 1800 + (index * 300),
          activityCount: 1 + (index % 3),
        );
      });

      return WeeklyActivityStats(
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        dailyStats: dailyStats,
        totalFatGramsBurned: 84.0,
        totalCaloriesBurned: 2100.0,
        totalDurationInSeconds: 16200,
        totalActivityCount: 14,
      );
    }

    List<Activity> createMockActivities() {
      return List.generate(5, (index) {
        return Activity(
          timestamp: DateTime.now().subtract(Duration(days: index)),
          type: ActivityType.values[index % ActivityType.values.length],
          durationInSeconds: 1800 + (index * 300),
          caloriesBurned: 300.0 + (index * 50.0),
          distanceInMeters: index > 0 ? (5000.0 + (index * 1000)) : null,
          userId: 'test-user',
        );
      });
    }

    Widget createTestApp() {
      return MaterialApp(
        home: DashboardScreen(userId: 'test-user-id'),
      );
    }

    testWidgets('初期ローディング状態を表示する', (WidgetTester tester) async {
      // Arrange
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => createMockWeeklyStats());

      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.pumpWidget(createTestApp());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading your health data...'), findsOneWidget);
    });

    testWidgets('データ読み込み完了後にダッシュボードコンテンツを表示する', (WidgetTester tester) async {
      // Arrange
      final weeklyStats = createMockWeeklyStats();
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => weeklyStats);

      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.pumpWidget(createTestApp());

      // データ読み込み完了まで待機
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('FatGram Dashboard'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
    });

    testWidgets('期間選択ボタンをタップできる', (WidgetTester tester) async {
      // Arrange
      final weeklyStats = createMockWeeklyStats();
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => weeklyStats);

      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 期間選択ボタンをタップ
      await tester.tap(find.text('This Week'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('This Week'), findsOneWidget);

      // 別の期間をタップ
      await tester.tap(find.text('This Month'));
      await tester.pumpAndSettle();

      expect(find.text('This Month'), findsOneWidget);
    });

    testWidgets('エラー状態を正しく表示する', (WidgetTester tester) async {
      // Arrange
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenThrow(Exception('Network error'));

      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenThrow(Exception('Network error'));

      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Failed to load dashboard data: Exception: Network error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('Try Againボタンでリトライできる', (WidgetTester tester) async {
      // Arrange
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenThrow(Exception('Network error'));

      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 成功するように変更
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => createMockWeeklyStats());

      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('FatGram Dashboard'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
    });

    testWidgets('アクションボタンが表示される', (WidgetTester tester) async {
      // Arrange
      final weeklyStats = createMockWeeklyStats();
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => weeklyStats);

      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('最近のアクティビティが表示される', (WidgetTester tester) async {
      // Arrange
      final weeklyStats = createMockWeeklyStats();
      final activities = createMockActivities();
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => weeklyStats);

      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => activities);

      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Recent Activities'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
    });

    testWidgets('グリーティングメッセージが時間帯に応じて変わる', (WidgetTester tester) async {
      // Arrange
      final weeklyStats = createMockWeeklyStats();
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => weeklyStats);

      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Assert
      // グリーティングメッセージが存在することを確認
      final greetingMessages = [
        'Good morning! Ready to burn some fat?',
        'Good afternoon! Keep up the great work!',
        'Good evening! Time to check your progress!',
      ];

      bool foundMessage = false;
      for (final message in greetingMessages) {
        if (find.text(message).evaluate().isNotEmpty) {
          foundMessage = true;
          break;
        }
      }
      expect(foundMessage, isTrue, reason: 'No greeting message found');
    });

    testWidgets('スライバーレイアウトが正しく動作する', (WidgetTester tester) async {
      // Arrange
      final weeklyStats = createMockWeeklyStats();
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => weeklyStats);

      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
    });
  });
}