import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:faker/faker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// テスト用のモッククラス
class MockSharedPreferences extends Mock implements SharedPreferences {}

/// テスト用のFakerインスタンス
final faker = Faker();

/// テストヘルパークラス
class TestHelper {
  /// SharedPreferencesのモックを設定
  static void setupSharedPreferencesMock() {
    SharedPreferences.setMockInitialValues({});
  }

  /// ウィジェットテスト用のMaterialAppラッパー
  static Widget wrapWithMaterialApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  /// テスト用のランダムなユーザーデータを生成
  static Map<String, dynamic> generateUserData() {
    return {
      'id': faker.guid.guid(),
      'name': faker.person.name(),
      'email': faker.internet.email(),
      'age': faker.randomGenerator.integer(100, min: 18),
      'weight': faker.randomGenerator.decimal(scale: 1, min: 40),
      'height': faker.randomGenerator.decimal(scale: 1, min: 140),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// テスト用のランダムなアクティビティデータを生成
  static Map<String, dynamic> generateActivityData() {
    final startTime = DateTime.now().subtract(Duration(hours: faker.randomGenerator.integer(24)));
    final duration = faker.randomGenerator.integer(7200, min: 300); // 5分〜2時間
    final endTime = startTime.add(Duration(seconds: duration));

    return {
      'id': faker.guid.guid(),
      'type': faker.randomGenerator.element(['running', 'walking', 'cycling', 'swimming']),
      'startDate': startTime,
      'endDate': endTime,
      'totalEnergyBurned': faker.randomGenerator.integer(1000, min: 50).toDouble(),
      'totalDistance': faker.randomGenerator.decimal(scale: 2, min: 0.5),
      'averageHeartRate': faker.randomGenerator.integer(200, min: 60).toDouble(),
      'maxHeartRate': faker.randomGenerator.integer(220, min: 100).toDouble(),
      'name': 'Test ${faker.randomGenerator.element(['Running', 'Walking', 'Cycling', 'Swimming'])}',
      'source': 'healthkit',
    };
  }

  /// テスト用のランダムなヘルスデータを生成
  static Map<String, dynamic> generateHealthData() {
    return {
      'id': faker.guid.guid(),
      'type': faker.randomGenerator.element(['steps', 'heartRate', 'weight', 'sleep']),
      'value': faker.randomGenerator.decimal(scale: 2, min: 1),
      'unit': faker.randomGenerator.element(['count', 'bpm', 'kg', 'hours']),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// テスト用のエラーレスポンスを生成
  static Map<String, dynamic> generateErrorResponse({
    int statusCode = 400,
    String? message,
  }) {
    return {
      'statusCode': statusCode,
      'message': message ?? faker.lorem.sentence(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 非同期テストの待機時間を短縮するためのヘルパー
  static Future<void> pumpAndSettle(WidgetTester tester, [Duration? duration]) async {
    await tester.pumpAndSettle(duration ?? const Duration(milliseconds: 100));
  }

  /// テスト用のモックレスポンスを作成
  static Map<String, dynamic> createMockResponse<T>({
    required T data,
    bool success = true,
    String? message,
  }) {
    return {
      'success': success,
      'data': data,
      'message': message ?? (success ? 'Success' : 'Error'),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// テスト用の定数
class TestConstants {
  static const String testUserId = 'test-user-id';
  static const String testUserEmail = 'test@example.com';
  static const String testUserName = 'Test User';
  static const String testApiKey = 'test-api-key';
  static const String testBaseUrl = 'https://api.test.com';

  // テスト用のファイルパス
  static const String testDatabasePath = 'test_database.db';
  static const String testFixturesPath = 'test/fixtures';
}

/// カスタムマッチャー
class CustomMatchers {
  /// 日付文字列が有効かチェック
  static Matcher isValidDateString() {
    return predicate<String>((value) {
      try {
        DateTime.parse(value);
        return true;
      } catch (e) {
        return false;
      }
    }, 'is a valid date string');
  }

  /// UUIDが有効かチェック
  static Matcher isValidUuid() {
    return predicate<String>((value) {
      final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
      );
      return uuidRegex.hasMatch(value);
    }, 'is a valid UUID');
  }

  /// 正の数値かチェック
  static Matcher isPositiveNumber() {
    return predicate<num>((value) => value > 0, 'is a positive number');
  }
}