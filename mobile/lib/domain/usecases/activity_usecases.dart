import '../models/activity.dart';
import '../repositories/activity_repository.dart';

/// アクティビティ保存ユースケース
class SaveActivities {
  final ActivityRepository repository;

  SaveActivities(this.repository);

  Future<void> call(List<Activity> activities) {
    return repository.saveActivities(activities);
  }
}

/// アクティビティ同期ユースケース
class SyncActivities {
  final ActivityRepository repository;

  SyncActivities(this.repository);

  Future<Map<String, dynamic>> call() {
    return repository.syncActivities();
  }
}

/// アクティビティ取得ユースケース
class GetActivities {
  final ActivityRepository repository;

  GetActivities(this.repository);

  Future<List<Activity>> call({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getActivities(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

/// 脂肪燃焼量取得ユースケース
class GetTotalFatBurned {
  final ActivityRepository repository;

  GetTotalFatBurned(this.repository);

  Future<double> call({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getTotalFatBurned(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

/// アクティビティタイプ別統計取得ユースケース
class GetActivityTypeStats {
  final ActivityRepository repository;

  GetActivityTypeStats(this.repository);

  Future<Map<String, dynamic>> call({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getActivityTypeStats(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

/// 週間レポート取得ユースケース
class GetWeeklyReport {
  final ActivityRepository repository;

  GetWeeklyReport(this.repository);

  Future<Map<String, dynamic>> call({
    required DateTime date,
  }) {
    return repository.getWeeklyReport(
      date: date,
    );
  }
}