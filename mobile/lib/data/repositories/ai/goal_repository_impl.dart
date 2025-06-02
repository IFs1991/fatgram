import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fatgram/core/error/exceptions.dart';
import 'package:fatgram/data/datasources/ai/gemini_api_client.dart';
import 'package:fatgram/domain/models/ai/user_goal.dart';
import 'package:fatgram/domain/repositories/ai/goal_repository.dart';
import 'package:logger/logger.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final geminiClient = ref.watch(geminiClientProvider);
  return GoalRepositoryImpl(
    apiClient: geminiClient,
    logger: Logger(),
  );
});

class GoalRepositoryImpl implements GoalRepository {
  final GeminiApiClient apiClient;
  final Logger logger;
  final Uuid _uuid = const Uuid();

  // メモリ内キャッシュ
  final Map<String, UserGoal> _goalCache = {};

  GoalRepositoryImpl({
    required this.apiClient,
    required this.logger,
  });

  @override
  Future<List<UserGoal>> suggestGoals({
    int limit = 3,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      // ユーザーコンテキスト情報を準備
      final contextData = {
        'limit': limit.toString(),
        ...?userContext?.map((key, value) => MapEntry(key.toString(), value.toString())),
      };

      // AI経由でゴール提案を生成
      // final response = await apiClient.generateChatResponse(
      //   history: [
      //     genai.Content(
      //       role: 'user',
      //       parts: [genai.TextPart(text: 'Suggest $limit personalized fitness goals based on my profile and activity data.')],
      //     ),
      //   ],
      //   systemInstructions: {
      //     'role': 'You are a fitness goal setting assistant that helps users set realistic and achievable goals.',
      //     'format': 'Return goals as a JSON array with objects having title, description, targetValue, and timeframe fields.',
      //     'context': contextData.toString(),
      //   },
      // );

      // レスポンスをパースしてゴールリストを作成（実際のAPIでは適切な処理が必要）
      // 簡略化のため、ダミーデータを生成
      final now = DateTime.now();
      final goals = [
        UserGoal(
          id: _uuid.v4(),
          title: 'Daily Fat Burn Goal',
          description: 'Burn at least 500 calories daily through aerobic exercise',
          type: GoalType.fatLoss,
          createdAt: now,
          targetDate: now.add(const Duration(days: 30)),
          status: GoalStatus.notStarted,
          targetValue: 500.0,
          currentValue: 0.0,
          unit: 'calories',
          milestones: [
            GoalMilestone(
              id: _uuid.v4(),
              title: 'Week 1 Target',
              targetValue: 350.0,
              status: GoalStatus.notStarted,
              targetDate: now.add(const Duration(days: 7)),
            ),
            GoalMilestone(
              id: _uuid.v4(),
              title: 'Week 2 Target',
              targetValue: 400.0,
              status: GoalStatus.notStarted,
              targetDate: now.add(const Duration(days: 14)),
            )
          ],
        ),
        UserGoal(
          id: _uuid.v4(),
          title: 'Weekly Activity Streak',
          description: 'Complete at least 5 workout sessions every week',
          type: GoalType.consistencyStreak,
          createdAt: now,
          targetDate: now.add(const Duration(days: 60)),
          status: GoalStatus.notStarted,
          targetValue: 5.0,
          currentValue: 0.0,
          unit: 'sessions',
        ),
        UserGoal(
          id: _uuid.v4(),
          title: 'Monthly Fat Loss',
          description: 'Lose 2kg of fat mass in a month through consistent exercise and diet',
          type: GoalType.fatLoss,
          createdAt: now,
          targetDate: now.add(const Duration(days: 30)),
          status: GoalStatus.notStarted,
          targetValue: 2.0,
          currentValue: 0.0,
          unit: 'kg',
        ),
      ];

      // ゴールをキャッシュに追加
      for (final goal in goals) {
        _goalCache[goal.id] = goal;
      }

      return goals.take(limit).toList();
    } catch (e) {
      logger.e('Error suggesting goals: $e');
      throw AIException(
        message: 'Failed to suggest goals: ${e.toString()}',
      );
    }
  }

