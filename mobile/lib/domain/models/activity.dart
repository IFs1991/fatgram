/// アクティビティモデル
class Activity {
  final String activityId;
  final String activityType;
  final DateTime startTime;
  final DateTime endTime;
  final double caloriesBurned;
  final double fatBurnedGrams;
  final double? heartRateAvg;
  final double? heartRateMax;
  final int? steps;
  final double? distance;
  final List<HeartRateData>? heartRateData;

  Activity({
    required this.activityId,
    required this.activityType,
    required this.startTime,
    required this.endTime,
    required this.caloriesBurned,
    required this.fatBurnedGrams,
    this.heartRateAvg,
    this.heartRateMax,
    this.steps,
    this.distance,
    this.heartRateData,
  });

  /// JSONからActivityを作成
  factory Activity.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? heartRateDataJson = json['heart_rate_data'] as List<dynamic>?;

    return Activity(
      activityId: json['activity_id'] as String,
      activityType: json['activity_type'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      caloriesBurned: json['calories_burned'] as double,
      fatBurnedGrams: json['fat_burned_grams'] as double,
      heartRateAvg: json['heart_rate_avg'] as double?,
      heartRateMax: json['heart_rate_max'] as double?,
      steps: json['steps'] as int?,
      distance: json['distance'] as double?,
      heartRateData: heartRateDataJson?.map((e) => HeartRateData.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// ActivityをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'activity_id': activityId,
      'activity_type': activityType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'calories_burned': caloriesBurned,
      'fat_burned_grams': fatBurnedGrams,
      'heart_rate_avg': heartRateAvg,
      'heart_rate_max': heartRateMax,
      'steps': steps,
      'distance': distance,
      'heart_rate_data': heartRateData?.map((e) => e.toJson()).toList(),
    };
  }
}

/// 心拍数データモデル
class HeartRateData {
  final DateTime timestamp;
  final int value;

  HeartRateData({
    required this.timestamp,
    required this.value,
  });

  /// JSONからHeartRateDataを作成
  factory HeartRateData.fromJson(Map<String, dynamic> json) {
    return HeartRateData(
      timestamp: DateTime.parse(json['timestamp'] as String),
      value: json['value'] as int,
    );
  }

  /// HeartRateDataをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
    };
  }
}