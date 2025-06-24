import 'package:equatable/equatable.dart';

/// アクティビティタイプの定義
enum ActivityType {
  running,
  walking,
  cycling,
  swimming,
  weightTraining,
  yoga,
  tennis,
  basketball,
  hiking,
  dancing,
  rowing,
  climbing,
  skiing,
  golf,
  soccer,
  volleyball,
  unknown,
}

/// ヘルスデータのソース
enum HealthDataSource {
  healthKit,
  healthConnect,
  manual,
  thirdParty,
  unknown,
}

/// アクティビティの集計期間
enum AggregationPeriod {
  daily,
  weekly,
  monthly,
  yearly,
}

/// 正規化されたアクティビティデータ
class NormalizedActivity extends Equatable {
  final String id;
  final ActivityType type;
  final DateTime startTime;
  final DateTime endTime;
  final HealthDataSource source;
  final double? calories;
  final double? distance; // meters
  final double? averageHeartRate;
  final double? maxHeartRate;
  final int? steps;
  final String? name;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const NormalizedActivity({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.source,
    this.calories,
    this.distance,
    this.averageHeartRate,
    this.maxHeartRate,
    this.steps,
    this.name,
    this.notes,
    this.metadata,
  });

  /// アクティビティの継続時間を取得
  Duration get duration => endTime.difference(startTime);

  /// 1分あたりのカロリー消費量を計算
  double? get caloriesPerMinute {
    if (calories == null) return null;
    final minutes = duration.inMinutes;
    return minutes > 0 ? calories! / minutes : 0.0;
  }

  /// 1時間あたりの平均速度を計算（km/h）
  double? get averageSpeedKmh {
    if (distance == null) return null;
    final hours = duration.inMilliseconds / (1000 * 60 * 60);
    return hours > 0 ? (distance! / 1000) / hours : 0.0;
  }

  /// アクティビティの強度レベルを判定
  ActivityIntensity get intensity {
    if (averageHeartRate == null) return ActivityIntensity.unknown;

    if (averageHeartRate! < 100) return ActivityIntensity.light;
    if (averageHeartRate! < 140) return ActivityIntensity.moderate;
    if (averageHeartRate! < 170) return ActivityIntensity.vigorous;
    return ActivityIntensity.maximal;
  }

  /// アクティビティが有効かチェック
  bool get isValid {
    return startTime.isBefore(endTime) &&
           duration.inMinutes >= 1 &&
           (calories == null || calories! >= 0) &&
           (distance == null || distance! >= 0) &&
           (steps == null || steps! >= 0);
  }

  /// JSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'source': source.name,
      'calories': calories,
      'distance': distance,
      'averageHeartRate': averageHeartRate,
      'maxHeartRate': maxHeartRate,
      'steps': steps,
      'name': name,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// JSONから作成
  factory NormalizedActivity.fromJson(Map<String, dynamic> json) {
    return NormalizedActivity(
      id: json['id'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActivityType.unknown,
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      source: HealthDataSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => HealthDataSource.unknown,
      ),
      calories: json['calories']?.toDouble(),
      distance: json['distance']?.toDouble(),
      averageHeartRate: json['averageHeartRate']?.toDouble(),
      maxHeartRate: json['maxHeartRate']?.toDouble(),
      steps: json['steps']?.toInt(),
      name: json['name'] as String?,
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// コピーを作成
  NormalizedActivity copyWith({
    String? id,
    ActivityType? type,
    DateTime? startTime,
    DateTime? endTime,
    HealthDataSource? source,
    double? calories,
    double? distance,
    double? averageHeartRate,
    double? maxHeartRate,
    int? steps,
    String? name,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return NormalizedActivity(
      id: id ?? this.id,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      source: source ?? this.source,
      calories: calories ?? this.calories,
      distance: distance ?? this.distance,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      steps: steps ?? this.steps,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        startTime,
        endTime,
        source,
        calories,
        distance,
        averageHeartRate,
        maxHeartRate,
        steps,
        name,
        notes,
        metadata,
      ];

  @override
  String toString() {
    return 'NormalizedActivity{id: $id, type: $type, duration: ${duration.inMinutes}min, '
           'calories: $calories, distance: ${distance != null ? '${(distance! / 1000).toStringAsFixed(1)}km' : 'null'}}';
  }
}

/// アクティビティの強度レベル
enum ActivityIntensity {
  light,
  moderate,
  vigorous,
  maximal,
  unknown,
}

/// アクティビティ統計情報
class ActivityStatistics extends Equatable {
  final int totalActivities;
  final double totalCalories;
  final double totalDistance; // meters
  final Duration totalDuration;
  final double averageCaloriesPerWorkout;
  final double averageDistancePerWorkout;
  final Duration averageDurationPerWorkout;
  final ActivityType? mostCommonActivityType;
  final Map<ActivityType, int> activityTypeCount;
  final Map<ActivityIntensity, int> intensityDistribution;

  const ActivityStatistics({
    required this.totalActivities,
    required this.totalCalories,
    required this.totalDistance,
    required this.totalDuration,
    required this.averageCaloriesPerWorkout,
    required this.averageDistancePerWorkout,
    required this.averageDurationPerWorkout,
    this.mostCommonActivityType,
    required this.activityTypeCount,
    required this.intensityDistribution,
  });

  /// 1日あたりの平均ワークアウト数
  double get averageWorkoutsPerDay {
    // これは実際の計算期間に基づいて調整する必要がある
    return totalActivities / 30.0; // 30日間の仮定
  }

  /// 週あたりの平均ワークアウト数
  double get averageWorkoutsPerWeek => averageWorkoutsPerDay * 7;

  @override
  List<Object?> get props => [
        totalActivities,
        totalCalories,
        totalDistance,
        totalDuration,
        averageCaloriesPerWorkout,
        averageDistancePerWorkout,
        averageDurationPerWorkout,
        mostCommonActivityType,
        activityTypeCount,
        intensityDistribution,
      ];
}

/// アクティビティサマリー
class ActivitySummary extends Equatable {
  final int totalWorkouts;
  final double totalCalories;
  final double totalDistance;
  final Duration totalDuration;
  final double averageWorkoutsPerWeek;
  final Map<String, int> weeklyBreakdown; // week -> workout count
  final Map<ActivityType, ActivityStatistics> typeBreakdown;

  const ActivitySummary({
    required this.totalWorkouts,
    required this.totalCalories,
    required this.totalDistance,
    required this.totalDuration,
    required this.averageWorkoutsPerWeek,
    required this.weeklyBreakdown,
    required this.typeBreakdown,
  });

  @override
  List<Object?> get props => [
        totalWorkouts,
        totalCalories,
        totalDistance,
        totalDuration,
        averageWorkoutsPerWeek,
        weeklyBreakdown,
        typeBreakdown,
      ];
}