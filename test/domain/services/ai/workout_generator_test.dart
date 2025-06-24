import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fatgram/domain/services/ai/workout_generator.dart';
import 'package:fatgram/domain/services/ai/prompt_builder.dart';
import 'package:fatgram/domain/services/ai/context_analyzer.dart';
import 'package:fatgram/data/datasources/ai/secure_api_client.dart';
import 'package:fatgram/core/security/api_key_manager.dart';
import 'package:fatgram/core/error/exceptions.dart';
import 'package:dio/dio.dart';

// Mock classes
class MockPromptBuilder extends Mock implements PromptBuilder {}
class MockContextAnalyzer extends Mock implements ContextAnalyzer {}
class MockSecureApiClient extends Mock implements SecureApiClient {}

void main() {
  late WorkoutGenerator workoutGenerator;
  late MockPromptBuilder mockPromptBuilder;
  late MockContextAnalyzer mockContextAnalyzer;
  late MockSecureApiClient mockSecureApiClient;

  setUp(() {
    mockPromptBuilder = MockPromptBuilder();
    mockContextAnalyzer = MockContextAnalyzer();
    mockSecureApiClient = MockSecureApiClient();
    workoutGenerator = WorkoutGeneratorImpl(
      promptBuilder: mockPromptBuilder,
      contextAnalyzer: mockContextAnalyzer,
      apiClient: mockSecureApiClient,
    );
  });

  group('WorkoutGenerator - 基本機能', () {
    test('正常に初期化される', () {
      expect(workoutGenerator, isNotNull);
      expect(workoutGenerator.supportedWorkoutTypes, isNotEmpty);
      expect(workoutGenerator.supportedEquipment, isNotEmpty);
    });

    test('サポートされているワークアウトタイプを確認', () {
      final types = workoutGenerator.supportedWorkoutTypes;
      expect(types, contains(WorkoutType.strength));
      expect(types, contains(WorkoutType.cardio));
      expect(types, contains(WorkoutType.yoga));
    });

    test('サポートされている器具を確認', () {
      final equipment = workoutGenerator.supportedEquipment;
      expect(equipment, contains(Equipment.dumbbells));
      expect(equipment, contains(Equipment.barbell));
      expect(equipment, contains(Equipment.none));
    });
  });

  group('WorkoutGenerator - ワークアウト生成', () {
    test('パーソナライズされたワークアウトを生成する', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'user-123',
        age: 30,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.intermediate,
        goals: [FitnessGoal.muscleGain, FitnessGoal.strength],
        preferences: UserPreferences(
          workoutTypes: [WorkoutType.strength],
          availableTime: 60,
          equipment: [Equipment.dumbbells, Equipment.barbell],
        ),
      );

      final workoutRequest = WorkoutRequest(
        targetMuscleGroups: [MuscleGroup.chest, MuscleGroup.shoulders],
        duration: 60,
        intensity: WorkoutIntensity.moderate,
        workoutType: WorkoutType.strength,
        equipment: [Equipment.dumbbells],
      );

      final contextAnalysis = ContextAnalysis(
        summary: 'Intermediate male user focused on muscle gain',
        keyMetrics: {'fitness_level': 'intermediate', 'primary_goal': 'muscle_gain'},
        recommendations: ['Focus on compound movements'],
        priority: ContextPriority.high,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => contextAnalysis);

      when(() => mockSecureApiClient.post(
        any(),
        apiProvider: ApiProvider.gemini,
        data: any(named: 'data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'workout_plan': {
            'name': 'Upper Body Strength',
            'description': 'Focused chest and shoulder workout',
            'estimated_duration': 60,
            'difficulty_level': 'intermediate',
            'exercises': [
              {
                'name': 'Dumbbell Bench Press',
                'muscle_groups': ['chest', 'shoulders', 'triceps'],
                'equipment': ['dumbbells'],
                'sets': 3,
                'reps': '8-10',
                'rest_seconds': 90,
                'instructions': 'Lie on bench, press dumbbells up and down',
                'form_tips': ['Keep core tight', 'Control the weight'],
              },
            ],
            'warm_up': {
              'duration_minutes': 5,
              'exercises': ['Arm circles', 'Light stretching'],
            },
            'cool_down': {
              'duration_minutes': 5,
              'exercises': ['Chest stretch', 'Shoulder stretch'],
            },
          },
          'generation_metadata': {
            'ai_confidence': 0.9,
            'personalization_score': 0.85,
            'safety_rating': 'high',
          },
        },
      ));

      // Act
      final result = await workoutGenerator.generateWorkout(
        userContext: userContext,
        request: workoutRequest,
      );

      // Assert
      expect(result.workoutPlan.name, equals('Upper Body Strength'));
      expect(result.workoutPlan.exercises.length, equals(1));
      expect(result.workoutPlan.exercises[0].name, equals('Dumbbell Bench Press'));
      expect(result.workoutPlan.exercises[0].sets, equals(3));
      expect(result.generationMetadata.aiConfidence, equals(0.9));

      verify(() => mockContextAnalyzer.analyzeUserContext(userContext)).called(1);
      verify(() => mockSecureApiClient.post(
        any(),
        apiProvider: ApiProvider.gemini,
        data: any(named: 'data'),
      )).called(1);
    });

    test('進捗に基づいてワークアウトを調整する', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'user-123',
        age: 25,
        gender: Gender.female,
        fitnessLevel: FitnessLevel.beginner,
        goals: [FitnessGoal.fatLoss],
      );

      final progressData = WorkoutProgress(
        completedWorkouts: 5,
        averageIntensity: 0.7,
        strengthGains: {'bench_press': 10.0, 'squat': 15.0},
        enduranceImprovements: {'running_distance': 2.0},
        lastWorkoutDate: DateTime.now().subtract(const Duration(days: 2)),
        consistencyScore: 0.8,
      );

      when(() => mockSecureApiClient.post(
        any(),
        apiProvider: ApiProvider.gemini,
        data: any(named: 'data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'workout_plan': {
            'name': 'Progressive Cardio',
            'description': 'Adjusted for recent progress',
            'estimated_duration': 45,
            'difficulty_level': 'beginner_plus',
            'exercises': [
              {
                'name': 'Incline Walking',
                'muscle_groups': ['legs', 'glutes'],
                'equipment': ['treadmill'],
                'duration_minutes': 30,
                'intensity': 'moderate',
                'instructions': 'Walk at 3.5 mph with 5% incline',
              },
            ],
          },
          'adjustments_made': [
            'Increased intensity based on progress',
            'Added incline for progression',
          ],
        },
      ));

      // Act
      final result = await workoutGenerator.generateAdaptiveWorkout(
        userContext: userContext,
        progressData: progressData,
      );

      // Assert
      expect(result.workoutPlan.name, equals('Progressive Cardio'));
      expect(result.adjustmentsMade, contains('Increased intensity based on progress'));
    });

    test('器具なしワークアウトを生成する', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'user-123',
        age: 28,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.intermediate,
        goals: [FitnessGoal.health],
        preferences: UserPreferences(
          equipment: [Equipment.none],
          availableTime: 30,
        ),
      );

      final workoutRequest = WorkoutRequest(
        targetMuscleGroups: [MuscleGroup.fullBody],
        duration: 30,
        intensity: WorkoutIntensity.moderate,
        workoutType: WorkoutType.hiit,
        equipment: [Equipment.none],
      );

      final contextAnalysis = ContextAnalysis(
        summary: 'Intermediate male user focused on health',
        keyMetrics: {'fitness_level': 'intermediate', 'primary_goal': 'health'},
        recommendations: ['Focus on bodyweight exercises'],
        priority: ContextPriority.medium,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => contextAnalysis);

      when(() => mockSecureApiClient.post(
        any(),
        apiProvider: ApiProvider.gemini,
        data: any(named: 'data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'workout_plan': {
            'name': 'Bodyweight HIIT',
            'description': 'No equipment full body workout',
            'estimated_duration': 30,
            'exercises': [
              {
                'name': 'Push-ups',
                'muscle_groups': ['chest', 'shoulders', 'triceps'],
                'equipment': [],
                'sets': 3,
                'reps': '10-15',
                'rest_seconds': 60,
              },
              {
                'name': 'Squats',
                'muscle_groups': ['legs', 'glutes'],
                'equipment': [],
                'sets': 3,
                'reps': '15-20',
                'rest_seconds': 60,
              },
            ],
          },
        },
      ));

      // Act
      final result = await workoutGenerator.generateWorkout(
        userContext: userContext,
        request: workoutRequest,
      );

      // Assert
      expect(result.workoutPlan.name, equals('Bodyweight HIIT'));
      expect(result.workoutPlan.exercises.length, equals(2));
      expect(result.workoutPlan.exercises.every((e) => e.equipment.isEmpty), isTrue);
    });
  });

  group('WorkoutGenerator - ワークアウトプラン管理', () {
    test('ワークアウトプランを保存する', () async {
      // Arrange
      final workoutPlan = WorkoutPlan(
        id: 'plan-123',
        name: 'My Custom Workout',
        description: 'Personal strength training plan',
        estimatedDuration: 45,
        difficultyLevel: DifficultyLevel.intermediate,
        exercises: const [],
        warmUp: const WarmUpCoolDown(
          durationMinutes: 5,
          exercises: ['Dynamic stretching'],
        ),
        coolDown: const WarmUpCoolDown(
          durationMinutes: 5,
          exercises: ['Static stretching'],
        ),
        createdAt: DateTime.now(),
      );

      // Act
      final savedPlan = await workoutGenerator.saveWorkoutPlan(workoutPlan);

      // Assert
      expect(savedPlan.id, equals('plan-123'));
      expect(savedPlan.name, equals('My Custom Workout'));
    });

    test('ユーザーのワークアウトプラン履歴を取得する', () async {
      // Arrange
      const userId = 'user-123';

      // Act
      final plans = await workoutGenerator.getUserWorkoutPlans(userId);

      // Assert
      expect(plans, isNotEmpty);
      expect(plans.first.id, isNotNull);
    });

    test('ワークアウトプランをお気に入りに追加する', () async {
      // Arrange
      const userId = 'user-123';
      const planId = 'plan-456';

      // Act
      final result = await workoutGenerator.addToFavorites(userId, planId);

      // Assert
      expect(result, isTrue);
    });
  });

  group('WorkoutGenerator - 進捗追跡', () {
    test('ワークアウト完了を記録する', () async {
      // Arrange
      final completedWorkout = CompletedWorkout(
        id: 'completed-123',
        userId: 'user-456',
        workoutPlanId: 'plan-789',
        completedAt: DateTime.now(),
        duration: 45,
        exercises: [
          CompletedExercise(
            exerciseName: 'Push-ups',
            setsCompleted: 3,
            repsCompleted: [12, 10, 8],
            weightUsed: null,
            notes: 'Felt strong today',
          ),
        ],
        overallRating: 4,
        difficultyRating: 3,
        notes: 'Great workout session',
      );

      // Act
      final savedWorkout = await workoutGenerator.recordCompletedWorkout(completedWorkout);

      // Assert
      expect(savedWorkout.id, equals('completed-123'));
      expect(savedWorkout.overallRating, equals(4));
      expect(savedWorkout.exercises.length, equals(1));
    });

    test('進捗統計を計算する', () async {
      // Arrange
      const userId = 'user-123';
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now();

      // Act
      final stats = await workoutGenerator.getProgressStats(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      expect(stats.totalWorkouts, greaterThan(0));
      expect(stats.averageDuration, greaterThan(0));
      expect(stats.consistencyScore, greaterThanOrEqualTo(0.0));
      expect(stats.consistencyScore, lessThanOrEqualTo(1.0));
    });
  });

  group('WorkoutGenerator - エラーハンドリング', () {
    test('無効なワークアウトリクエストでエラーを投げる', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'user-123',
        age: 30,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.intermediate,
        goals: [FitnessGoal.muscleGain],
      );

      final invalidRequest = WorkoutRequest(
        targetMuscleGroups: [], // 空のリスト
        duration: 0, // 無効な時間
        intensity: WorkoutIntensity.low,
        workoutType: WorkoutType.strength,
        equipment: [Equipment.dumbbells],
      );

      // Act & Assert
      expect(
        () => workoutGenerator.generateWorkout(
          userContext: userContext,
          request: invalidRequest,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('API呼び出し失敗時の適切なエラーハンドリング', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'user-123',
        age: 30,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.intermediate,
        goals: [FitnessGoal.muscleGain],
      );

      final workoutRequest = WorkoutRequest(
        targetMuscleGroups: [MuscleGroup.chest],
        duration: 60,
        intensity: WorkoutIntensity.moderate,
        workoutType: WorkoutType.strength,
        equipment: [Equipment.dumbbells],
      );

      final contextAnalysis = ContextAnalysis(
        summary: 'Intermediate male user focused on muscle gain',
        keyMetrics: {'fitness_level': 'intermediate', 'primary_goal': 'muscle_gain'},
        recommendations: ['Focus on compound movements'],
        priority: ContextPriority.high,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => contextAnalysis);

      when(() => mockSecureApiClient.post(
        any(),
        apiProvider: ApiProvider.gemini,
        data: any(named: 'data'),
      )).thenThrow(const NetworkException(message: 'API request failed'));

      // Act & Assert
      expect(
        () => workoutGenerator.generateWorkout(
          userContext: userContext,
          request: workoutRequest,
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test('空のユーザーIDでエラーを投げる', () async {
      // Act & Assert
      expect(
        () => workoutGenerator.getUserWorkoutPlans(''),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('WorkoutGenerator - パフォーマンステスト', () {
    test('大量のワークアウト生成のパフォーマンス', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'user-123',
        age: 30,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.intermediate,
        goals: [FitnessGoal.muscleGain],
      );

      final workoutRequest = WorkoutRequest(
        targetMuscleGroups: [MuscleGroup.chest],
        duration: 30,
        intensity: WorkoutIntensity.moderate,
        workoutType: WorkoutType.strength,
        equipment: [Equipment.dumbbells],
      );

      final contextAnalysis = ContextAnalysis(
        summary: 'Intermediate male user focused on muscle gain',
        keyMetrics: {'fitness_level': 'intermediate', 'primary_goal': 'muscle_gain'},
        recommendations: ['Focus on compound movements'],
        priority: ContextPriority.high,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => contextAnalysis);

      when(() => mockSecureApiClient.post(
        any(),
        apiProvider: ApiProvider.gemini,
        data: any(named: 'data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'workout_plan': {
            'name': 'Quick Workout',
            'description': 'Fast workout',
            'estimated_duration': 30,
            'exercises': [],
          },
        },
      ));

      // Act
      final stopwatch = Stopwatch()..start();

      final futures = List.generate(10, (index) =>
        workoutGenerator.generateWorkout(
          userContext: userContext,
          request: workoutRequest,
        ),
      );

      await Future.wait(futures);

      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5秒以内
      expect(futures.length, equals(10));
    });
  });
}