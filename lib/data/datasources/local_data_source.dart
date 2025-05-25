import '../../domain/models/activity_model.dart';
import '../../domain/models/user_model.dart';

abstract class LocalDataSource {
  /// アクティビティを取得する
  Future<List<Activity>> getActivities({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  });

  /// アクティビティを保存する
  Future<void> saveActivity(Activity activity);

  /// アクティビティリストを保存する
  Future<void> saveActivities(List<Activity> activities);

  /// 未同期のアクティビティを取得する
  Future<List<Activity>> getUnsyncedActivities(String userId);

  /// アクティビティを同期済みとしてマークする
  Future<void> markActivityAsSynced(String activityId);

  /// 現在のユーザーを保存する
  Future<void> saveCurrentUser(User user);

  /// 現在のユーザーを取得する
  Future<User?> getCurrentUser();

  /// ユーザーをクリアする (ログアウト時など)
  Future<void> clearUser();
}