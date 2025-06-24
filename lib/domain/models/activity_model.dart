import 'package:uuid/uuid.dart';
import '../entities/activity.dart' as entities;

enum ActivityType {
  // 基本的な有酸素運動
  walking,
  running,
  cycling,
  swimming,
  
  // フィットネス・トレーニング
  workout,
  weightTraining,
  yoga,
  
  // スポーツ
  tennis,
  basketball,
  soccer,
  volleyball,
  golf,
  
  // アウトドア
  hiking,
  climbing,
  skiing,
  rowing,
  
  // その他
  dancing,
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
    final activityName = (data['activityName'] as String? ?? '').toLowerCase();

    switch (activityName) {
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
      case 'weighttraining':
      case 'strength_training':
      case 'weight_lifting':
        activityType = ActivityType.weightTraining;
        break;
      case 'yoga':
        activityType = ActivityType.yoga;
        break;
      case 'tennis':
        activityType = ActivityType.tennis;
        break;
      case 'basketball':
        activityType = ActivityType.basketball;
        break;
      case 'soccer':
      case 'football':
        activityType = ActivityType.soccer;
        break;
      case 'volleyball':
        activityType = ActivityType.volleyball;
        break;
      case 'golf':
        activityType = ActivityType.golf;
        break;
      case 'hiking':
        activityType = ActivityType.hiking;
        break;
      case 'climbing':
      case 'rock_climbing':
        activityType = ActivityType.climbing;
        break;
      case 'skiing':
        activityType = ActivityType.skiing;
        break;
      case 'rowing':
        activityType = ActivityType.rowing;
        break;
      case 'dancing':
        activityType = ActivityType.dancing;
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

  // Create from JSON (for Firebase/API data)
  factory Activity.fromJson(Map<String, dynamic> json) {
    // ActivityType enumの文字列からの復元（拡張対応）
    ActivityType activityType;
    final typeString = json['type'] as String? ?? 'other';
    
    switch (typeString.toLowerCase()) {
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
      case 'weighttraining':
        activityType = ActivityType.weightTraining;
        break;
      case 'yoga':
        activityType = ActivityType.yoga;
        break;
      case 'tennis':
        activityType = ActivityType.tennis;
        break;
      case 'basketball':
        activityType = ActivityType.basketball;
        break;
      case 'soccer':
        activityType = ActivityType.soccer;
        break;
      case 'volleyball':
        activityType = ActivityType.volleyball;
        break;
      case 'golf':
        activityType = ActivityType.golf;
        break;
      case 'hiking':
        activityType = ActivityType.hiking;
        break;
      case 'climbing':
        activityType = ActivityType.climbing;
        break;
      case 'skiing':
        activityType = ActivityType.skiing;
        break;
      case 'rowing':
        activityType = ActivityType.rowing;
        break;
      case 'dancing':
        activityType = ActivityType.dancing;
        break;
      default:
        activityType = ActivityType.other;
    }

    // タイムスタンプの適切な処理（timestamp/dateの両方をサポート）
    DateTime parsedTimestamp;
    if (json['timestamp'] is String) {
      parsedTimestamp = DateTime.parse(json['timestamp'] as String);
    } else if (json['date'] is String) {
      // Firestoreからのレガシーフィールド対応
      parsedTimestamp = DateTime.parse(json['date'] as String);
    } else if (json['timestamp'] is int) {
      // ミリ秒での格納の場合
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int);
    } else {
      // デフォルトは現在時刻
      parsedTimestamp = DateTime.now();
    }

    final caloriesBurned = (json['caloriesBurned'] as num?)?.toDouble() ?? 0.0;
    final fatGramsBurned = (json['fatGramsBurned'] as num?)?.toDouble() ?? 
                           (caloriesBurned / FAT_CALORIES_RATIO);

    return Activity(
      id: json['id'] as String? ?? const Uuid().v4(),
      timestamp: parsedTimestamp,
      type: activityType,
      durationInSeconds: (json['durationInSeconds'] as num?)?.toInt() ?? 0,
      caloriesBurned: caloriesBurned,
      distanceInMeters: (json['distanceInMeters'] as num?)?.toDouble(),
      fatGramsBurned: fatGramsBurned,
      userId: json['userId'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }


  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'date': timestamp.toIso8601String(), // Firestoreクエリ用の別名
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

  // NormalizedActivityに変換
  entities.NormalizedActivity toNormalizedActivity() {
    // ActivityTypeをNormalizedActivityのActivityTypeに変換
    entities.ActivityType normalizedType;
    switch (type) {
      case ActivityType.walking:
        normalizedType = entities.ActivityType.walking;
        break;
      case ActivityType.running:
        normalizedType = entities.ActivityType.running;
        break;
      case ActivityType.cycling:
        normalizedType = entities.ActivityType.cycling;
        break;
      case ActivityType.swimming:
        normalizedType = entities.ActivityType.swimming;
        break;
      case ActivityType.weightTraining:
        normalizedType = entities.ActivityType.weightTraining;
        break;
      case ActivityType.yoga:
        normalizedType = entities.ActivityType.yoga;
        break;
      case ActivityType.tennis:
        normalizedType = entities.ActivityType.tennis;
        break;
      case ActivityType.basketball:
        normalizedType = entities.ActivityType.basketball;
        break;
      case ActivityType.soccer:
        normalizedType = entities.ActivityType.soccer;
        break;
      case ActivityType.volleyball:
        normalizedType = entities.ActivityType.volleyball;
        break;
      case ActivityType.golf:
        normalizedType = entities.ActivityType.golf;
        break;
      case ActivityType.hiking:
        normalizedType = entities.ActivityType.hiking;
        break;
      case ActivityType.climbing:
        normalizedType = entities.ActivityType.climbing;
        break;
      case ActivityType.skiing:
        normalizedType = entities.ActivityType.skiing;
        break;
      case ActivityType.rowing:
        normalizedType = entities.ActivityType.rowing;
        break;
      case ActivityType.dancing:
        normalizedType = entities.ActivityType.dancing;
        break;
      case ActivityType.workout:
      case ActivityType.other:
      default:
        normalizedType = entities.ActivityType.unknown;
    }

    return entities.NormalizedActivity(
      id: id,
      type: normalizedType,
      startTime: timestamp,
      endTime: timestamp.add(Duration(seconds: durationInSeconds)),
      source: entities.HealthDataSource.manual, // デフォルトはmanual
      calories: caloriesBurned,
      distance: distanceInMeters,
      metadata: metadata,
    );
  }

  // NormalizedActivityから変換
  factory Activity.fromNormalizedActivity(entities.NormalizedActivity normalizedActivity, String userId) {
    // NormalizedActivityのActivityTypeをActivityTypeに変換
    ActivityType activityType;
    switch (normalizedActivity.type) {
      case entities.ActivityType.walking:
        activityType = ActivityType.walking;
        break;
      case entities.ActivityType.running:
        activityType = ActivityType.running;
        break;
      case entities.ActivityType.cycling:
        activityType = ActivityType.cycling;
        break;
      case entities.ActivityType.swimming:
        activityType = ActivityType.swimming;
        break;
      case entities.ActivityType.weightTraining:
        activityType = ActivityType.weightTraining;
        break;
      case entities.ActivityType.yoga:
        activityType = ActivityType.yoga;
        break;
      case entities.ActivityType.tennis:
        activityType = ActivityType.tennis;
        break;
      case entities.ActivityType.basketball:
        activityType = ActivityType.basketball;
        break;
      case entities.ActivityType.soccer:
        activityType = ActivityType.soccer;
        break;
      case entities.ActivityType.volleyball:
        activityType = ActivityType.volleyball;
        break;
      case entities.ActivityType.golf:
        activityType = ActivityType.golf;
        break;
      case entities.ActivityType.hiking:
        activityType = ActivityType.hiking;
        break;
      case entities.ActivityType.climbing:
        activityType = ActivityType.climbing;
        break;
      case entities.ActivityType.skiing:
        activityType = ActivityType.skiing;
        break;
      case entities.ActivityType.rowing:
        activityType = ActivityType.rowing;
        break;
      case entities.ActivityType.dancing:
        activityType = ActivityType.dancing;
        break;
      case entities.ActivityType.unknown:
      default:
        activityType = ActivityType.other;
    }

    return Activity(
      id: normalizedActivity.id,
      timestamp: normalizedActivity.startTime,
      type: activityType,
      durationInSeconds: normalizedActivity.duration.inSeconds,
      caloriesBurned: normalizedActivity.calories ?? 0.0,
      distanceInMeters: normalizedActivity.distance,
      userId: userId,
      metadata: normalizedActivity.metadata,
    );
  }
}