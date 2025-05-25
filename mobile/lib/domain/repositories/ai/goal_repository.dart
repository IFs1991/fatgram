import 'package:fatgram/domain/models/ai/user_goal.dart';

abstract class GoalRepository {
  /// AIを活用してユーザーに適したゴールを提案する
  Future<List<UserGoal>> suggestGoals({
    int limit = 3,
    Map<String, dynamic>? userContext,
  });

  /// 新しいゴールを作成する
  Future<UserGoal> createGoal(UserGoal goal);

  /// ユーザーの全てのゴールを取得する
  Future<List<UserGoal>> getUserGoals({
    GoalStatus? status,
    GoalType? type,
  });

  /// 特定のゴールの詳細を取得する
  Future<UserGoal> getGoalDetails(String goalId);

  /// ゴールの進捗を更新する
  Future<UserGoal> updateGoalProgress({
    required String goalId,
    required double newValue,
    String? notes,
  });

  /// ゴールのステータスを更新する
  Future<UserGoal> updateGoalStatus({
    required String goalId,
    required GoalStatus newStatus,
  });

  /// ゴールを削除する
  Future<void> deleteGoal(String goalId);

  /// ゴールの目標値やターゲット日付を更新する
  Future<UserGoal> updateGoalTarget({
    required String goalId,
    double? newTargetValue,
    DateTime? newTargetDate,
  });

  /// ゴールのマイルストーンを追加する
  Future<UserGoal> addGoalMilestone({
    required String goalId,
    required GoalMilestone milestone,
  });
}