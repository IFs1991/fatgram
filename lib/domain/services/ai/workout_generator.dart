import 'package:equatable/equatable.dart';
import 'package:fatgram/domain/services/ai/prompt_builder.dart';
import 'package:fatgram/domain/services/ai/context_analyzer.dart';
import 'package:fatgram/data/datasources/ai/secure_api_client.dart';
import 'package:fatgram/core/security/api_key_manager.dart';
import 'package:fatgram/core/error/exceptions.dart';

// 筋肉グループ
enum MuscleGroup {
  chest,
  back,
  shoulders,
  arms,
  biceps,
  triceps,
  legs,
  quads,
  hamstrings,
  glutes,
  calves,
  core,
  abs,
  fullBody,
}

// ワークアウト強度
enum WorkoutIntensity {
  low,
  moderate,
  high,
  extreme,
}

// 難易度レベル
enum DifficultyLevel {
  beginner,
  beginnerPlus,
  intermediate,
  advanced,
  expert,
}

// ワークアウトリクエスト
class WorkoutRequest extends Equatable {
  final List<MuscleGroup> targetMuscleGroups;
  final int duration; // 分
  final WorkoutIntensity intensity;
  final WorkoutType workoutType;
  final List<Equipment> equipment;
  final String? specificGoals;
  final Map<String, dynamic>? preferences;

  const WorkoutRequest({
    required this.targetMuscleGroups,
    required this.duration,
    required this.intensity,
    required this.workoutType,
    required this.equipment,
    this.specificGoals,
    this.preferences,
  });

  @override
  List<Object?> get props => [
        targetMuscleGroups,
        duration,
        intensity,
        workoutType,
        equipment,
        specificGoals,
        preferences,
      ];
}

// エクササイズ
class Exercise extends Equatable {
  final String name;
  final List<MuscleGroup> muscleGroups;
  final List<Equipment> equipment;
  final int? sets;
  final String? reps; // "8-10" or "30 seconds" など
  final int? restSeconds;
  final int? durationMinutes;
  final String instructions;
  final List<String> formTips;
  final String? videoUrl;
  final DifficultyLevel difficulty;

  const Exercise({
    required this.name,
    required this.muscleGroups,
    required this.equipment,
    this.sets,
    this.reps,
    this.restSeconds,
    this.durationMinutes,
    required this.instructions,
    required this.formTips,
    this.videoUrl,
    required this.difficulty,
  });

  @override
  List<Object?> get props => [
        name,
        muscleGroups,
        equipment,
        sets,
        reps,
        restSeconds,
        durationMinutes,
        instructions,
        formTips,
        videoUrl,
        difficulty,
      ];
}

// ウォームアップ・クールダウン
class WarmUpCoolDown extends Equatable {
  final int durationMinutes;
  final List<String> exercises;
  final String? instructions;

  const WarmUpCoolDown({
    required this.durationMinutes,
    required this.exercises,
    this.instructions,
  });

  @override
  List<Object?> get props => [durationMinutes, exercises, instructions];
}

// ワークアウトプラン
class WorkoutPlan extends Equatable {
  final String id;
  final String name;
  final String description;
  final int estimatedDuration;
  final DifficultyLevel difficultyLevel;
  final List<Exercise> exercises;
  final WarmUpCoolDown warmUp;
  final WarmUpCoolDown coolDown;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.estimatedDuration,
    required this.difficultyLevel,
    required this.exercises,
    required this.warmUp,
    required this.coolDown,
    this.tags,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        estimatedDuration,
        difficultyLevel,
        exercises,
        warmUp,
        coolDown,
        tags,
        createdAt,
        updatedAt,
      ];
}

// 生成メタデータ
class WorkoutGenerationMetadata extends Equatable {
  final double aiConfidence;
  final double personalizationScore;
  final String safetyRating;
  final List<String>? warnings;
  final DateTime generatedAt;

