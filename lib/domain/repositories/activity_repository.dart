import '../models/activity_model.dart';
import '../models/weekly_activity_stats.dart';

abstract class ActivityRepository {
  /// アクティビティを取得する
  Future<List<Activity>> getActivities({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// アクティビティを保存する
  Future<void> saveActivity(Activity activity);

  /// スマートウォッチからアクティビティを同期する
  Future<List<Activity>> syncActivitiesFromHealthKit();

  /// 週間アクティビティ統計を取得する
  Future<WeeklyActivityStats> getWeeklyActivityStats({
    required DateTime weekStartDate,
  });
}