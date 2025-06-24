import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'test_helper.dart';
import 'fixtures/fixture_reader.dart';

void main() {
  group('TestHelper', () {
    test('generateUserData should return valid user data', () {
      // Act
      final userData = TestHelper.generateUserData();

      // Assert
      expect(userData, isA<Map<String, dynamic>>());
      expect(userData['id'], isNotNull);
      expect(userData['name'], isNotNull);
      expect(userData['email'], isNotNull);
      expect(userData['age'], isA<int>());
      expect(userData['weight'], isA<double>());
      expect(userData['height'], isA<double>());
      expect(userData['createdAt'], CustomMatchers.isValidDateString());

      // 年齢の範囲チェック
      expect(userData['age'], greaterThanOrEqualTo(18));
      expect(userData['age'], lessThanOrEqualTo(100));

      // 体重の範囲チェック
      expect(userData['weight'], CustomMatchers.isPositiveNumber());
      expect(userData['weight'], greaterThanOrEqualTo(40));

      // 身長の範囲チェック
      expect(userData['height'], CustomMatchers.isPositiveNumber());
      expect(userData['height'], greaterThanOrEqualTo(140));
    });

    test('generateActivityData should return valid activity data', () {
      // Act
      final activityData = TestHelper.generateActivityData();

      // Assert
      expect(activityData, isA<Map<String, dynamic>>());
      expect(activityData['id'], isNotNull);
      expect(activityData['type'], isIn(['running', 'walking', 'cycling', 'swimming']));
      expect(activityData['duration'], isA<int>());
      expect(activityData['calories'], isA<int>());
      expect(activityData['distance'], isA<double>());
      expect(activityData['heartRate'], isA<int>());
      expect(activityData['startTime'], CustomMatchers.isValidDateString());
      expect(activityData['endTime'], CustomMatchers.isValidDateString());

      // 値の範囲チェック
      expect(activityData['duration'], greaterThanOrEqualTo(300)); // 5分以上
      expect(activityData['duration'], lessThanOrEqualTo(7200)); // 2時間以下
      expect(activityData['calories'], greaterThanOrEqualTo(50));
      expect(activityData['calories'], lessThanOrEqualTo(1000));
      expect(activityData['heartRate'], greaterThanOrEqualTo(60));
      expect(activityData['heartRate'], lessThanOrEqualTo(200));
    });

    test('generateHealthData should return valid health data', () {
      // Act
      final healthData = TestHelper.generateHealthData();

      // Assert
      expect(healthData, isA<Map<String, dynamic>>());
      expect(healthData['id'], isNotNull);
      expect(healthData['type'], isIn(['steps', 'heartRate', 'weight', 'sleep']));
      expect(healthData['value'], isA<double>());
      expect(healthData['unit'], isIn(['count', 'bpm', 'kg', 'hours']));
      expect(healthData['timestamp'], CustomMatchers.isValidDateString());
      expect(healthData['value'], CustomMatchers.isPositiveNumber());
    });

    test('generateErrorResponse should return valid error response', () {
      // Act
      final errorResponse = TestHelper.generateErrorResponse();

      // Assert
      expect(errorResponse, isA<Map<String, dynamic>>());
      expect(errorResponse['statusCode'], equals(400));
      expect(errorResponse['message'], isNotNull);
      expect(errorResponse['timestamp'], CustomMatchers.isValidDateString());
    });

    test('generateErrorResponse with custom parameters should return custom error', () {
      // Arrange
      const customStatusCode = 500;
      const customMessage = 'Custom error message';

      // Act
      final errorResponse = TestHelper.generateErrorResponse(
        statusCode: customStatusCode,
        message: customMessage,
      );

      // Assert
      expect(errorResponse['statusCode'], equals(customStatusCode));
      expect(errorResponse['message'], equals(customMessage));
    });

    test('createMockResponse should return valid response structure', () {
      // Arrange
      final testData = {'test': 'data'};

      // Act
      final response = TestHelper.createMockResponse(data: testData);

      // Assert
      expect(response, isA<Map<String, dynamic>>());
      expect(response['success'], isTrue);
      expect(response['data'], equals(testData));
      expect(response['message'], equals('Success'));
      expect(response['timestamp'], CustomMatchers.isValidDateString());
    });

    testWidgets('wrapWithMaterialApp should wrap widget correctly', (tester) async {
      // Arrange
      const testWidget = Text('Test Widget');

      // Act
      await tester.pumpWidget(TestHelper.wrapWithMaterialApp(testWidget));

      // Assert
      expect(find.text('Test Widget'), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('FixtureReader', () {
    test('readJson should read user fixture correctly', () {
      // Act
      final userData = FixtureReader.readJson(FixtureFiles.user);

      // Assert
      expect(userData, isA<Map<String, dynamic>>());
      expect(userData['id'], equals('test-user-123'));
      expect(userData['name'], equals('Test User'));
      expect(userData['email'], equals('test@example.com'));
      expect(userData['age'], equals(30));
      expect(userData['weight'], equals(70.5));
      expect(userData['height'], equals(175.0));
    });

    test('readJson should read activity fixture correctly', () {
      // Act
      final activityData = FixtureReader.readJson(FixtureFiles.activity);

      // Assert
      expect(activityData, isA<Map<String, dynamic>>());
      expect(activityData['id'], equals('activity-123'));
      expect(activityData['userId'], equals('test-user-123'));
      expect(activityData['type'], equals('running'));
      expect(activityData['duration'], equals(1800));
      expect(activityData['calories'], equals(350));
      expect(activityData['averageHeartRate'], equals(145));
    });

    test('exists should return true for existing fixtures', () {
      // Act & Assert
      expect(FixtureReader.exists(FixtureFiles.user), isTrue);
      expect(FixtureReader.exists(FixtureFiles.activity), isTrue);
      expect(FixtureReader.exists('non_existent_file.json'), isFalse);
    });
  });

  group('CustomMatchers', () {
        test('isValidDateString should validate date strings correctly', () {
      // Valid date strings
      expect('2024-01-15T12:30:00.000Z', CustomMatchers.isValidDateString());
      expect('2024-12-31T23:59:59.999Z', CustomMatchers.isValidDateString());

      // Invalid date strings should not match
      expect('invalid-date', isNot(CustomMatchers.isValidDateString()));
      expect('not-a-date', isNot(CustomMatchers.isValidDateString()));
    });

        test('isValidUuid should validate UUIDs correctly', () {
      // Valid UUIDs
      expect('123e4567-e89b-12d3-a456-426614174000', CustomMatchers.isValidUuid());
      expect('550e8400-e29b-41d4-a716-446655440000', CustomMatchers.isValidUuid());

      // Invalid UUIDs should not match
      expect('invalid-uuid', isNot(CustomMatchers.isValidUuid()));
      expect('123-456-789', isNot(CustomMatchers.isValidUuid()));
    });

        test('isPositiveNumber should validate positive numbers correctly', () {
      // Positive numbers
      expect(1, CustomMatchers.isPositiveNumber());
      expect(1.5, CustomMatchers.isPositiveNumber());
      expect(100, CustomMatchers.isPositiveNumber());

      // Non-positive numbers should not match
      expect(0, isNot(CustomMatchers.isPositiveNumber()));
      expect(-1, isNot(CustomMatchers.isPositiveNumber()));
    });
  });
}