  const WorkoutGenerationMetadata({
    required this.aiConfidence,
    required this.personalizationScore,
    required this.safetyRating,
    this.warnings,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [
        aiConfidence,
        personalizationScore,
        safetyRating,
        warnings,
        generatedAt,
      ];
}

// ワークアウト生成結果
class WorkoutGenerationResult extends Equatable {
  final WorkoutPlan workoutPlan;
  final WorkoutGenerationMetadata generationMetadata;
  final List<String>? adjustmentsMade;

  const WorkoutGenerationResult({
    required this.workoutPlan,
    required this.generationMetadata,
    this.adjustmentsMade,
  });

  @override
  List<Object?> get props => [workoutPlan, generationMetadata, adjustmentsMade];
}

// ワークアウト進捗
class WorkoutProgress extends Equatable {
  final int completedWorkouts;
  final double averageIntensity;
  final Map<String, double> strengthGains; // エクササイズ名 -> 重量増加
  final Map<String, double> enduranceImprovements; // メトリクス名 -> 改善値
  final DateTime lastWorkoutDate;
  final double consistencyScore; // 0.0 - 1.0

  const WorkoutProgress({
    required this.completedWorkouts,
    required this.averageIntensity,
    required this.strengthGains,
    required this.enduranceImprovements,
    required this.lastWorkoutDate,
    required this.consistencyScore,
  });

  @override
  List<Object> get props => [
        completedWorkouts,
        averageIntensity,
        strengthGains,
        enduranceImprovements,
        lastWorkoutDate,
        consistencyScore,
      ];
}

// 完了したエクササイズ
class CompletedExercise extends Equatable {
  final String exerciseName;
  final int setsCompleted;
  final List<int> repsCompleted;
  final double? weightUsed;
  final String? notes;

  const CompletedExercise({
    required this.exerciseName,
    required this.setsCompleted,
    required this.repsCompleted,
    this.weightUsed,
    this.notes,
  });

  @override
  List<Object?> get props => [
        exerciseName,
        setsCompleted,
        repsCompleted,
        weightUsed,
        notes,
      ];
}

// 完了したワークアウト
class CompletedWorkout extends Equatable {
  final String id;
  final String userId;
  final String workoutPlanId;
  final DateTime completedAt;
  final int duration; // 実際にかかった時間（分）
  final List<CompletedExercise> exercises;
  final int overallRating; // 1-5
  final int difficultyRating; // 1-5
  final String? notes;

  const CompletedWorkout({
    required this.id,
    required this.userId,
    required this.workoutPlanId,
    required this.completedAt,
    required this.duration,
    required this.exercises,
    required this.overallRating,
    required this.difficultyRating,
    this.notes,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        workoutPlanId,
        completedAt,
        duration,
        exercises,
        overallRating,
        difficultyRating,
        notes,
      ];
}

// 進捗統計
class WorkoutProgressStats extends Equatable {
  final int totalWorkouts;
  final int totalDuration; // 分
  final double averageDuration;
  final double consistencyScore;
  final Map<WorkoutType, int> workoutTypeBreakdown;
  final Map<String, double> strengthProgress;
  final List<String> achievements;

  const WorkoutProgressStats({
    required this.totalWorkouts,
    required this.totalDuration,
    required this.averageDuration,
    required this.consistencyScore,
    required this.workoutTypeBreakdown,
    required this.strengthProgress,
    required this.achievements,
  });

  @override
  List<Object> get props => [
        totalWorkouts,
        totalDuration,
        averageDuration,
        consistencyScore,
        workoutTypeBreakdown,
        strengthProgress,
        achievements,
      ];
}

// ワークアウト生成サービス抽象クラス
abstract class WorkoutGenerator {
  /// サポートされているワークアウトタイプ
  List<WorkoutType> get supportedWorkoutTypes;

  /// サポートされている器具
  List<Equipment> get supportedEquipment;

  /// パーソナライズされたワークアウトを生成する
  Future<WorkoutGenerationResult> generateWorkout({
    required UserContext userContext,
    required WorkoutRequest request,
  });

  /// 進捗に基づいて適応的なワークアウトを生成する
  Future<WorkoutGenerationResult> generateAdaptiveWorkout({
    required UserContext userContext,
    required WorkoutProgress progressData,
    WorkoutRequest? baseRequest,
  });

  /// ワークアウトプランを保存する
  Future<WorkoutPlan> saveWorkoutPlan(WorkoutPlan plan);

  /// ユーザーのワークアウトプラン履歴を取得する
  Future<List<WorkoutPlan>> getUserWorkoutPlans(String userId);

  /// ワークアウトプランをお気に入りに追加する
  Future<bool> addToFavorites(String userId, String planId);

  /// 完了したワークアウトを記録する
  Future<CompletedWorkout> recordCompletedWorkout(CompletedWorkout workout);

  /// 進捗統計を取得する
  Future<WorkoutProgressStats> getProgressStats({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
}

// ワークアウト生成サービス実装
class WorkoutGeneratorImpl implements WorkoutGenerator {
  final PromptBuilder promptBuilder;
  final ContextAnalyzer contextAnalyzer;
  final SecureApiClient apiClient;

  static const List<WorkoutType> _supportedWorkoutTypes = [
    WorkoutType.strength,
    WorkoutType.cardio,
    WorkoutType.yoga,
    WorkoutType.pilates,
    WorkoutType.hiit,
    WorkoutType.powerlifting,
    WorkoutType.running,
    WorkoutType.cycling,
  ];

  static const List<Equipment> _supportedEquipment = [
    Equipment.none,
    Equipment.dumbbells,
    Equipment.barbell,
    Equipment.rack,
    Equipment.cardio_machine,
    Equipment.resistance_bands,
    Equipment.kettlebells,
  ];

  const WorkoutGeneratorImpl({
    required this.promptBuilder,
    required this.contextAnalyzer,
    required this.apiClient,
  });

  @override
  List<WorkoutType> get supportedWorkoutTypes => _supportedWorkoutTypes;

  @override
  List<Equipment> get supportedEquipment => _supportedEquipment;

  @override
  Future<WorkoutGenerationResult> generateWorkout({
    required UserContext userContext,
    required WorkoutRequest request,
  }) async {
    // リクエストの検証
    _validateWorkoutRequest(request);

    try {
      // ユーザーコンテキストを分析
      final contextAnalysis = await contextAnalyzer.analyzeUserContext(userContext);

      // API呼び出し用のデータを準備
      final requestData = {
        'user_context': {
          'age': userContext.age,
          'gender': userContext.gender?.name,
          'fitness_level': userContext.fitnessLevel?.name,
          'goals': userContext.goals?.map((g) => g.name).toList(),
          'preferences': {
            'workout_types': userContext.preferences?.workoutTypes?.map((w) => w.name).toList(),
            'available_time': userContext.preferences?.availableTime,
            'equipment': userContext.preferences?.equipment?.map((e) => e.name).toList(),
          },
        },
        'workout_request': {
          'target_muscle_groups': request.targetMuscleGroups.map((m) => m.name).toList(),
          'duration': request.duration,
          'intensity': request.intensity.name,
          'workout_type': request.workoutType.name,
          'equipment': request.equipment.map((e) => e.name).toList(),
          'specific_goals': request.specificGoals,
          'preferences': request.preferences,
        },
        'context_analysis': {
          'summary': contextAnalysis.summary,
          'key_metrics': contextAnalysis.keyMetrics,
          'recommendations': contextAnalysis.recommendations,
        },
      };

      // Gemini APIでワークアウト生成を実行
      final response = await apiClient.post(
        '/ai/workout-generation',
        apiProvider: ApiProvider.gemini,
        data: requestData,
      );

      // レスポンスを解析
      return _parseWorkoutGenerationResult(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AIException(
        message: 'Workout generation failed: ${e.toString()}',
        data: {'user_id': userContext.userId},
      );
    }
  }

  @override
  Future<WorkoutGenerationResult> generateAdaptiveWorkout({
    required UserContext userContext,
    required WorkoutProgress progressData,
    WorkoutRequest? baseRequest,
  }) async {
    try {
      // 進捗データに基づいてリクエストを調整
      final adaptedRequest = baseRequest ?? _createDefaultRequest(userContext);

      // API呼び出し用のデータを準備
      final requestData = {
        'user_context': {
          'user_id': userContext.userId,
          'fitness_level': userContext.fitnessLevel?.name,
          'goals': userContext.goals?.map((g) => g.name).toList(),
        },
        'progress_data': {
          'completed_workouts': progressData.completedWorkouts,
          'average_intensity': progressData.averageIntensity,
          'strength_gains': progressData.strengthGains,
          'endurance_improvements': progressData.enduranceImprovements,
          'last_workout_date': progressData.lastWorkoutDate.toIso8601String(),
          'consistency_score': progressData.consistencyScore,
        },
        'base_request': {
          'target_muscle_groups': adaptedRequest.targetMuscleGroups.map((m) => m.name).toList(),
          'duration': adaptedRequest.duration,
          'intensity': adaptedRequest.intensity.name,
          'workout_type': adaptedRequest.workoutType.name,
          'equipment': adaptedRequest.equipment.map((e) => e.name).toList(),
        },
      };

      // Gemini APIで適応的ワークアウト生成を実行
      final response = await apiClient.post(
        '/ai/adaptive-workout-generation',
        apiProvider: ApiProvider.gemini,
        data: requestData,
      );

      // レスポンスを解析
      return _parseWorkoutGenerationResult(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AIException(
        message: 'Adaptive workout generation failed: ${e.toString()}',
        data: {'user_id': userContext.userId},
      );
    }
  }

  @override
  Future<WorkoutPlan> saveWorkoutPlan(WorkoutPlan plan) async {
    try {
      // TODO: データベースに保存する実装
      // 現在はモックとして同じプランを返す
      return plan.copyWith(
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to save workout plan: ${e.toString()}',
        data: {'plan_id': plan.id},
      );
    }
  }

  @override
  Future<List<WorkoutPlan>> getUserWorkoutPlans(String userId) async {
    if (userId.isEmpty) {
      throw ValidationException(message: 'User ID cannot be empty');
    }

    try {
      // TODO: データベースからプラン履歴を取得する実装
      // 現在はモックデータを返す
      final now = DateTime.now();
      return [
        WorkoutPlan(
          id: 'plan-1',
          name: 'Upper Body Strength',
          description: 'Focused upper body workout',
          estimatedDuration: 45,
          difficultyLevel: DifficultyLevel.intermediate,
          exercises: const [],
          warmUp: const WarmUpCoolDown(
            durationMinutes: 5,
            exercises: ['Arm circles', 'Light stretching'],
          ),
          coolDown: const WarmUpCoolDown(
            durationMinutes: 5,
            exercises: ['Upper body stretches'],
          ),
          createdAt: now,
        ),
      ];
    } catch (e) {
      throw CacheException(
        message: 'Failed to get user workout plans: ${e.toString()}',
        data: {'user_id': userId},
      );
    }
  }

  @override
  Future<bool> addToFavorites(String userId, String planId) async {
    try {
      // TODO: お気に入りに追加する実装
      // 現在はモックとして成功を返す
      return true;
    } catch (e) {
      throw CacheException(
        message: 'Failed to add to favorites: ${e.toString()}',
        data: {'user_id': userId, 'plan_id': planId},
      );
    }
  }

  @override
  Future<CompletedWorkout> recordCompletedWorkout(CompletedWorkout workout) async {
    try {
      // TODO: 完了したワークアウトを記録する実装
      // 現在はモックとして同じワークアウトを返す
      return workout;
    } catch (e) {
      throw CacheException(
        message: 'Failed to record completed workout: ${e.toString()}',
        data: {'workout_id': workout.id},
      );
    }
  }

  @override
  Future<WorkoutProgressStats> getProgressStats({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // TODO: データベースから進捗統計を計算する実装
      // 現在はモックデータを返す
      return const WorkoutProgressStats(
        totalWorkouts: 15,
        totalDuration: 675, // 45分 × 15回
        averageDuration: 45.0,
        consistencyScore: 0.8,
        workoutTypeBreakdown: {
          WorkoutType.strength: 10,
          WorkoutType.cardio: 5,
        },
        strengthProgress: {
          'bench_press': 10.0,
          'squat': 15.0,
          'deadlift': 20.0,
        },
        achievements: [
          'Completed 15 workouts this month',
          'Increased bench press by 10kg',
          'Maintained 80% consistency',
        ],
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to get progress stats: ${e.toString()}',
        data: {'user_id': userId},
      );
    }
  }

  // プライベートメソッド
  void _validateWorkoutRequest(WorkoutRequest request) {
    if (request.targetMuscleGroups.isEmpty) {
      throw ValidationException(
        message: 'Target muscle groups cannot be empty',
        data: {'request': request},
      );
    }

    if (request.duration <= 0) {
      throw ValidationException(
        message: 'Workout duration must be greater than 0',
        data: {'duration': request.duration},
      );
    }

    if (request.duration > 180) {
      throw ValidationException(
        message: 'Workout duration cannot exceed 180 minutes',
        data: {'duration': request.duration},
      );
    }
  }

  WorkoutRequest _createDefaultRequest(UserContext userContext) {
    return WorkoutRequest(
      targetMuscleGroups: [MuscleGroup.fullBody],
      duration: userContext.preferences?.availableTime ?? 30,
      intensity: WorkoutIntensity.moderate,
      workoutType: userContext.preferences?.workoutTypes?.first ?? WorkoutType.strength,
      equipment: userContext.preferences?.equipment ?? [Equipment.none],
    );
  }

  WorkoutGenerationResult _parseWorkoutGenerationResult(Map<String, dynamic> response) {
    final workoutPlanData = response['workout_plan'] as Map<String, dynamic>;
    final metadataData = response['generation_metadata'] as Map<String, dynamic>? ?? {};

    // エクササイズを解析
    final exercisesData = workoutPlanData['exercises'] as List? ?? [];
    final exercises = exercisesData.map((exerciseData) {
      return Exercise(
        name: exerciseData['name'] as String,
        muscleGroups: (exerciseData['muscle_groups'] as List)
            .map((mg) => MuscleGroup.values.firstWhere(
                  (m) => m.name == mg,
                  orElse: () => MuscleGroup.fullBody,
                ))
            .toList(),
        equipment: (exerciseData['equipment'] as List? ?? [])
            .map((eq) => Equipment.values.firstWhere(
                  (e) => e.name == eq,
                  orElse: () => Equipment.none,
                ))
            .toList(),
        sets: exerciseData['sets'] as int?,
        reps: exerciseData['reps'] as String?,
        restSeconds: exerciseData['rest_seconds'] as int?,
        durationMinutes: exerciseData['duration_minutes'] as int?,
        instructions: exerciseData['instructions'] as String? ?? '',
        formTips: (exerciseData['form_tips'] as List? ?? []).cast<String>(),
        videoUrl: exerciseData['video_url'] as String?,
        difficulty: DifficultyLevel.values.firstWhere(
          (d) => d.name == exerciseData['difficulty'],
          orElse: () => DifficultyLevel.intermediate,
        ),
      );
    }).toList();

    // ウォームアップとクールダウンを解析
    final warmUpData = workoutPlanData['warm_up'] as Map<String, dynamic>? ?? {};
    final coolDownData = workoutPlanData['cool_down'] as Map<String, dynamic>? ?? {};

    final workoutPlan = WorkoutPlan(
      id: workoutPlanData['id'] as String? ?? 'generated-${DateTime.now().millisecondsSinceEpoch}',
      name: workoutPlanData['name'] as String,
      description: workoutPlanData['description'] as String,
      estimatedDuration: workoutPlanData['estimated_duration'] as int,
      difficultyLevel: DifficultyLevel.values.firstWhere(
        (d) => d.name == workoutPlanData['difficulty_level'],
        orElse: () => DifficultyLevel.intermediate,
      ),
      exercises: exercises,
      warmUp: WarmUpCoolDown(
        durationMinutes: warmUpData['duration_minutes'] as int? ?? 5,
        exercises: (warmUpData['exercises'] as List? ?? []).cast<String>(),
        instructions: warmUpData['instructions'] as String?,
      ),
      coolDown: WarmUpCoolDown(
        durationMinutes: coolDownData['duration_minutes'] as int? ?? 5,
        exercises: (coolDownData['exercises'] as List? ?? []).cast<String>(),
        instructions: coolDownData['instructions'] as String?,
      ),
      createdAt: DateTime.now(),
    );

    final generationMetadata = WorkoutGenerationMetadata(
      aiConfidence: (metadataData['ai_confidence'] as num?)?.toDouble() ?? 0.8,
      personalizationScore: (metadataData['personalization_score'] as num?)?.toDouble() ?? 0.7,
      safetyRating: metadataData['safety_rating'] as String? ?? 'medium',
      warnings: (metadataData['warnings'] as List?)?.cast<String>(),
      generatedAt: DateTime.now(),
    );

    return WorkoutGenerationResult(
      workoutPlan: workoutPlan,
      generationMetadata: generationMetadata,
      adjustmentsMade: (response['adjustments_made'] as List?)?.cast<String>(),
    );
  }
}

// WorkoutPlan の copyWith メソッド拡張
extension WorkoutPlanCopyWith on WorkoutPlan {
  WorkoutPlan copyWith({
    String? id,
    String? name,
    String? description,
    int? estimatedDuration,
    DifficultyLevel? difficultyLevel,
    List<Exercise>? exercises,
    WarmUpCoolDown? warmUp,
    WarmUpCoolDown? coolDown,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      exercises: exercises ?? this.exercises,
      warmUp: warmUp ?? this.warmUp,
      coolDown: coolDown ?? this.coolDown,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}