import 'package:flutter_test/flutter_test.dart';
import '../../../lib/domain/models/user_model.dart';

void main() {
  group('User Model JSON Serialization', () {
    late User testUser;

    setUp(() {
      testUser = User(
        id: 'user-123',
        email: 'test@example.com',
        displayName: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        height: 175,
        weight: 70,
        age: 30,
        isPremium: true,
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        lastLoginAt: DateTime.parse('2024-01-08T10:00:00Z'),
      );
    });

    test('should serialize User to JSON correctly', () {
      final json = testUser.toJson();

      expect(json['id'], equals('user-123'));
      expect(json['email'], equals('test@example.com'));
      expect(json['displayName'], equals('Test User'));
      expect(json['photoUrl'], equals('https://example.com/photo.jpg'));
      expect(json['height'], equals(175));
      expect(json['weight'], equals(70));
      expect(json['age'], equals(30));
      expect(json['isPremium'], equals(true));
      expect(json['createdAt'], equals('2024-01-01T00:00:00.000Z'));
      expect(json['lastLoginAt'], equals('2024-01-08T10:00:00.000Z'));
    });

    test('should deserialize User from JSON correctly', () {
      final json = {
        'id': 'user-456',
        'email': 'test2@example.com',
        'displayName': 'Test User 2',
        'photoUrl': 'https://example.com/photo2.jpg',
        'height': 180,
        'weight': 75,
        'age': 25,
        'isPremium': false,
        'createdAt': '2024-01-02T00:00:00.000Z',
        'lastLoginAt': '2024-01-08T12:00:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.id, equals('user-456'));
      expect(user.email, equals('test2@example.com'));
      expect(user.displayName, equals('Test User 2'));
      expect(user.photoUrl, equals('https://example.com/photo2.jpg'));
      expect(user.height, equals(180));
      expect(user.weight, equals(75));
      expect(user.age, equals(25));
      expect(user.isPremium, equals(false));
      expect(user.createdAt, equals(DateTime.parse('2024-01-02T00:00:00.000Z')));
      expect(user.lastLoginAt, equals(DateTime.parse('2024-01-08T12:00:00.000Z')));
    });

    test('should handle nullable fields correctly', () {
      final json = {
        'id': 'user-minimal',
        'isPremium': false,
        'createdAt': '2024-01-08T00:00:00.000Z',
        // email, displayName, photoUrl, height, weight, age, lastLoginAt are missing
      };

      final user = User.fromJson(json);

      expect(user.id, equals('user-minimal'));
      expect(user.email, isNull);
      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
      expect(user.height, isNull);
      expect(user.weight, isNull);
      expect(user.age, isNull);
      expect(user.isPremium, equals(false));
      expect(user.createdAt, equals(DateTime.parse('2024-01-08T00:00:00.000Z')));
      expect(user.lastLoginAt, isNull);
    });

    test('should handle integer timestamp', () {
      final createdTimestamp = DateTime.parse('2024-01-08T00:00:00.000Z').millisecondsSinceEpoch;
      final lastLoginTimestamp = DateTime.parse('2024-01-08T12:00:00.000Z').millisecondsSinceEpoch;
      
      final json = {
        'id': 'user-int-timestamp',
        'email': 'test@example.com',
        'isPremium': false,
        'createdAt': createdTimestamp,
        'lastLoginAt': lastLoginTimestamp,
      };

      final user = User.fromJson(json);

      expect(user.createdAt, equals(DateTime.fromMillisecondsSinceEpoch(createdTimestamp)));
      expect(user.lastLoginAt, equals(DateTime.fromMillisecondsSinceEpoch(lastLoginTimestamp)));
    });

    test('should default isPremium to false when missing', () {
      final json = {
        'id': 'user-default-premium',
        'email': 'test@example.com',
        'createdAt': '2024-01-08T00:00:00.000Z',
        // isPremium is missing
      };

      final user = User.fromJson(json);

      expect(user.isPremium, equals(false));
    });

    test('should round-trip serialize and deserialize correctly', () {
      final originalJson = testUser.toJson();
      final deserializedUser = User.fromJson(originalJson);
      final reserializedJson = deserializedUser.toJson();

      expect(reserializedJson['id'], equals(originalJson['id']));
      expect(reserializedJson['email'], equals(originalJson['email']));
      expect(reserializedJson['displayName'], equals(originalJson['displayName']));
      expect(reserializedJson['photoUrl'], equals(originalJson['photoUrl']));
      expect(reserializedJson['height'], equals(originalJson['height']));
      expect(reserializedJson['weight'], equals(originalJson['weight']));
      expect(reserializedJson['age'], equals(originalJson['age']));
      expect(reserializedJson['isPremium'], equals(originalJson['isPremium']));
      expect(reserializedJson['createdAt'], equals(originalJson['createdAt']));
      expect(reserializedJson['lastLoginAt'], equals(originalJson['lastLoginAt']));
    });

    test('should work with Firebase fromFirebase factory', () {
      final firebaseData = {
        'uid': 'firebase-user-123',
        'email': 'firebase@example.com',
        'displayName': 'Firebase User',
        'photoURL': 'https://firebase.com/photo.jpg',
        'isPremium': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'lastLoginAt': '2024-01-08T10:00:00.000Z',
      };

      final user = User.fromFirebase(firebaseData);

      expect(user.id, equals('firebase-user-123'));
      expect(user.email, equals('firebase@example.com'));
      expect(user.displayName, equals('Firebase User'));
      expect(user.photoUrl, equals('https://firebase.com/photo.jpg'));
      expect(user.isPremium, equals(true));
      expect(user.createdAt, equals(DateTime.parse('2024-01-01T00:00:00.000Z')));
      expect(user.lastLoginAt, equals(DateTime.parse('2024-01-08T10:00:00.000Z')));

      // fromFirebaseで作成されたUserオブジェクトがtoJson/fromJsonでも正しく動作するかテスト
      final json = user.toJson();
      final userFromJson = User.fromJson(json);

      expect(userFromJson.id, equals(user.id));
      expect(userFromJson.email, equals(user.email));
      expect(userFromJson.displayName, equals(user.displayName));
      expect(userFromJson.photoUrl, equals(user.photoUrl));
      expect(userFromJson.isPremium, equals(user.isPremium));
    });
  });
}