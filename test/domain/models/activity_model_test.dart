import 'package:flutter_test/flutter_test.dart';
import '../../../lib/domain/models/activity_model.dart';

void main() {
  group('Activity Model JSON Serialization', () {
    late Activity testActivity;

    setUp(() {
      testActivity = Activity(
        id: 'test-activity-123',
        timestamp: DateTime.parse('2024-01-08T10:30:00Z'),
        type: ActivityType.running,
        durationInSeconds: 1800, // 30 minutes
        caloriesBurned: 250.0,
        distanceInMeters: 5000.0,
        userId: 'user-123',
        metadata: {'source': 'healthkit', 'confidence': 'high'},
      );
    });

    test('should serialize Activity to JSON correctly', () {
      final json = testActivity.toJson();

      expect(json['id'], equals('test-activity-123'));
      expect(json['timestamp'], equals('2024-01-08T10:30:00.000Z'));
      expect(json['type'], equals('running'));
      expect(json['durationInSeconds'], equals(1800));
      expect(json['caloriesBurned'], equals(250.0));
      expect(json['distanceInMeters'], equals(5000.0));
      expect(json['fatGramsBurned'], equals(250.0 / Activity.FAT_CALORIES_RATIO));
      expect(json['userId'], equals('user-123'));
      expect(json['metadata'], equals({'source': 'healthkit', 'confidence': 'high'}));
    });

    test('should deserialize Activity from JSON correctly', () {
      final json = {
        'id': 'test-activity-456',
        'timestamp': '2024-01-08T14:15:00.000Z',
        'type': 'cycling',
        'durationInSeconds': 2700,
        'caloriesBurned': 300.0,
        'distanceInMeters': 10000.0,
        'fatGramsBurned': 41.67, // 300.0 / 7.2
        'userId': 'user-456',
        'metadata': {'source': 'healthconnect', 'device': 'garmin'},
      };

      final activity = Activity.fromJson(json);

      expect(activity.id, equals('test-activity-456'));
      expect(activity.timestamp, equals(DateTime.parse('2024-01-08T14:15:00.000Z')));
      expect(activity.type, equals(ActivityType.cycling));
      expect(activity.durationInSeconds, equals(2700));
      expect(activity.caloriesBurned, equals(300.0));
      expect(activity.distanceInMeters, equals(10000.0));
      expect(activity.fatGramsBurned, equals(41.67));
      expect(activity.userId, equals('user-456'));
      expect(activity.metadata, equals({'source': 'healthconnect', 'device': 'garmin'}));
    });

    test('should handle missing fatGramsBurned and calculate from calories', () {
      final json = {
        'id': 'test-activity-789',
        'timestamp': '2024-01-08T16:00:00.000Z',
        'type': 'walking',
        'durationInSeconds': 1200,
        'caloriesBurned': 100.0,
        'userId': 'user-789',
        // fatGramsBurned is missing
      };

      final activity = Activity.fromJson(json);

      expect(activity.fatGramsBurned, equals(100.0 / Activity.FAT_CALORIES_RATIO));
    });

    test('should handle unknown activity type as other', () {
      final json = {
        'id': 'test-activity-unknown',
        'timestamp': '2024-01-08T18:00:00.000Z',
        'type': 'unknown_activity',
        'durationInSeconds': 600,
        'caloriesBurned': 50.0,
        'userId': 'user-unknown',
      };

      final activity = Activity.fromJson(json);

      expect(activity.type, equals(ActivityType.other));
    });

    test('should handle nullable fields correctly', () {
      final json = {
        'id': 'test-activity-minimal',
        'timestamp': '2024-01-08T20:00:00.000Z',
        'type': 'swimming',
        'durationInSeconds': 1800,
        'caloriesBurned': 200.0,
        'userId': 'user-minimal',
        // distanceInMeters and metadata are missing
      };

      final activity = Activity.fromJson(json);

      expect(activity.distanceInMeters, isNull);
      expect(activity.metadata, isNull);
    });

    test('should handle integer timestamp', () {
      final timestamp = DateTime.parse('2024-01-08T22:00:00.000Z').millisecondsSinceEpoch;
      final json = {
        'id': 'test-activity-int-timestamp',
        'timestamp': timestamp,
        'type': 'workout',
        'durationInSeconds': 3600,
        'caloriesBurned': 400.0,
        'userId': 'user-int-timestamp',
      };

      final activity = Activity.fromJson(json);

      expect(activity.timestamp, equals(DateTime.fromMillisecondsSinceEpoch(timestamp)));
    });

    test('should round-trip serialize and deserialize correctly', () {
      final originalJson = testActivity.toJson();
      final deserializedActivity = Activity.fromJson(originalJson);
      final reserializedJson = deserializedActivity.toJson();

      expect(reserializedJson['id'], equals(originalJson['id']));
      expect(reserializedJson['timestamp'], equals(originalJson['timestamp']));
      expect(reserializedJson['type'], equals(originalJson['type']));
      expect(reserializedJson['durationInSeconds'], equals(originalJson['durationInSeconds']));
      expect(reserializedJson['caloriesBurned'], equals(originalJson['caloriesBurned']));
      expect(reserializedJson['distanceInMeters'], equals(originalJson['distanceInMeters']));
      expect(reserializedJson['fatGramsBurned'], equals(originalJson['fatGramsBurned']));
      expect(reserializedJson['userId'], equals(originalJson['userId']));
      expect(reserializedJson['metadata'], equals(originalJson['metadata']));
    });
  });
}