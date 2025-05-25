import 'package:uuid/uuid.dart';

enum ActivityType {
  walking,
  running,
  cycling,
  swimming,
  workout,
  other,
}

class Activity {
  final String id;
  final DateTime timestamp;
  final ActivityType type;
  final int durationInSeconds;
  final double caloriesBurned;
  final double? distanceInMeters;
  final double fatGramsBurned;  // Calculated field
  final String userId;
  final Map<String, dynamic>? metadata;

  static const double FAT_CALORIES_RATIO = 7.2; // 7.2 kcal per gram of fat

  Activity({
    String? id,
    required this.timestamp,
    required this.type,
    required this.durationInSeconds,
    required this.caloriesBurned,
    this.distanceInMeters,
    double? fatGramsBurned,
    required this.userId,
    this.metadata,
  })  : id = id ?? const Uuid().v4(),
        fatGramsBurned = fatGramsBurned ?? (caloriesBurned / FAT_CALORIES_RATIO);

  // Create from HealthKit or Health Connect API data
  factory Activity.fromHealthData(Map<String, dynamic> data, String userId) {
    ActivityType activityType;

    switch (data['activityName']) {
      case 'walking':
        activityType = ActivityType.walking;
        break;
      case 'running':
        activityType = ActivityType.running;
        break;
      case 'cycling':
        activityType = ActivityType.cycling;
        break;
      case 'swimming':
        activityType = ActivityType.swimming;
        break;
      case 'workout':
        activityType = ActivityType.workout;
        break;
      default:
        activityType = ActivityType.other;
    }

    return Activity(
      id: data['id'],
      timestamp: DateTime.parse(data['startTime']),
      type: activityType,
      durationInSeconds: data['durationInSeconds'] ?? 0,
      caloriesBurned: data['calories'] != null ? double.parse(data['calories'].toString()) : 0.0,
      distanceInMeters: data['distance'] != null ? double.parse(data['distance'].toString()) : null,
      userId: userId,
      metadata: data['metadata'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'durationInSeconds': durationInSeconds,
      'caloriesBurned': caloriesBurned,
      'distanceInMeters': distanceInMeters,
      'fatGramsBurned': fatGramsBurned,
      'userId': userId,
      'metadata': metadata,
    };
  }

  // Copy with
  Activity copyWith({
    String? id,
    DateTime? timestamp,
    ActivityType? type,
    int? durationInSeconds,
    double? caloriesBurned,
    double? distanceInMeters,
    double? fatGramsBurned,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return Activity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      distanceInMeters: distanceInMeters ?? this.distanceInMeters,
      fatGramsBurned: fatGramsBurned ?? this.fatGramsBurned,
      userId: userId ?? this.userId,
      metadata: metadata ?? this.metadata,
    );
  }
}