  @override
  Future<UserGoal> createGoal(UserGoal goal) async {
    try {
      final goalWithId = goal.id.isEmpty
          ? goal.copyWith(id: _uuid.v4())
          : goal;

      _goalCache[goalWithId.id] = goalWithId;
      return goalWithId;
    } catch (e) {
      logger.e('Error creating goal: $e');
      throw AIException(
        message: 'Failed to create goal: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<UserGoal>> getUserGoals({
    GoalStatus? status,
    GoalType? type,
  }) async {
    try {
      var goals = _goalCache.values.toList();

      if (status != null) {
        goals = goals.where((goal) => goal.status == status).toList();
      }

      if (type != null) {
        goals = goals.where((goal) => goal.type == type).toList();
      }

      // 期限が近い順にソート
      goals.sort((a, b) => a.targetDate.compareTo(b.targetDate));

      return goals;
    } catch (e) {
      logger.e('Error getting user goals: $e');
      throw AIException(
        message: 'Failed to get user goals: ${e.toString()}',
      );
    }
  }

  @override
  Future<UserGoal> getGoalDetails(String goalId) async {
    if (_goalCache.containsKey(goalId)) {
      return _goalCache[goalId]!;
    }

    throw NotFoundException(
      message: 'Goal not found: $goalId',
    );
  }

  @override
  Future<UserGoal> updateGoalProgress({
    required String goalId,
    required double newValue,
    String? notes,
  }) async {
    if (!_goalCache.containsKey(goalId)) {
      throw NotFoundException(
        message: 'Goal not found: $goalId',
      );
    }

    final goal = _goalCache[goalId]!;

    // 進捗を更新
    final updatedGoal = goal.copyWith(
      currentValue: newValue,
      // 目標達成の場合はステータスを更新
      status: newValue >= goal.targetValue
          ? GoalStatus.completed
          : goal.status == GoalStatus.notStarted
              ? GoalStatus.inProgress
              : goal.status,
    );

    _goalCache[goalId] = updatedGoal;
    return updatedGoal;
  }

  @override
  Future<UserGoal> updateGoalStatus({
    required String goalId,
    required GoalStatus newStatus,
  }) async {
    if (!_goalCache.containsKey(goalId)) {
      throw NotFoundException(
        message: 'Goal not found: $goalId',
      );
    }

    final goal = _goalCache[goalId]!;
    final updatedGoal = goal.copyWith(status: newStatus);

    _goalCache[goalId] = updatedGoal;
    return updatedGoal;
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    if (!_goalCache.containsKey(goalId)) {
      throw NotFoundException(
        message: 'Goal not found: $goalId',
      );
    }

    _goalCache.remove(goalId);
  }

  @override
  Future<UserGoal> updateGoalTarget({
    required String goalId,
    double? newTargetValue,
    DateTime? newTargetDate,
  }) async {
    if (!_goalCache.containsKey(goalId)) {
      throw NotFoundException(
        message: 'Goal not found: $goalId',
      );
    }

    final goal = _goalCache[goalId]!;
    final updatedGoal = goal.copyWith(
      targetValue: newTargetValue ?? goal.targetValue,
      targetDate: newTargetDate ?? goal.targetDate,
    );

    _goalCache[goalId] = updatedGoal;
    return updatedGoal;
  }

  @override
  Future<UserGoal> addGoalMilestone({
    required String goalId,
    required GoalMilestone milestone,
  }) async {
    if (!_goalCache.containsKey(goalId)) {
      throw NotFoundException(
        message: 'Goal not found: $goalId',
      );
    }

    final goal = _goalCache[goalId]!;

    // 既存のマイルストーンに新しいマイルストーンを追加
    final milestones = [...?goal.milestones, milestone];

    // マイルストーンを期限順にソート
    milestones.sort((a, b) => a.targetDate.compareTo(b.targetDate));

    final updatedGoal = goal.copyWith(milestones: milestones);

    _goalCache[goalId] = updatedGoal;
    return updatedGoal;
  }
}