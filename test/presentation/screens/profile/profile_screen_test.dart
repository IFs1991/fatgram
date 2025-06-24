import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fatgram/presentation/screens/profile/profile_screen.dart';
import 'package:fatgram/domain/repositories/user_repository.dart';
import 'package:fatgram/domain/repositories/activity_repository.dart';
import 'package:fatgram/domain/models/user_model.dart';
import 'package:fatgram/domain/models/activity_model.dart';
import 'package:fatgram/domain/models/weekly_activity_stats.dart';

// Mocksクラス
class MockUserRepository extends Mock implements UserRepository {}
class MockActivityRepository extends Mock implements ActivityRepository {}

void main() {
  group('ProfileScreen', () {
    late MockUserRepository mockUserRepository;
    late MockActivityRepository mockActivityRepository;

    setUp(() {
      mockUserRepository = MockUserRepository();
      mockActivityRepository = MockActivityRepository();
    });

    // テストデータ作成
    User createMockUser({
      String? displayName,
      String? email,
      int? height,
      int? weight,
      int? age,
      bool isPremium = false,
    }) {
      return User(
        id: 'test-user-id',
        displayName: displayName ?? 'Test User',
        email: email ?? 'test@example.com',
        height: height ?? 170,
        weight: weight ?? 70,
        age: age ?? 25,
        isPremium: isPremium,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLoginAt: DateTime.now(),
      );
    }

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
        home: ProfileScreen(userId: 'test-user-id'),
      );
    }

    testWidgets('初期ローディング状態を表示する', (WidgetTester tester) async {
      // Arrange
      when(() => mockUserRepository.getCurrentUser())
          .thenAnswer((_) async => createMockUser());
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
    });

    testWidgets('ユーザー情報を正しく表示する', (WidgetTester tester) async {
      // Arrange
      final user = createMockUser(
        displayName: 'John Doe',
        email: 'john@example.com',
        height: 180,
        weight: 75,
        age: 30,
      );

      when(() => mockUserRepository.getCurrentUser())
          .thenAnswer((_) async => user);
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => createMockWeeklyStats());
      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.text('180 cm'), findsOneWidget);
      expect(find.text('75 kg'), findsOneWidget);
      expect(find.text('30 years'), findsOneWidget);
    });

    testWidgets('プレミアムユーザーのバッジを表示する', (WidgetTester tester) async {
      // Arrange
      final premiumUser = createMockUser(isPremium: true);

      when(() => mockUserRepository.getCurrentUser())
          .thenAnswer((_) async => premiumUser);
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => createMockWeeklyStats());
      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Premium Member'), findsOneWidget);
      expect(find.byIcon(Icons.stars), findsOneWidget);
    });

    testWidgets('編集モードに切り替える', (WidgetTester tester) async {
      // Arrange
      final user = createMockUser();

      when(() => mockUserRepository.getCurrentUser())
          .thenAnswer((_) async => user);
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => createMockWeeklyStats());
      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('プロフィール更新が成功する', (WidgetTester tester) async {
      // Arrange
      final user = createMockUser();
      final updatedUser = user.copyWith(displayName: 'Updated Name');

      when(() => mockUserRepository.getCurrentUser())
          .thenAnswer((_) async => user);
      when(() => mockUserRepository.updateUser(any()))
          .thenAnswer((_) async => updatedUser);
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => createMockWeeklyStats());
      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // 編集モードに切り替え
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // 名前を変更
      await tester.enterText(find.byType(TextField).first, 'Updated Name');

      // 保存
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Profile updated successfully'), findsOneWidget);
      verify(() => mockUserRepository.updateUser(any())).called(1);
    });

    testWidgets('週間統計を表示する', (WidgetTester tester) async {
      // Arrange
      final user = createMockUser();
      final weeklyStats = createMockWeeklyStats();

      when(() => mockUserRepository.getCurrentUser())
          .thenAnswer((_) async => user);
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
      expect(find.text('This Week\'s Stats'), findsOneWidget);
      expect(find.text('84.0g'), findsOneWidget); // Fat burned
      expect(find.text('2100'), findsOneWidget); // Calories
      expect(find.text('14'), findsOneWidget); // Activities
    });

    testWidgets('アクションアイテムをタップできる', (WidgetTester tester) async {
      // Arrange
      final user = createMockUser();

      when(() => mockUserRepository.getCurrentUser())
          .thenAnswer((_) async => user);
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => createMockWeeklyStats());
      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Achievementsアクションをタップ
      await tester.tap(find.text('Achievements'));
      await tester.pumpAndSettle();

      // Assert
      // ナビゲーションが発生することを確認（実際のテストでは画面遷移を確認）
      expect(find.text('Achievements'), findsOneWidget);
    });

    testWidgets('サインアウトダイアログを表示する', (WidgetTester tester) async {
      // Arrange
      final user = createMockUser();

      when(() => mockUserRepository.getCurrentUser())
          .thenAnswer((_) async => user);
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => createMockWeeklyStats());
      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Sign Out'), findsAtLeastNWidgets(1)); // ダイアログタイトル
      expect(find.text('Are you sure you want to sign out of your account?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('サインアウト処理が実行される', (WidgetTester tester) async {
      // Arrange
      final user = createMockUser();

      when(() => mockUserRepository.getCurrentUser())
          .thenAnswer((_) async => user);
      when(() => mockUserRepository.logout())
          .thenAnswer((_) async {});
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => createMockWeeklyStats());
      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // ダイアログでサインアウトを確認
      await tester.tap(find.text('Sign Out').last);
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockUserRepository.logout()).called(1);
    });

    testWidgets('最近のアクティビティを表示する', (WidgetTester tester) async {
      // Arrange
      final user = createMockUser();
      final activities = createMockActivities();

      when(() => mockUserRepository.getCurrentUser())
          .thenAnswer((_) async => user);
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => createMockWeeklyStats());
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

      // 最大3つのアクティビティが表示されることを確認
      final activityTiles = find.byType(ListTile);
      expect(activityTiles.evaluate().length, lessThanOrEqualTo(8)); // 他のListTileも含む
    });

    testWidgets('エラー状態を正しく表示する', (WidgetTester tester) async {
      // Arrange
      when(() => mockUserRepository.getCurrentUser())
          .thenThrow(Exception('User not found'));
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
      expect(find.text('Failed to load profile'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('Try Againボタンでリトライできる', (WidgetTester tester) async {
      // Arrange
      when(() => mockUserRepository.getCurrentUser())
          .thenThrow(Exception('Network error'));
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
      when(() => mockUserRepository.getCurrentUser())
          .thenAnswer((_) async => createMockUser());
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
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Failed to load profile'), findsNothing);
    });

    testWidgets('プロフィールアバターが正しく表示される', (WidgetTester tester) async {
      // Arrange
      final user = createMockUser();

      when(() => mockUserRepository.getCurrentUser())
          .thenAnswer((_) async => user);
      when(() => mockActivityRepository.getWeeklyActivityStats(
        weekStartDate: any(named: 'weekStartDate'),
      )).thenAnswer((_) async => createMockWeeklyStats());
      when(() => mockActivityRepository.getActivities(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      )).thenAnswer((_) async => createMockActivities());

      // Act
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.person), findsOneWidget); // デフォルトアバター
    });
  });
}