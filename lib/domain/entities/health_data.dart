import 'package:equatable/equatable.dart';
import 'activity.dart';

/// ヘルスプラットフォームの種類
enum HealthPlatform {
  ios,
  android,
  web,
  unknown,
}

/// ヘルスデータタイプ
enum HealthDataType {
  activities,
  heartRate,
  steps,
  calories,
  distance,
  sleep,
  weight,
  bloodPressure,
  bloodGlucose,
}

/// 正規化された心拍数データ
class NormalizedHeartRateData extends Equatable {
  final List<HeartRateSample> samples;
  final double averageHeartRate;
  final double minHeartRate;
  final double maxHeartRate;
  final DateTime startTime;
  final DateTime endTime;
  final HealthDataSource source;

  const NormalizedHeartRateData({
    required this.samples,
    required this.averageHeartRate,
    required this.minHeartRate,
    required this.maxHeartRate,
    required this.startTime,
    required this.endTime,
    required this.source,
  });

  /// 心拍数ゾーンの分析を行う
  HeartRateZoneAnalysis get zoneAnalysis {
    final zoneDistribution = <HeartRateZone, Duration>{};

    for (final sample in samples) {
      final zone = sample.heartRateZone;
      final duration = const Duration(minutes: 1); // サンプル間隔を仮定
      zoneDistribution[zone] = (zoneDistribution[zone] ?? Duration.zero) + duration;
    }

    return HeartRateZoneAnalysis(
      zoneDistribution: zoneDistribution,
      totalDuration: endTime.difference(startTime),
    );
  }

  /// 心拍数の変動性を計算
  double get heartRateVariability {
    if (samples.length < 2) return 0.0;

    final intervals = <double>[];
    for (int i = 1; i < samples.length; i++) {
      final diff = (samples[i].value - samples[i-1].value).abs();
      intervals.add(diff);
    }

    final mean = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.map((x) => (x - mean) * (x - mean))
                              .reduce((a, b) => a + b) / intervals.length;

    return variance;
  }

  @override
  List<Object?> get props => [
    samples,
    averageHeartRate,
    minHeartRate,
    maxHeartRate,
    startTime,
    endTime,
    source,
  ];
}

/// 心拍数サンプル
class HeartRateSample extends Equatable {
  final double value;
  final DateTime timestamp;

  const HeartRateSample({
    required this.value,
    required this.timestamp,
  });

  /// 心拍数ゾーンを計算
  HeartRateZone get heartRateZone {
    // 一般的な年齢別最大心拍数の推定: 220 - 年齢
    // ここでは30歳を仮定: 220 - 30 = 190
    const maxHeartRate = 190.0;

    final percentage = value / maxHeartRate;

    if (percentage < 0.5) return HeartRateZone.recovery;
    if (percentage < 0.6) return HeartRateZone.base;
    if (percentage < 0.7) return HeartRateZone.aerobic;
    if (percentage < 0.8) return HeartRateZone.threshold;
    if (percentage < 0.9) return HeartRateZone.vo2Max;
    return HeartRateZone.maximal;
  }

  @override
  List<Object?> get props => [value, timestamp];
}

/// 心拍数ゾーン
enum HeartRateZone {
  recovery,    // 50-60%
  base,        // 60-70%
  aerobic,     // 70-80%
  threshold,   // 80-90%
  vo2Max,      // 90-95%
  maximal,     // 95%+
}

/// 心拍数ゾーン分析
class HeartRateZoneAnalysis extends Equatable {
  final Map<HeartRateZone, Duration> zoneDistribution;
  final Duration totalDuration;

  const HeartRateZoneAnalysis({
    required this.zoneDistribution,
    required this.totalDuration,
  });

  /// 特定ゾーンの滞在時間の割合を取得
  double getZonePercentage(HeartRateZone zone) {
    final zoneDuration = zoneDistribution[zone] ?? Duration.zero;
    return totalDuration.inMilliseconds > 0
        ? zoneDuration.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;
  }

  @override
  List<Object?> get props => [zoneDistribution, totalDuration];
}

/// プラットフォーム機能情報
class HealthPlatformCapabilities extends Equatable {
  final List<HealthDataType> supportedDataTypes;
  final bool hasBackgroundSync;
  final bool hasRealtimeData;
  final bool hasWriteCapability;
  final List<String> requiredPermissions;
  final String? minimumOSVersion;

  const HealthPlatformCapabilities({
    required this.supportedDataTypes,
    required this.hasBackgroundSync,
    required this.hasRealtimeData,
    required this.hasWriteCapability,
    required this.requiredPermissions,
    this.minimumOSVersion,
  });

  @override
  List<Object?> get props => [
    supportedDataTypes,
    hasBackgroundSync,
    hasRealtimeData,
    hasWriteCapability,
    requiredPermissions,
    minimumOSVersion,
  ];
}

