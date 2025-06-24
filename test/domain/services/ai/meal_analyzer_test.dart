import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fatgram/domain/services/ai/meal_analyzer.dart';
import 'package:fatgram/domain/services/ai/prompt_builder.dart';
import 'package:fatgram/data/datasources/ai/secure_api_client.dart';
import 'package:fatgram/core/security/api_key_manager.dart';
import 'package:fatgram/core/error/exceptions.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'dart:io';

// Mock classes
class MockPromptBuilder extends Mock implements PromptBuilder {}
class MockSecureApiClient extends Mock implements SecureApiClient {}
class MockFile extends Mock implements File {}

void main() {
  late MealAnalyzer mealAnalyzer;
  late MockPromptBuilder mockPromptBuilder;
  late MockSecureApiClient mockSecureApiClient;

  setUp(() {
    mockPromptBuilder = MockPromptBuilder();
    mockSecureApiClient = MockSecureApiClient();
    mealAnalyzer = MealAnalyzerImpl(
      promptBuilder: mockPromptBuilder,
      apiClient: mockSecureApiClient,
    );
  });

  group('MealAnalyzer - 基本機能', () {
    test('正常に初期化される', () {
      expect(mealAnalyzer, isNotNull);
      expect(mealAnalyzer.supportedImageFormats, isNotEmpty);
      expect(mealAnalyzer.maxImageSizeBytes, equals(10 * 1024 * 1024));
    });

    test('サポートされている画像フォーマットを確認', () {
      final formats = mealAnalyzer.supportedImageFormats;
      expect(formats, contains(ImageFormat.jpeg));
      expect(formats, contains(ImageFormat.png));
      expect(formats, contains(ImageFormat.webp));
    });
  });

  group('MealAnalyzer - 画像認識機能', () {
    test('画像から食材を正しく認識する', () async {
      // Arrange
      final mockFile = MockFile();
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

      when(() => mockFile.readAsBytes()).thenAnswer((_) async => imageBytes);
      when(() => mockFile.lengthSync()).thenReturn(1024);
      when(() => mockFile.path).thenReturn('/path/to/image.jpg');

      when(() => mockSecureApiClient.post(
        any(),
        apiProvider: ApiProvider.gemini,
        data: any(named: 'data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'foods': [
            {
              'name': 'Apple',
              'confidence': 0.95,
              'bounding_box': {'x': 10, 'y': 10, 'width': 100, 'height': 100},
              'category': 'fruit',
            },
          ],
          'processing_time_ms': 1500,
        },
      ));

      // Act
      final result = await mealAnalyzer.recognizeFood(mockFile);

      // Assert
      expect(result.detectedFoods.length, equals(1));
      expect(result.detectedFoods[0].name, equals('Apple'));
      expect(result.detectedFoods[0].confidence, equals(0.95));
      expect(result.processingTime.inMilliseconds, greaterThan(0));

      verify(() => mockFile.readAsBytes()).called(1);
      verify(() => mockSecureApiClient.post(
        any(),
        apiProvider: ApiProvider.gemini,
        data: any(named: 'data'),
      )).called(1);
    });

    test('画像サイズが制限を超える場合エラーを投げる', () async {
      // Arrange
      final mockFile = MockFile();
      when(() => mockFile.lengthSync()).thenReturn(15 * 1024 * 1024); // 15MB

      // Act & Assert
      expect(
        () => mealAnalyzer.recognizeFood(mockFile),
        throwsA(isA<ValidationException>()),
      );
    });

    test('サポートされていない画像フォーマットでエラーを投げる', () async {
      // Arrange
      final mockFile = MockFile();
      when(() => mockFile.path).thenReturn('/path/to/image.bmp');
      when(() => mockFile.lengthSync()).thenReturn(1024);

      // Act & Assert
      expect(
        () => mealAnalyzer.recognizeFood(mockFile),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('MealAnalyzer - 栄養素推定', () {
    test('認識された食材からカロリーを推定する', () async {
      // Arrange
      final detectedFoods = [
        DetectedFood(
          name: 'Apple',
          confidence: 0.95,
          boundingBox: BoundingBox(x: 10, y: 10, width: 100, height: 100),
          category: FoodCategory.fruit,
        ),
      ];

      when(() => mockSecureApiClient.post(
        any(),
        apiProvider: ApiProvider.gemini,
        data: any(named: 'data'),
      )).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'total_calories': 180,
          'macronutrients': {
            'carbohydrates': 45.0,
            'protein': 2.0,
            'fat': 0.5,
            'fiber': 6.0,
          },
          'portion_sizes': [
            {
              'food_name': 'Apple',
              'estimated_weight': 150.0,
              'unit': 'grams',
              'confidence': 0.8,
            },
          ],
          'analysis_metadata': {
            'data_source': 'USDA Food Database',
            'analysis_method': 'AI-powered estimation',
            'confidence_score': 0.82,
          },
        },
      ));

      // Act
      final result = await mealAnalyzer.estimateNutrition(detectedFoods);

      // Assert
      expect(result.totalCalories, equals(180));
      expect(result.macronutrients.carbohydrates, equals(45.0));
      expect(result.macronutrients.protein, equals(2.0));
      expect(result.portionSizes.length, equals(1));
      expect(result.portionSizes[0].foodName, equals('Apple'));
      expect(result.analysisMetadata.confidenceScore, equals(0.82));
    });

    test('空の食材リストでエラーを投げる', () async {
      // Act & Assert
      expect(
        () => mealAnalyzer.estimateNutrition([]),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('MealAnalyzer - 食事記録機能', () {
    test('食事記録を正常に作成する', () async {
      // Arrange
      final mealRecord = MealRecord(
        id: 'meal-123',
        userId: 'user-456',
        timestamp: DateTime.now(),
        mealType: MealType.lunch,
        detectedFoods: const [],
        nutritionEstimate: NutritionEstimate(
          totalCalories: 250,
          macronutrients: const Macronutrients(
            carbohydrates: 30.0,
            protein: 20.0,
            fat: 10.0,
            fiber: 5.0,
          ),
          portionSizes: const [],
          analysisMetadata: NutritionAnalysisMetadata(
            dataSource: 'USDA Food Database',
            analysisMethod: 'AI-powered estimation',
            confidenceScore: 0.8,
            lastUpdated: DateTime.now(),
          ),
        ),
        imageMetadata: const ImageMetadata(
          width: 800,
          height: 600,
          format: ImageFormat.jpeg,
          sizeBytes: 2048,
        ),
        isVerified: false,
      );

      // Act
      final savedRecord = await mealAnalyzer.saveMealRecord(mealRecord);

      // Assert
      expect(savedRecord.id, equals('meal-123'));
      expect(savedRecord.mealType, equals(MealType.lunch));
      expect(savedRecord.nutritionEstimate.totalCalories, equals(250));
      expect(savedRecord.isVerified, isFalse);
    });

    test('食事記録の履歴を取得する', () async {
      // Arrange
      final startDate = DateTime.now().subtract(const Duration(days: 7));
      final endDate = DateTime.now();

      // Act
      final records = await mealAnalyzer.getMealHistory(
        userId: 'user-456',
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      expect(records, isNotEmpty);
      expect(records.first.userId, equals('user-456'));
    });

    test('無効なユーザーIDでエラーを投げる', () async {
      // Act & Assert
      expect(
        () => mealAnalyzer.getMealHistory(
          userId: '',
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('MealAnalyzer - 統計機能', () {
    test('日次栄養統計を取得する', () async {
      // Arrange
      final date = DateTime.now();

      // Act
      final stats = await mealAnalyzer.getDailyNutritionStats(
        userId: 'user-456',
        date: date,
      );

      // Assert
      expect(stats.totalCalories, equals(1800));
      expect(stats.macronutrients.protein, equals(90.0));
      expect(stats.achievementPercentage, equals(0.9));
    });

    test('週次栄養トレンドを取得する', () async {
      // Arrange
      final startDate = DateTime.now().subtract(const Duration(days: 7));

      // Act
      final trends = await mealAnalyzer.getWeeklyNutritionTrends(
        userId: 'user-456',
        weekStartDate: startDate,
      );

      // Assert
      expect(trends.averageCalories, equals(1850));
      expect(trends.goalAchievementRate, equals(0.85));
      expect(trends.recommendations, contains('Increase fiber intake'));
    });
  });

  group('MealAnalyzer - エラーハンドリング', () {
    test('API呼び出し失敗時の適切なエラーハンドリング', () async {
      // Arrange
      final mockFile = MockFile();
      when(() => mockFile.readAsBytes()).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
      when(() => mockFile.lengthSync()).thenReturn(1024);
      when(() => mockFile.path).thenReturn('/path/to/image.jpg');

      when(() => mockSecureApiClient.post(
        any(),
        apiProvider: ApiProvider.gemini,
        data: any(named: 'data'),
      )).thenThrow(const NetworkException(message: 'API request failed'));

      // Act & Assert
      expect(
        () => mealAnalyzer.recognizeFood(mockFile),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}