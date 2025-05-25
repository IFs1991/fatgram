class DailyStats {
  final DateTime date;
  final double fatGramsBurned;
  final double caloriesBurned;
  final int totalDurationInSeconds;
  final int activityCount;

  DailyStats({
    required this.date,
    required this.fatGramsBurned,
    required this.caloriesBurned,
    required this.totalDurationInSeconds,
    required this.activityCount,
  });

  // Factory method to create an empty day stats
  factory DailyStats.empty(DateTime date) {
    return DailyStats(
      date: date,
      fatGramsBurned: 0.0,
      caloriesBurned: 0.0,
      totalDurationInSeconds: 0,
      activityCount: 0,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'fatGramsBurned': fatGramsBurned,
      'caloriesBurned': caloriesBurned,
      'totalDurationInSeconds': totalDurationInSeconds,
      'activityCount': activityCount,
    };
  }
}

class WeeklyActivityStats {
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final List<DailyStats> dailyStats;
  final double totalFatGramsBurned;
  final double totalCaloriesBurned;
  final int totalDurationInSeconds;
  final int totalActivityCount;

  WeeklyActivityStats({
    required this.weekStartDate,
    required this.weekEndDate,
    required this.dailyStats,
    required this.totalFatGramsBurned,
    required this.totalCaloriesBurned,
    required this.totalDurationInSeconds,
    required this.totalActivityCount,
  });

  // Factory method to create a weekly stats object from daily stats
  factory WeeklyActivityStats.fromDailyStats(
      DateTime weekStartDate, List<DailyStats> dailyStats) {
    double totalFatGramsBurned = 0.0;
    double totalCaloriesBurned = 0.0;
    int totalDurationInSeconds = 0;
    int totalActivityCount = 0;

    for (var dailyStat in dailyStats) {
      totalFatGramsBurned += dailyStat.fatGramsBurned;
      totalCaloriesBurned += dailyStat.caloriesBurned;
      totalDurationInSeconds += dailyStat.totalDurationInSeconds;
      totalActivityCount += dailyStat.activityCount;
    }

    final weekEndDate = weekStartDate.add(const Duration(days: 6));

    return WeeklyActivityStats(
      weekStartDate: weekStartDate,
      weekEndDate: weekEndDate,
      dailyStats: dailyStats,
      totalFatGramsBurned: totalFatGramsBurned,
      totalCaloriesBurned: totalCaloriesBurned,
      totalDurationInSeconds: totalDurationInSeconds,
      totalActivityCount: totalActivityCount,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'weekStartDate': weekStartDate.toIso8601String(),
      'weekEndDate': weekEndDate.toIso8601String(),
      'dailyStats': dailyStats.map((day) => day.toJson()).toList(),
      'totalFatGramsBurned': totalFatGramsBurned,
      'totalCaloriesBurned': totalCaloriesBurned,
      'totalDurationInSeconds': totalDurationInSeconds,
      'totalActivityCount': totalActivityCount,
    };
  }
}