/// プラットフォーム利用可能性情報
class PlatformAvailability extends Equatable {
  final bool isHealthKitAvailable;
  final bool isHealthConnectAvailable;
  final HealthPlatform recommendedPlatform;
  final String? errorMessage;

  const PlatformAvailability({
    required this.isHealthKitAvailable,
    required this.isHealthConnectAvailable,
    required this.recommendedPlatform,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    isHealthKitAvailable,
    isHealthConnectAvailable,
    recommendedPlatform,
    errorMessage,
  ];
}

/// 権限リクエスト結果
class PermissionRequestResult extends Equatable {
  final bool isSuccess;
  final List<String> grantedPermissions;
  final List<String> deniedPermissions;
  final String? errorMessage;

  const PermissionRequestResult({
    required this.isSuccess,
    required this.grantedPermissions,
    required this.deniedPermissions,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    isSuccess,
    grantedPermissions,
    deniedPermissions,
    errorMessage,
  ];
}

/// 権限状態
class PermissionStatus extends Equatable {
  final bool workouts;
  final bool heartRate;
  final bool steps;
  final bool calories;
  final bool distance;
  final bool sleep;

  const PermissionStatus({
    required this.workouts,
    required this.heartRate,
    required this.steps,
    required this.calories,
    required this.distance,
    required this.sleep,
  });

  /// すべての必須権限が許可されているかチェック
  bool get hasAllRequiredPermissions {
    return workouts && heartRate && steps && calories;
  }

  /// 許可されている権限のリストを取得
  List<String> get grantedPermissions {
    final permissions = <String>[];
    if (workouts) permissions.add('workouts');
    if (heartRate) permissions.add('heartRate');
    if (steps) permissions.add('steps');
    if (calories) permissions.add('calories');
    if (distance) permissions.add('distance');
    if (sleep) permissions.add('sleep');
    return permissions;
  }

  @override
  List<Object?> get props => [
    workouts,
    heartRate,
    steps,
    calories,
    distance,
    sleep,
  ];
}

/// 正規化された距離データ
class NormalizedDistance extends Equatable {
  final double meters;

  const NormalizedDistance({required this.meters});

  /// キロメートル単位で取得
  double get kilometers => meters / 1000.0;

  /// マイル単位で取得
  double get miles => meters / 1609.344;

  /// フィート単位で取得
  double get feet => meters * 3.28084;

  @override
  List<Object?> get props => [meters];
}

/// データリクエスト
class DataRequest extends Equatable {
  final HealthDataType type;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, dynamic>? parameters;

  const DataRequest({
    required this.type,
    required this.startTime,
    required this.endTime,
    this.parameters,
  });

  @override
  List<Object?> get props => [type, startTime, endTime, parameters];
}

/// データレスポンス
class DataResponse extends Equatable {
  final HealthDataType type;
  final bool isSuccess;
  final dynamic data;
  final String? errorMessage;
  final DateTime responseTime;

  const DataResponse({
    required this.type,
    required this.isSuccess,
    required this.data,
    this.errorMessage,
    required this.responseTime,
  });

  @override
  List<Object?> get props => [type, isSuccess, data, errorMessage, responseTime];
}

/// リアルタイム監視フィルター条件
class RealtimeFilterCriteria extends Equatable {
  final Duration? minDuration;
  final List<ActivityType>? activityTypes;
  final double? minCalories;
  final double? minDistance;
  final double? minAverageHeartRate;

  const RealtimeFilterCriteria({
    this.minDuration,
    this.activityTypes,
    this.minCalories,
    this.minDistance,
    this.minAverageHeartRate,
  });

