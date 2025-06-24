import 'package:fatgram/domain/entities/activity.dart';
import 'package:fatgram/domain/entities/health_data.dart';

// ActivityをNormalizedActivityのエイリアスとして定義
typedef Activity = NormalizedActivity;

// ユーザーコンテキストの型定義
class UserContext {
  final String userId;
  final int? age;
  final Gender? gender;
  final FitnessLevel? fitnessLevel;
  final List<FitnessGoal>? goals;
  final UserPreferences? preferences;
  final Map<String, dynamic>? customAttributes;

  const UserContext({
    required this.userId,
    this.age,
    this.gender,
    this.fitnessLevel,
    this.goals,
    this.preferences,
    this.customAttributes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserContext &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          age == other.age &&
          gender == other.gender &&
          fitnessLevel == other.fitnessLevel;

  @override
  int get hashCode =>
      userId.hashCode ^
      age.hashCode ^
      gender.hashCode ^
      fitnessLevel.hashCode;
}

// ユーザー設定の型定義
class UserPreferences {
  final List<WorkoutType>? workoutTypes;
  final int? availableTime; // 分単位
  final List<Equipment>? equipment;
  final List<String>? dietaryRestrictions;
  final List<String>? mealPreferences;
  final Map<String, dynamic>? customPreferences;

  const UserPreferences({
    this.workoutTypes,
    this.availableTime,
    this.equipment,
    this.dietaryRestrictions,
    this.mealPreferences,
    this.customPreferences,
  });
}

// Enum定義
enum Gender { male, female, other }
enum FitnessLevel { beginner, intermediate, advanced }
enum FitnessGoal { fatLoss, muscleGain, strength, endurance, health, weightMaintenance }
enum WorkoutType { cardio, strength, yoga, pilates, hiit, powerlifting, running, cycling }
enum Equipment { none, dumbbells, barbell, rack, cardio_machine, resistance_bands, kettlebells }
enum ContextPriority { low, medium, high, critical }

// コンテキスト分析結果
class ContextAnalysis {
  final String summary;
  final Map<String, String> keyMetrics;
  final List<String> recommendations;
  final ContextPriority priority;
  final DateTime? analyzedAt;
  final double? confidenceScore;

  const ContextAnalysis({
    required this.summary,
    required this.keyMetrics,
    required this.recommendations,
    required this.priority,
    this.analyzedAt,
    this.confidenceScore,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContextAnalysis &&
          runtimeType == other.runtimeType &&
          summary == other.summary &&
          priority == other.priority;

  @override
  int get hashCode => summary.hashCode ^ priority.hashCode;
}

// コンテキスト分析サービス
abstract class ContextAnalyzer {
  /// ユーザーコンテキストを分析する
  Future<ContextAnalysis> analyzeUserContext(UserContext userContext);

  /// アクティビティデータから洞察を抽出する
  Future<ContextAnalysis> analyzeActivityData(List<Activity> activities);

  /// 複合的なコンテキスト分析を実行する
  Future<ContextAnalysis> analyzeComprehensiveContext({
    required UserContext userContext,
    List<Activity>? activities,
    Map<String, dynamic>? additionalData,
  });
}

// 実装クラス
class ContextAnalyzerImpl implements ContextAnalyzer {
  static const int _maxActivitiesToAnalyze = 50;
  static const Duration _analysisTimeWindow = Duration(days: 30);

  @override
  Future<ContextAnalysis> analyzeUserContext(UserContext userContext) async {
    try {
      final summary = _generateUserSummary(userContext);
      final keyMetrics = _extractUserMetrics(userContext);
      final recommendations = _generateUserRecommendations(userContext);
      final priority = _calculateUserPriority(userContext);
      final confidenceScore = _calculateUserConfidence(userContext);

      return ContextAnalysis(
        summary: summary,
        keyMetrics: keyMetrics,
        recommendations: recommendations,
        priority: priority,
        analyzedAt: DateTime.now(),
        confidenceScore: confidenceScore,
      );
    } catch (e) {
      // フォールバック分析
      return ContextAnalysis(
        summary: 'Basic user profile analysis',
        keyMetrics: {'user_id': userContext.userId},
        recommendations: ['Continue with regular fitness activities'],
        priority: ContextPriority.low,
        analyzedAt: DateTime.now(),
        confidenceScore: 0.3,
      );
    }
  }

  @override
  Future<ContextAnalysis> analyzeActivityData(List<Activity> activities) async {
    try {
      // 最新のアクティビティに絞る
      final recentActivities = _filterRecentActivities(activities);

      final summary = _generateActivitySummary(recentActivities);
      final keyMetrics = _extractActivityMetrics(recentActivities);
      final recommendations = _generateActivityRecommendations(recentActivities);
      final priority = _calculateActivityPriority(recentActivities);
      final confidenceScore = _calculateActivityConfidence(recentActivities);

      return ContextAnalysis(
        summary: summary,
        keyMetrics: keyMetrics,
        recommendations: recommendations,
        priority: priority,
        analyzedAt: DateTime.now(),
        confidenceScore: confidenceScore,
      );
    } catch (e) {
      // フォールバック分析
      return ContextAnalysis(
        summary: 'Basic activity analysis',
        keyMetrics: {'activity_count': activities.length.toString()},
        recommendations: ['Continue with current activity level'],
        priority: ContextPriority.low,
        analyzedAt: DateTime.now(),
        confidenceScore: 0.3,
      );
    }
  }

  @override
  Future<ContextAnalysis> analyzeComprehensiveContext({
    required UserContext userContext,
    List<Activity>? activities,
    Map<String, dynamic>? additionalData,
  }) async {
    final userAnalysis = await analyzeUserContext(userContext);

    ContextAnalysis? activityAnalysis;
    if (activities != null && activities.isNotEmpty) {
      activityAnalysis = await analyzeActivityData(activities);
    }

    // 複合分析結果を生成
    final summary = _generateComprehensiveSummary(userAnalysis, activityAnalysis);
    final keyMetrics = _mergeMetrics(userAnalysis.keyMetrics, activityAnalysis?.keyMetrics);
    final recommendations = _mergeRecommendations(userAnalysis.recommendations, activityAnalysis?.recommendations);
    final priority = _calculateCombinedPriority(userAnalysis.priority, activityAnalysis?.priority);
    final confidenceScore = _calculateCombinedConfidence(userAnalysis.confidenceScore, activityAnalysis?.confidenceScore);

    return ContextAnalysis(
      summary: summary,
      keyMetrics: keyMetrics,
      recommendations: recommendations,
      priority: priority,
      analyzedAt: DateTime.now(),
      confidenceScore: confidenceScore,
    );
  }

  // ユーザー分析ヘルパーメソッド
  String _generateUserSummary(UserContext userContext) {
    final parts = <String>[];

    if (userContext.fitnessLevel != null) {
      parts.add(_fitnessLevelToString(userContext.fitnessLevel!));
    }

    if (userContext.gender != null) {
      parts.add(_genderToString(userContext.gender!));
    }

    if (userContext.age != null) {
      final ageGroup = _getAgeGroup(userContext.age!);
      parts.add(ageGroup);
    }

    parts.add('user');

    if (userContext.goals != null && userContext.goals!.isNotEmpty) {
      final primaryGoal = _getPrimaryGoal(userContext.goals!);
      parts.add('focused on $primaryGoal');
    }

    return parts.join(' ');
  }

  Map<String, String> _extractUserMetrics(UserContext userContext) {
    final metrics = <String, String>{
      'user_id': userContext.userId,
    };

    if (userContext.age != null) {
      metrics['age'] = userContext.age.toString();
      metrics['age_group'] = _getAgeGroup(userContext.age!);
    }

    if (userContext.gender != null) {
      metrics['gender'] = _genderToString(userContext.gender!);
    }

    if (userContext.fitnessLevel != null) {
      metrics['fitness_level'] = _fitnessLevelToString(userContext.fitnessLevel!);
    }

    if (userContext.goals != null && userContext.goals!.isNotEmpty) {
      metrics['primary_goal'] = _getPrimaryGoal(userContext.goals!);
      metrics['goal_count'] = userContext.goals!.length.toString();
    }

    if (userContext.preferences?.availableTime != null) {
      metrics['available_time'] = userContext.preferences!.availableTime.toString();
    }

    if (userContext.preferences?.workoutTypes != null) {
      metrics['preferred_workouts'] = userContext.preferences!.workoutTypes!
          .map((w) => _workoutTypeToString(w))
          .join(',');
    }

    return metrics;
  }

  List<String> _generateUserRecommendations(UserContext userContext) {
    final recommendations = <String>[];

    // フィットネスレベルに基づく推奨
    if (userContext.fitnessLevel != null) {
      switch (userContext.fitnessLevel!) {
        case FitnessLevel.beginner:
          recommendations.add('Start with low-intensity workouts');
          recommendations.add('Focus on proper form and technique');
          break;
        case FitnessLevel.intermediate:
          recommendations.add('Increase workout intensity gradually');
          recommendations.add('Consider adding variety to your routine');
          break;
        case FitnessLevel.advanced:
          recommendations.add('Focus on specific performance goals');
          recommendations.add('Consider advanced training techniques');
          break;
      }
    }

    // 目標に基づく推奨
    if (userContext.goals != null) {
      for (final goal in userContext.goals!) {
        switch (goal) {
          case FitnessGoal.fatLoss:
            recommendations.add('Combine cardio with strength training');
            recommendations.add('Focus on caloric deficit through diet');
            break;
          case FitnessGoal.muscleGain:
            recommendations.add('Prioritize progressive overload');
            recommendations.add('Ensure adequate protein intake');
            break;
          case FitnessGoal.strength:
            recommendations.add('Focus on compound movements');
            recommendations.add('Gradually increase weights');
            break;
          case FitnessGoal.endurance:
            recommendations.add('Include longer cardio sessions');
            recommendations.add('Build aerobic base gradually');
            break;
          case FitnessGoal.health:
            recommendations.add('Maintain consistent activity levels');
            recommendations.add('Focus on overall well-being');
            break;
          case FitnessGoal.weightMaintenance:
            recommendations.add('Balance caloric intake and expenditure');
            recommendations.add('Monitor weight trends regularly');
            break;
        }
      }
    }

    // 時間制約に基づく推奨
    if (userContext.preferences?.availableTime != null) {
      final time = userContext.preferences!.availableTime!;
      if (time <= 30) {
        recommendations.add('Consider high-intensity interval training');
        recommendations.add('Focus on compound exercises');
      } else if (time >= 60) {
        recommendations.add('Include warm-up and cool-down periods');
        recommendations.add('Add variety with different exercise types');
      }
    }

    return recommendations.take(5).toList(); // 最大5つの推奨事項
  }

  ContextPriority _calculateUserPriority(UserContext userContext) {
    int score = 0;

    // 基本情報の完全性
    if (userContext.age != null) score += 1;
    if (userContext.gender != null) score += 1;
    if (userContext.fitnessLevel != null) score += 2;
    if (userContext.goals != null && userContext.goals!.isNotEmpty) score += 3;
    if (userContext.preferences != null) score += 2;

    // スコアに基づく優先度
    if (score >= 7) return ContextPriority.high;
    if (score >= 4) return ContextPriority.medium;
    return ContextPriority.low;
  }

  double _calculateUserConfidence(UserContext userContext) {
    double confidence = 0.0;
    int factors = 0;

    if (userContext.age != null) {
      confidence += 0.15;
      factors++;
    }

    if (userContext.gender != null) {
      confidence += 0.1;
      factors++;
    }

    if (userContext.fitnessLevel != null) {
      confidence += 0.25;
      factors++;
    }

    if (userContext.goals != null && userContext.goals!.isNotEmpty) {
      confidence += 0.3;
      factors++;
    }

    if (userContext.preferences != null) {
      confidence += 0.2;
      factors++;
    }

    return factors > 0 ? confidence : 0.1;
  }

  // アクティビティ分析ヘルパーメソッド
  List<Activity> _filterRecentActivities(List<Activity> activities) {
    final cutoffDate = DateTime.now().subtract(_analysisTimeWindow);
    return activities
        .where((activity) => activity.startTime.isAfter(cutoffDate))
        .take(_maxActivitiesToAnalyze)
        .toList();
  }

  String _generateActivitySummary(List<Activity> activities) {
    if (activities.isEmpty) {
      return 'No recent activity data available';
    }

    final activityTypes = activities.map((a) => a.type).toSet();
         final totalCalories = activities.fold<double>(0, (sum, a) => sum + (a.calories ?? 0));
    final avgDuration = activities.fold<double>(0, (sum, a) =>
        sum + a.endTime.difference(a.startTime).inMinutes) / activities.length;

    return 'Recent ${activities.length} activities with ${activityTypes.length} different types, '
           'average ${avgDuration.round()} minutes, total ${totalCalories.round()} calories burned';
  }

  Map<String, String> _extractActivityMetrics(List<Activity> activities) {
    if (activities.isEmpty) {
      return {'activity_count': '0'};
    }

         final metrics = <String, String>{
       'activity_count': activities.length.toString(),
       'total_calories': activities.fold<double>(0, (sum, a) => sum + (a.calories ?? 0)).round().toString(),
       'avg_duration': (activities.fold<double>(0, (sum, a) =>
           sum + a.endTime.difference(a.startTime).inMinutes) / activities.length).round().toString(),
     };

     // 活動タイプの分析
     final typeCount = <ActivityType, int>{};
     for (final activity in activities) {
       typeCount[activity.type] = (typeCount[activity.type] ?? 0) + 1;
     }

     if (typeCount.isNotEmpty) {
       final mostCommonType = typeCount.entries
           .reduce((a, b) => a.value > b.value ? a : b)
           .key;
       metrics['most_common_activity'] = mostCommonType.toString().split('.').last;
     }

     // 心拍数データがある場合（NormalizedActivityではaverageHeartRateを使用）
     final activitiesWithHR = activities.where((a) => a.averageHeartRate != null).toList();
     if (activitiesWithHR.isNotEmpty) {
       final avgHeartRate = activitiesWithHR.fold<double>(0, (sum, a) =>
           sum + a.averageHeartRate!) / activitiesWithHR.length;
       metrics['avg_heart_rate'] = avgHeartRate.round().toString();
     }

     // 距離データ
     final totalDistance = activities.fold<double>(0, (sum, a) => sum + (a.distance ?? 0));
     if (totalDistance > 0) {
       metrics['total_distance'] = (totalDistance / 1000).round().toString(); // km
       metrics['avg_distance'] = ((totalDistance / 1000) / activities.length).toStringAsFixed(1);
     }

    return metrics;
  }

  List<String> _generateActivityRecommendations(List<Activity> activities) {
    final recommendations = <String>[];

    if (activities.isEmpty) {
      recommendations.add('Start tracking your fitness activities');
      recommendations.add('Begin with light exercises');
      return recommendations;
    }

    // 活動頻度の分析
    final daysWithActivity = activities.map((a) =>
        DateTime(a.startTime.year, a.startTime.month, a.startTime.day)).toSet().length;

    if (daysWithActivity < 3) {
      recommendations.add('Try to increase activity frequency');
      recommendations.add('Aim for at least 3-4 workout days per week');
    }

    // 活動の多様性
    final activityTypes = activities.map((a) => a.type).toSet();
    if (activityTypes.length == 1) {
      recommendations.add('Consider adding variety to your workouts');
      recommendations.add('Cross-training can improve overall fitness');
    }

         // 心拍数の分析
     final activitiesWithHR = activities.where((a) => a.averageHeartRate != null).toList();
     if (activitiesWithHR.isNotEmpty) {
       final avgHeartRate = activitiesWithHR.fold<double>(0, (sum, a) =>
           sum + a.averageHeartRate!) / activitiesWithHR.length;

      if (avgHeartRate < 120) {
        recommendations.add('Consider increasing workout intensity');
      } else if (avgHeartRate > 160) {
        recommendations.add('Monitor heart rate zones for optimal training');
      }
    }

    // 継続性の分析
    if (activities.length >= 5) {
      recommendations.add('Great job maintaining consistency!');
      recommendations.add('Consider setting new challenges');
    }

    return recommendations.take(4).toList();
  }

  ContextPriority _calculateActivityPriority(List<Activity> activities) {
    if (activities.isEmpty) return ContextPriority.low;

    final recentActivity = activities.isNotEmpty &&
        activities.first.startTime.isAfter(DateTime.now().subtract(const Duration(days: 3)));

         final hasVariety = activities.map((a) => a.type).toSet().length > 1;
     final hasHeartRateData = activities.any((a) => a.averageHeartRate != null);

    if (recentActivity && hasVariety && hasHeartRateData) {
      return ContextPriority.high;
    } else if (recentActivity && (hasVariety || hasHeartRateData)) {
      return ContextPriority.medium;
    }

    return ContextPriority.low;
  }

  double _calculateActivityConfidence(List<Activity> activities) {
    if (activities.isEmpty) return 0.1;

    double confidence = 0.3; // ベースライン

    // データの豊富さ
    if (activities.length >= 10) confidence += 0.2;
    else if (activities.length >= 5) confidence += 0.1;

    // 多様性
    final activityTypes = activities.map((a) => a.type).toSet().length;
    if (activityTypes >= 3) confidence += 0.2;
    else if (activityTypes >= 2) confidence += 0.1;

         // 詳細データの存在
     if (activities.any((a) => a.averageHeartRate != null)) confidence += 0.2;
    if (activities.any((a) => a.distance != null && a.distance! > 0)) confidence += 0.1;

    // 新しさ
    final hasRecentData = activities.any((a) =>
        a.startTime.isAfter(DateTime.now().subtract(const Duration(days: 7))));
    if (hasRecentData) confidence += 0.1;

    return confidence.clamp(0.1, 1.0);
  }

  // 複合分析ヘルパーメソッド
  String _generateComprehensiveSummary(ContextAnalysis userAnalysis, ContextAnalysis? activityAnalysis) {
    if (activityAnalysis == null) {
      return userAnalysis.summary;
    }

    return '${userAnalysis.summary} with ${activityAnalysis.summary.toLowerCase()}';
  }

  Map<String, String> _mergeMetrics(Map<String, String> userMetrics, Map<String, String>? activityMetrics) {
    final merged = Map<String, String>.from(userMetrics);
    if (activityMetrics != null) {
      merged.addAll(activityMetrics);
    }
    return merged;
  }

  List<String> _mergeRecommendations(List<String> userRecs, List<String>? activityRecs) {
    final merged = List<String>.from(userRecs);
    if (activityRecs != null) {
      merged.addAll(activityRecs);
    }
    return merged.take(8).toList(); // 最大8つの推奨事項
  }

  ContextPriority _calculateCombinedPriority(ContextPriority userPriority, ContextPriority? activityPriority) {
    if (activityPriority == null) return userPriority;

    final userScore = _priorityToScore(userPriority);
    final activityScore = _priorityToScore(activityPriority);
    final combinedScore = (userScore + activityScore) / 2;

    return _scoreToPriority(combinedScore);
  }

  double? _calculateCombinedConfidence(double? userConfidence, double? activityConfidence) {
    if (userConfidence == null) return activityConfidence;
    if (activityConfidence == null) return userConfidence;

    // 加重平均（ユーザーデータを重視）
    return (userConfidence * 0.6 + activityConfidence * 0.4);
  }

  // ユーティリティメソッド
  String _fitnessLevelToString(FitnessLevel level) {
    switch (level) {
      case FitnessLevel.beginner: return 'beginner';
      case FitnessLevel.intermediate: return 'intermediate';
      case FitnessLevel.advanced: return 'advanced';
    }
  }

  String _genderToString(Gender gender) {
    switch (gender) {
      case Gender.male: return 'male';
      case Gender.female: return 'female';
      case Gender.other: return 'other';
    }
  }

  String _getAgeGroup(int age) {
    if (age < 25) return 'young adult';
    if (age < 35) return 'adult';
    if (age < 50) return 'middle-aged';
    return 'mature adult';
  }

  String _getPrimaryGoal(List<FitnessGoal> goals) {
    // 優先度順
    const priority = [
      FitnessGoal.fatLoss,
      FitnessGoal.muscleGain,
      FitnessGoal.strength,
      FitnessGoal.endurance,
      FitnessGoal.health,
      FitnessGoal.weightMaintenance,
    ];

    for (final goal in priority) {
      if (goals.contains(goal)) {
        return goal.toString().split('.').last.replaceAll(RegExp(r'([A-Z])'), ' \$1').toLowerCase().trim();
      }
    }

    return goals.first.toString().split('.').last;
  }

  String _workoutTypeToString(WorkoutType type) {
    return type.toString().split('.').last;
  }

  int _priorityToScore(ContextPriority priority) {
    switch (priority) {
      case ContextPriority.low: return 1;
      case ContextPriority.medium: return 2;
      case ContextPriority.high: return 3;
      case ContextPriority.critical: return 4;
    }
  }

  ContextPriority _scoreToPriority(double score) {
    if (score >= 3.5) return ContextPriority.critical;
    if (score >= 2.5) return ContextPriority.high;
    if (score >= 1.5) return ContextPriority.medium;
    return ContextPriority.low;
  }
}