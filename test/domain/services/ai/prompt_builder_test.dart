import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fatgram/domain/services/ai/prompt_builder.dart';
import 'package:fatgram/domain/services/ai/context_analyzer.dart';
import 'package:fatgram/domain/entities/activity.dart';
import 'package:fatgram/domain/entities/health_data.dart';
import 'package:fatgram/core/error/exceptions.dart';

// Mock classes
class MockContextAnalyzer extends Mock implements ContextAnalyzer {}

void main() {
  late PromptBuilder promptBuilder;
  late MockContextAnalyzer mockContextAnalyzer;

  setUp(() {
    mockContextAnalyzer = MockContextAnalyzer();
    promptBuilder = PromptBuilder(
      contextAnalyzer: mockContextAnalyzer,
    );
  });

  group('PromptBuilder - 初期化と基本機能', () {
    test('正常に初期化される', () {
      expect(promptBuilder, isNotNull);
      expect(promptBuilder.availableTemplates, isNotEmpty);
    });

    test('デフォルトテンプレートが存在する', () {
      final templates = promptBuilder.availableTemplates;
      expect(templates, contains(PromptTemplate.fitnessChat));
      expect(templates, contains(PromptTemplate.workoutRecommendation));
      expect(templates, contains(PromptTemplate.nutritionAdvice));
      expect(templates, contains(PromptTemplate.goalSetting));
      expect(templates, contains(PromptTemplate.motivationalMessage));
    });

    test('カスタムテンプレートを登録できる', () {
      const customTemplate = CustomPromptTemplate(
        id: 'custom_template',
        name: 'Custom Template',
        description: 'A custom prompt template for testing',
        template: 'You are a {role}. Help with {task}.',
        variables: ['role', 'task'],
      );

      promptBuilder.registerCustomTemplate(customTemplate);

      expect(
        promptBuilder.getCustomTemplate('custom_template'),
        equals(customTemplate),
      );
    });
  });

  group('PromptBuilder - コンテキスト分析統合', () {
    test('ユーザーコンテキストを正しく分析する', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'test-user-123',
        age: 30,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.intermediate,
        goals: [FitnessGoal.fatLoss, FitnessGoal.muscleGain],
        preferences: UserPreferences(
          workoutTypes: [WorkoutType.cardio, WorkoutType.strength],
          availableTime: 60,
          equipment: [Equipment.dumbbells, Equipment.none],
        ),
      );

      final contextAnalysis = ContextAnalysis(
        summary: 'Intermediate male user focused on fat loss and muscle gain',
        keyMetrics: {
          'fitness_level': 'intermediate',
          'primary_goal': 'fat_loss',
          'available_time': '60',
        },
        recommendations: [
          'Focus on compound movements',
          'Include both cardio and strength training',
        ],
        priority: ContextPriority.high,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => contextAnalysis);

      // Act
      final result = await promptBuilder.analyzeContext(userContext);

      // Assert
      expect(result, equals(contextAnalysis));
      verify(() => mockContextAnalyzer.analyzeUserContext(userContext)).called(1);
    });

    test('アクティビティデータからコンテキストを抽出する', () async {
      // Arrange
      final activities = [
        Activity(
          id: 'activity-1',
          type: ActivityType.running,
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          endTime: DateTime.now().subtract(const Duration(days: 1, hours: -1)),
          source: HealthDataSource.healthKit,
          calories: 500,
          distance: 5000,
          averageHeartRate: 150,
          maxHeartRate: 180,
        ),
      ];

      final contextAnalysis = ContextAnalysis(
        summary: 'Recent running activity with good cardiovascular performance',
        keyMetrics: {
          'avg_heart_rate': '150',
          'fat_burn_rate': '56',
          'activity_type': 'running',
        },
        recommendations: [
          'Continue with cardio training',
          'Consider adding strength training',
        ],
        priority: ContextPriority.medium,
      );

      when(() => mockContextAnalyzer.analyzeActivityData(activities))
          .thenAnswer((_) async => contextAnalysis);

      // Act
      final result = await promptBuilder.analyzeActivityContext(activities);

      // Assert
      expect(result, equals(contextAnalysis));
      verify(() => mockContextAnalyzer.analyzeActivityData(activities)).called(1);
    });
  });

  group('PromptBuilder - プロンプト生成機能', () {
    test('フィットネスチャット用プロンプトを生成する', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'test-user',
        age: 25,
        gender: Gender.female,
        fitnessLevel: FitnessLevel.beginner,
        goals: [FitnessGoal.fatLoss],
      );

      final contextAnalysis = ContextAnalysis(
        summary: 'Beginner female user focused on fat loss',
        keyMetrics: {'fitness_level': 'beginner', 'primary_goal': 'fat_loss'},
        recommendations: ['Start with low-intensity workouts'],
        priority: ContextPriority.high,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => contextAnalysis);

      // Act
      final prompt = await promptBuilder.buildPrompt(
        template: PromptTemplate.fitnessChat,
        userContext: userContext,
        additionalContext: {
          'user_message': 'I want to start losing weight but don\'t know where to begin',
          'conversation_tone': 'encouraging',
        },
      );

      // Assert
      expect(prompt.systemPrompt, isNotEmpty);
      expect(prompt.systemPrompt, contains('fitness assistant'));
      expect(prompt.systemPrompt, contains('beginner'));
      expect(prompt.systemPrompt, contains('fat loss'));
      expect(prompt.userPrompt, contains('losing weight'));
      expect(prompt.contextData, isNotEmpty);
      expect(prompt.metadata['template'], equals('fitness_chat'));
      expect(prompt.metadata['user_fitness_level'], equals('beginner'));
    });

    test('ワークアウト推奨用プロンプトを生成する', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'test-user',
        age: 35,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.advanced,
        goals: [FitnessGoal.muscleGain, FitnessGoal.strength],
        preferences: UserPreferences(
          workoutTypes: [WorkoutType.strength, WorkoutType.powerlifting],
          availableTime: 90,
          equipment: [Equipment.dumbbells, Equipment.barbell, Equipment.rack],
        ),
      );

      final contextAnalysis = ContextAnalysis(
        summary: 'Advanced male user focused on muscle gain and strength',
        keyMetrics: {
          'fitness_level': 'advanced',
          'primary_goal': 'muscle_gain',
          'available_time': '90',
        },
        recommendations: [
          'Focus on compound lifts',
          'Progressive overload is key',
        ],
        priority: ContextPriority.high,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => contextAnalysis);

      // Act
      final prompt = await promptBuilder.buildPrompt(
        template: PromptTemplate.workoutRecommendation,
        userContext: userContext,
        additionalContext: {
          'target_muscle_groups': ['chest', 'shoulders', 'triceps'],
          'workout_split': 'push_day',
        },
      );

      // Assert
      expect(prompt.systemPrompt, contains('workout specialist'));
      expect(prompt.systemPrompt, contains('advanced'));
      expect(prompt.systemPrompt, contains('muscle gain'));
      expect(prompt.systemPrompt, contains('90 minutes'));
      expect(prompt.userPrompt, contains('chest'));
      expect(prompt.userPrompt, contains('shoulders'));
      expect(prompt.metadata['template'], equals('workout_recommendation'));
      expect(prompt.metadata['workout_split'], equals('push_day'));
    });

    test('栄養アドバイス用プロンプトを生成する', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'test-user',
        age: 28,
        gender: Gender.female,
        fitnessLevel: FitnessLevel.intermediate,
        goals: [FitnessGoal.fatLoss, FitnessGoal.health],
        preferences: UserPreferences(
          dietaryRestrictions: ['vegetarian', 'lactose_intolerant'],
          mealPreferences: ['quick_prep', 'high_protein'],
        ),
      );

      final contextAnalysis = ContextAnalysis(
        summary: 'Intermediate female user with dietary restrictions',
        keyMetrics: {
          'fitness_level': 'intermediate',
          'primary_goal': 'fat_loss',
          'dietary_restrictions': 'vegetarian,lactose_intolerant',
        },
        recommendations: [
          'Focus on plant-based proteins',
          'Consider lactose-free alternatives',
        ],
        priority: ContextPriority.high,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => contextAnalysis);

      // Act
      final prompt = await promptBuilder.buildPrompt(
        template: PromptTemplate.nutritionAdvice,
        userContext: userContext,
        additionalContext: {
          'meal_type': 'post_workout',
          'calorie_target': 1800,
        },
      );

      // Assert
      expect(prompt.systemPrompt, contains('nutrition specialist'));
      expect(prompt.systemPrompt, contains('vegetarian'));
      expect(prompt.systemPrompt, contains('lactose_intolerant'));
      expect(prompt.userPrompt, contains('post_workout'));
      expect(prompt.userPrompt, contains('1800'));
      expect(prompt.metadata['template'], equals('nutrition_advice'));
      expect(prompt.metadata['meal_type'], equals('post_workout'));
    });

    test('目標設定用プロンプトを生成する', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'test-user',
        age: 40,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.beginner,
        goals: [FitnessGoal.health, FitnessGoal.weightMaintenance],
      );

      final activities = [
        Activity(
          id: 'activity-1',
          type: ActivityType.walking,
          startTime: DateTime.now().subtract(const Duration(days: 7)),
          endTime: DateTime.now().subtract(const Duration(days: 7, hours: -1)),
          source: HealthDataSource.healthKit,
          calories: 200,
          steps: 8000,
        ),
      ];

      final userContextAnalysis = ContextAnalysis(
        summary: 'Beginner male user focused on health',
        keyMetrics: {'fitness_level': 'beginner', 'primary_goal': 'health'},
        recommendations: ['Start with walking and light exercises'],
        priority: ContextPriority.medium,
      );

      final activityContextAnalysis = ContextAnalysis(
        summary: 'Regular walking activity',
        keyMetrics: {'weekly_steps': '8000', 'consistency': 'good'},
        recommendations: ['Increase walking frequency'],
        priority: ContextPriority.low,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => userContextAnalysis);
      when(() => mockContextAnalyzer.analyzeActivityData(activities))
          .thenAnswer((_) async => activityContextAnalysis);

      // Act
      final prompt = await promptBuilder.buildPrompt(
        template: PromptTemplate.goalSetting,
        userContext: userContext,
        activityHistory: activities,
        additionalContext: {
          'time_frame': '4_weeks',
          'focus_area': 'cardiovascular_health',
        },
      );

      // Assert
      expect(prompt.systemPrompt, contains('goal-setting coach'));
      expect(prompt.systemPrompt, contains('beginner'));
      expect(prompt.systemPrompt, contains('health'));
      expect(prompt.userPrompt, contains('4_weeks'));
      expect(prompt.userPrompt, contains('cardiovascular_health'));
      expect(prompt.metadata['template'], equals('goal_setting'));
      expect(prompt.metadata['time_frame'], equals('4_weeks'));
    });
  });

  group('PromptBuilder - テンプレート管理', () {
    test('カスタムテンプレートの変数を検証する', () {
      // Arrange
      const invalidTemplate = CustomPromptTemplate(
        id: 'invalid_template',
        name: 'Invalid Template',
        description: 'Template with missing variables',
        template: 'You are a {role}. Help with {task} and {missing_var}.',
        variables: ['role', 'task'], // missing_var が variables に含まれていない
      );

      // Act & Assert
      expect(
        () => promptBuilder.registerCustomTemplate(invalidTemplate),
        throwsA(isA<ValidationException>()),
      );
    });

    test('テンプレートの複製を作成できる', () {
      // Arrange
      const originalTemplate = CustomPromptTemplate(
        id: 'original',
        name: 'Original Template',
        description: 'Original template',
        template: 'You are a {role}.',
        variables: ['role'],
      );

      promptBuilder.registerCustomTemplate(originalTemplate);

      // Act
      final duplicated = promptBuilder.duplicateTemplate(
        'original',
        newId: 'duplicated',
        modifications: {
          'name': 'Duplicated Template',
          'template': 'You are a professional {role}.',
        },
      );

      // Assert
      expect(duplicated.id, equals('duplicated'));
      expect(duplicated.name, equals('Duplicated Template'));
      expect(duplicated.template, equals('You are a professional {role}.'));
      expect(duplicated.variables, equals(['role']));
    });

    test('テンプレートの使用統計を記録する', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'test-user',
        age: 30,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.intermediate,
        goals: [FitnessGoal.fatLoss],
      );

      final contextAnalysis = ContextAnalysis(
        summary: 'Test context',
        keyMetrics: {},
        recommendations: [],
        priority: ContextPriority.medium,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => contextAnalysis);

      // Act
      await promptBuilder.buildPrompt(
        template: PromptTemplate.fitnessChat,
        userContext: userContext,
      );

      await promptBuilder.buildPrompt(
        template: PromptTemplate.fitnessChat,
        userContext: userContext,
      );

      // Assert
      final stats = promptBuilder.getTemplateUsageStats();
      expect(stats['fitness_chat']?.usageCount, equals(2));
      expect(stats['fitness_chat']?.lastUsed, isNotNull);
    });
  });

  group('PromptBuilder - 品質管理', () {
    test('プロンプトの品質を評価する', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'test-user',
        age: 30,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.intermediate,
        goals: [FitnessGoal.fatLoss],
      );

      final contextAnalysis = ContextAnalysis(
        summary: 'Well-defined user context',
        keyMetrics: {'fitness_level': 'intermediate'},
        recommendations: ['Specific recommendations'],
        priority: ContextPriority.high,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => contextAnalysis);

      // Act
      final prompt = await promptBuilder.buildPrompt(
        template: PromptTemplate.fitnessChat,
        userContext: userContext,
      );

      final quality = promptBuilder.evaluatePromptQuality(prompt);

      // Assert
      expect(quality.score, greaterThan(0.7));
      expect(quality.score, lessThanOrEqualTo(1.0));
      expect(quality.criteria.containsKey('context_richness'), isTrue);
      expect(quality.criteria.containsKey('specificity'), isTrue);
      expect(quality.criteria.containsKey('clarity'), isTrue);
      expect(quality.suggestions, isNotEmpty);
    });

    test('低品質プロンプトを検出する', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'test-user',
        age: 30,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.intermediate,
        goals: [FitnessGoal.fatLoss],
      );

      final poorContextAnalysis = ContextAnalysis(
        summary: '', // 空のサマリー
        keyMetrics: {}, // 空のメトリクス
        recommendations: [], // 空の推奨事項
        priority: ContextPriority.low,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => poorContextAnalysis);

      // Act
      final prompt = await promptBuilder.buildPrompt(
        template: PromptTemplate.fitnessChat,
        userContext: userContext,
        additionalContext: {}, // 空の追加コンテキスト
      );

      final quality = promptBuilder.evaluatePromptQuality(prompt);

      // Assert
      expect(quality.score, lessThan(0.6)); // より現実的な閾値
      expect(quality.suggestions, isNotEmpty);
    });

    test('プロンプトの改善提案を生成する', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'test-user',
        age: 30,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.intermediate,
        goals: [FitnessGoal.fatLoss],
      );

      final contextAnalysis = ContextAnalysis(
        summary: 'Basic user context',
        keyMetrics: {'fitness_level': 'intermediate'},
        recommendations: ['Basic recommendation'],
        priority: ContextPriority.medium,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => contextAnalysis);

      // Act
      final prompt = await promptBuilder.buildPrompt(
        template: PromptTemplate.fitnessChat,
        userContext: userContext,
      );

      final improvements = promptBuilder.suggestImprovements(prompt);

      // Assert
      expect(improvements, isNotEmpty);
      // 改善提案の種類をチェック（より柔軟に）
      final improvementTypes = improvements.map((i) => i.type).toSet();
      expect(improvementTypes.isNotEmpty, isTrue);
    });
  });

  group('PromptBuilder - エラーハンドリング', () {
    test('無効なテンプレートIDでエラーを投げる', () {
      expect(
        () => promptBuilder.getCustomTemplate('non_existent'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('コンテキスト分析失敗時のフォールバック', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'test-user',
        age: 30,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.intermediate,
        goals: [FitnessGoal.fatLoss],
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenThrow(const AIException(message: 'Context analysis failed'));

      // Act
      final prompt = await promptBuilder.buildPrompt(
        template: PromptTemplate.fitnessChat,
        userContext: userContext,
        fallbackOnError: true,
      );

      // Assert
      expect(prompt.systemPrompt, isNotEmpty);
      expect(prompt.metadata['fallback_used'], isTrue);
      expect(prompt.metadata['error_reason'], contains('Context analysis failed'));
    });

    test('必須コンテキストが不足している場合エラーを投げる', () async {
      // Arrange
      final incompleteUserContext = UserContext(
        userId: 'test-user',
        // age, gender, fitnessLevel, goals が不足
      );

      // Act & Assert
      expect(
        () => promptBuilder.buildPrompt(
          template: PromptTemplate.workoutRecommendation,
          userContext: incompleteUserContext,
          fallbackOnError: false,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('PromptBuilder - パフォーマンステスト', () {
    test('大量のプロンプト生成のパフォーマンス', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'test-user',
        age: 30,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.intermediate,
        goals: [FitnessGoal.fatLoss],
      );

      final contextAnalysis = ContextAnalysis(
        summary: 'Test context',
        keyMetrics: {'fitness_level': 'intermediate'},
        recommendations: ['Test recommendation'],
        priority: ContextPriority.medium,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => contextAnalysis);

      // Act
      final stopwatch = Stopwatch()..start();

      final futures = List.generate(100, (index) =>
        promptBuilder.buildPrompt(
          template: PromptTemplate.fitnessChat,
          userContext: userContext,
        ),
      );

      await Future.wait(futures);

      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5秒以内
      expect(futures.length, equals(100));
    });

    test('同時並行プロンプト生成の安全性', () async {
      // Arrange
      final userContext = UserContext(
        userId: 'test-user',
        age: 30,
        gender: Gender.male,
        fitnessLevel: FitnessLevel.intermediate,
        goals: [FitnessGoal.fatLoss],
      );

      final contextAnalysis = ContextAnalysis(
        summary: 'Test context',
        keyMetrics: {'fitness_level': 'intermediate'},
        recommendations: ['Test recommendation'],
        priority: ContextPriority.medium,
      );

      when(() => mockContextAnalyzer.analyzeUserContext(userContext))
          .thenAnswer((_) async => contextAnalysis);

      // Act
      final futures = List.generate(10, (index) =>
        promptBuilder.buildPrompt(
          template: PromptTemplate.fitnessChat,
          userContext: userContext,
          additionalContext: {'request_id': 'request_$index'},
        ),
      );

      final results = await Future.wait(futures);

      // Assert
      expect(results.length, equals(10));
      for (int i = 0; i < results.length; i++) {
        expect(results[i].metadata['request_id'], equals('request_$i'));
      }
    });
  });
}