  /// アクティビティがフィルター条件を満たすかチェック
  bool matches(NormalizedActivity activity) {
    if (minDuration != null && activity.duration < minDuration!) {
      return false;
    }
    if (activityTypes != null && !activityTypes!.contains(activity.type)) {
      return false;
    }
    if (minCalories != null && (activity.calories ?? 0) < minCalories!) {
      return false;
    }
    if (minDistance != null && (activity.distance ?? 0) < minDistance!) {
      return false;
    }
    if (minAverageHeartRate != null &&
        (activity.averageHeartRate ?? 0) < minAverageHeartRate!) {
      return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [
    minDuration,
    activityTypes,
    minCalories,
    minDistance,
    minAverageHeartRate,
  ];
}

/// 同期結果
class SyncResult extends Equatable {
  final bool isSuccess;
  final int syncedActivities;
  final int syncedHeartRateRecords;
  final int syncedStepsRecords;
  final List<DataConflict> conflicts;
  final DateTime syncTime;
  final String? errorMessage;

  const SyncResult({
    required this.isSuccess,
    required this.syncedActivities,
    required this.syncedHeartRateRecords,
    required this.syncedStepsRecords,
    required this.conflicts,
    required this.syncTime,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    isSuccess,
    syncedActivities,
    syncedHeartRateRecords,
    syncedStepsRecords,
    conflicts,
    syncTime,
    errorMessage,
  ];
}

/// データ競合
class DataConflict extends Equatable {
  final String id;
  final Map<String, dynamic> sourceData;
  final Map<String, dynamic> targetData;
  final HealthDataSource sourceType;
  final HealthDataSource targetType;
  final DateTime conflictTime;

  const DataConflict({
    required this.id,
    required this.sourceData,
    required this.targetData,
    required this.sourceType,
    required this.targetType,
    required this.conflictTime,
  });

  @override
  List<Object?> get props => [
    id,
    sourceData,
    targetData,
    sourceType,
    targetType,
    conflictTime,
  ];
}

/// 競合解決戦略
enum ConflictResolutionStrategy {
  mostRecent,
  sourcePreference,
  userChoice,
  merge,
  skip,
}

/// ヘルスインサイトの時間範囲
enum HealthInsightTimeRange {
  lastWeek,
  lastMonth,
  lastThreeMonths,
  lastSixMonths,
  lastYear,
}

/// ヘルスインサイト
class HealthInsights extends Equatable {
  final List<HealthTrend> trends;
  final List<HealthRecommendation> recommendations;
  final List<HealthAchievement> achievements;
  final List<HealthRiskFactor> riskFactors;
  final DateTime generatedAt;

  const HealthInsights({
    required this.trends,
    required this.recommendations,
    required this.achievements,
    required this.riskFactors,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [
    trends,
    recommendations,
    achievements,
    riskFactors,
    generatedAt,
  ];
}

/// ヘルストレンド
class HealthTrend extends Equatable {
  final String title;
  final String description;
  final TrendDirection direction;
  final double changePercentage;
  final HealthDataType dataType;

  const HealthTrend({
    required this.title,
    required this.description,
    required this.direction,
    required this.changePercentage,
    required this.dataType,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    direction,
    changePercentage,
    dataType,
  ];
}

/// トレンドの方向
enum TrendDirection {
  improving,
  declining,
  stable,
}

/// ヘルス推奨事項
class HealthRecommendation extends Equatable {
  final String title;
  final String description;
  final RecommendationType type;
  final int priority; // 1-10, 10が最高優先度

  const HealthRecommendation({
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
  });

  @override
  List<Object?> get props => [title, description, type, priority];
}

/// 推奨事項のタイプ
enum RecommendationType {
  exercise,
  nutrition,
  sleep,
  recovery,
  medical,
}

/// ヘルス達成項目
class HealthAchievement extends Equatable {
  final String title;
  final String description;
  final DateTime achievedDate;
  final AchievementType type;

  const HealthAchievement({
    required this.title,
    required this.description,
    required this.achievedDate,
    required this.type,
  });

  @override
  List<Object?> get props => [title, description, achievedDate, type];
}

/// 達成項目のタイプ
enum AchievementType {
  weeklyGoal,
  monthlyGoal,
  personalRecord,
  consistency,
  milestone,
}

/// ヘルスリスク要因
class HealthRiskFactor extends Equatable {
  final String title;
  final String description;
  final RiskLevel level;
  final List<String> mitigation;

  const HealthRiskFactor({
    required this.title,
    required this.description,
    required this.level,
    required this.mitigation,
  });

  @override
  List<Object?> get props => [title, description, level, mitigation];
}

/// リスクレベル
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

/// アクティビティ予測
class ActivityPrediction extends Equatable {
  final List<NormalizedActivity> predictedActivities;
  final double confidence; // 0.0-1.0
  final DateTime predictionDate;
  final Duration predictionWindow;

  const ActivityPrediction({
    required this.predictedActivities,
    required this.confidence,
    required this.predictionDate,
    required this.predictionWindow,
  });

  @override
  List<Object?> get props => [
    predictedActivities,
    confidence,
    predictionDate,
    predictionWindow,
  ];
}

/// 大量データ処理結果
class LargeDatasetProcessingResult extends Equatable {
  final int totalProcessed;
  final int successful;
  final int failed;
  final Duration processingTime;
  final List<String> errors;

  const LargeDatasetProcessingResult({
    required this.totalProcessed,
    required this.successful,
    required this.failed,
    required this.processingTime,
    required this.errors,
  });

  @override
  List<Object?> get props => [
    totalProcessed,
    successful,
    failed,
    processingTime,
    errors,
  ];
}

/// カスタム例外クラス
class DataNormalizationException implements Exception {
  final String message;
  const DataNormalizationException(this.message);

  @override
  String toString() => 'DataNormalizationException: $message';
}

class RealtimeMonitoringException implements Exception {
  final String message;
  const RealtimeMonitoringException(this.message);

  @override
  String toString() => 'RealtimeMonitoringException: $message';
}