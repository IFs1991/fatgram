import '../models/activity.dart';

/// アクティビティリポジトリインターフェース
abstract class ActivityRepository {
  /// アクティビティの保存
  Future<void> saveActivities(List<Activity> activities);

  /// アクティビティの同期
  ///
  /// 未同期のアクティビティをサーバーに送信します
  Future<Map<String, dynamic>> syncActivities();

  /// アクティビティの取得
  Future<List<Activity>> getActivities({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 期間別の合計脂肪燃焼量の取得
  Future<double> getTotalFatBurned({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// アクティビティタイプ別の統計取得
  Future<Map<String, dynamic>> getActivityTypeStats({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 週間レポート取得
  Future<Map<String, dynamic>> getWeeklyReport({
    required DateTime date,
  });

  /// 週間アクティビティの統計取得
  Future<Map<String, dynamic>> getWeeklyActivityStats({
    required DateTime startDate,
    required DateTime endDate,
  });
}