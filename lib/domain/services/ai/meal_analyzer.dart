import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:fatgram/domain/services/ai/prompt_builder.dart';
import 'package:fatgram/data/datasources/ai/secure_api_client.dart';
import 'package:fatgram/core/security/api_key_manager.dart';
import 'package:fatgram/core/error/exceptions.dart';

// 画像フォーマット
enum ImageFormat {
  jpeg,
  png,
  webp,
  gif,
}

// 食材カテゴリ
enum FoodCategory {
  fruit,
  vegetable,
  protein,
  grain,
  dairy,
  fat,
  beverage,
  snack,
  dessert,
  unknown,
}

// 重量単位
enum WeightUnit {
  grams,
  ounces,
  pounds,
  kilograms,
  cups,
  tablespoons,
  teaspoons,
  pieces,
}

// 食事タイプ
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
}

// トレンド方向
enum TrendDirection {
  increasing,
  decreasing,
  stable,
}

// バウンディングボックス
class BoundingBox extends Equatable {
  final double x;
  final double y;
  final double width;
  final double height;

  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  List<Object> get props => [x, y, width, height];
}

// 検出された食材
class DetectedFood extends Equatable {
  final String name;
  final double confidence;
  final BoundingBox boundingBox;
  final FoodCategory category;
  final Map<String, dynamic>? metadata;

  const DetectedFood({
    required this.name,
    required this.confidence,
    required this.boundingBox,
    required this.category,
    this.metadata,
  });

  @override
  List<Object?> get props => [name, confidence, boundingBox, category, metadata];
}

// 画像メタデータ
class ImageMetadata extends Equatable {
  final int width;
  final int height;
  final ImageFormat format;
  final int sizeBytes;
  final DateTime? capturedAt;

  const ImageMetadata({
    required this.width,
    required this.height,
    required this.format,
    required this.sizeBytes,
    this.capturedAt,
  });

  @override
  List<Object?> get props => [width, height, format, sizeBytes, capturedAt];
}

// 食材認識結果
class FoodRecognitionResult extends Equatable {
  final List<DetectedFood> detectedFoods;
  final Duration processingTime;
  final ImageMetadata imageMetadata;
  final List<String>? warnings;

  const FoodRecognitionResult({
    required this.detectedFoods,
    required this.processingTime,
    required this.imageMetadata,
    this.warnings,
  });

  @override
  List<Object?> get props => [detectedFoods, processingTime, imageMetadata, warnings];
}

// マクロ栄養素
class Macronutrients extends Equatable {
  final double carbohydrates; // グラム
  final double protein; // グラム
  final double fat; // グラム
  final double fiber; // グラム

  const Macronutrients({
    required this.carbohydrates,
    required this.protein,
    required this.fat,
    required this.fiber,
  });

  @override
  List<Object> get props => [carbohydrates, protein, fat, fiber];
}

// 分量サイズ
class PortionSize extends Equatable {
  final String foodName;
  final double estimatedWeight;
  final WeightUnit unit;
  final double confidence;

  const PortionSize({
    required this.foodName,
    required this.estimatedWeight,
    required this.unit,
    required this.confidence,
  });

  @override
  List<Object> get props => [foodName, estimatedWeight, unit, confidence];
}

// 栄養分析メタデータ
class NutritionAnalysisMetadata extends Equatable {
  final String dataSource;
  final String analysisMethod;
  final double confidenceScore;
  final DateTime lastUpdated;

  const NutritionAnalysisMetadata({
    required this.dataSource,
    required this.analysisMethod,
    required this.confidenceScore,
    required this.lastUpdated,
  });

  @override
  List<Object> get props => [dataSource, analysisMethod, confidenceScore, lastUpdated];
}

// 栄養推定結果
class NutritionEstimate extends Equatable {
  final int totalCalories;
  final Macronutrients macronutrients;
  final Map<String, double>? micronutrients;
  final List<PortionSize> portionSizes;
  final NutritionAnalysisMetadata analysisMetadata;
  final List<String>? warnings;

  const NutritionEstimate({
    required this.totalCalories,
    required this.macronutrients,
    this.micronutrients,
    required this.portionSizes,
    required this.analysisMetadata,
    this.warnings,
  });

  @override
  List<Object?> get props => [
        totalCalories,
        macronutrients,
        micronutrients,
        portionSizes,
        analysisMetadata,
        warnings,
      ];
}

// カスタム分量
class CustomPortion extends Equatable {
  final String foodName;
  final double weight;
  final WeightUnit unit;

  const CustomPortion({
    required this.foodName,
    required this.weight,
    required this.unit,
  });

  @override
  List<Object> get props => [foodName, weight, unit];
}

// 食事記録
class MealRecord extends Equatable {
  final String id;
  final String userId;
  final DateTime timestamp;
  final MealType mealType;
  final List<DetectedFood> detectedFoods;
  final NutritionEstimate nutritionEstimate;
  final ImageMetadata imageMetadata;
  final String? userNotes;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MealRecord({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.mealType,
    required this.detectedFoods,
    required this.nutritionEstimate,
    required this.imageMetadata,
    this.userNotes,
    required this.isVerified,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        timestamp,
        mealType,
        detectedFoods,
        nutritionEstimate,
        imageMetadata,
        userNotes,
        isVerified,
        createdAt,
        updatedAt,
      ];
}

// 食事記録更新
class MealRecordUpdate extends Equatable {
  final String? userNotes;
  final bool? isVerified;
  final List<CustomPortion>? customPortions;
  final MealType? mealType;

  const MealRecordUpdate({
    this.userNotes,
    this.isVerified,
    this.customPortions,
    this.mealType,
  });

  @override
  List<Object?> get props => [userNotes, isVerified, customPortions, mealType];
}

// 栄養目標
class NutritionGoals extends Equatable {
  final int calorieTarget;
  final double proteinTarget;
  final double carbTarget;
  final double fatTarget;
  final double? fiberTarget;

  const NutritionGoals({
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbTarget,
    required this.fatTarget,
    this.fiberTarget,
  });

  @override
  List<Object?> get props => [calorieTarget, proteinTarget, carbTarget, fatTarget, fiberTarget];
}

// 日次栄養統計
class DailyNutritionStats extends Equatable {
  final DateTime date;
  final int totalCalories;
  final Macronutrients macronutrients;
  final Map<MealType, int> mealBreakdown;
  final NutritionGoals nutritionGoals;
  final double achievementPercentage;

  const DailyNutritionStats({
    required this.date,
    required this.totalCalories,
    required this.macronutrients,
    required this.mealBreakdown,
    required this.nutritionGoals,
    required this.achievementPercentage,
  });

  @override
  List<Object> get props => [
        date,
        totalCalories,
        macronutrients,
        mealBreakdown,
        nutritionGoals,
        achievementPercentage,
      ];
}

// 週次栄養トレンド
class WeeklyNutritionTrends extends Equatable {
  final DateTime weekStartDate;
  final List<DailyNutritionStats> dailyStats;
  final int averageCalories;
  final int calorieVariation;
  final Map<String, TrendDirection> macronutrientTrends;
  final double goalAchievementRate;
  final List<String> recommendations;

  const WeeklyNutritionTrends({
    required this.weekStartDate,
    required this.dailyStats,
    required this.averageCalories,
    required this.calorieVariation,
    required this.macronutrientTrends,
    required this.goalAchievementRate,
    required this.recommendations,
  });

  @override
  List<Object> get props => [
        weekStartDate,
        dailyStats,
        averageCalories,
        calorieVariation,
        macronutrientTrends,
        goalAchievementRate,
        recommendations,
      ];
}

// 食事分析サービス抽象クラス
abstract class MealAnalyzer {
  /// サポートされている画像フォーマット
  List<ImageFormat> get supportedImageFormats;

  /// 最大画像サイズ（バイト）
  int get maxImageSizeBytes;

  /// 画像から食材を認識する
  Future<FoodRecognitionResult> recognizeFood(
    File imageFile, {
    double minConfidence = 0.5,
  });

  /// 認識された食材から栄養素を推定する
  Future<NutritionEstimate> estimateNutrition(
    List<DetectedFood> detectedFoods, {
    List<CustomPortion>? customPortions,
  });

  /// 食事記録を保存する
  Future<MealRecord> saveMealRecord(MealRecord record);

  /// 食事記録を更新する
  Future<MealRecord> updateMealRecord(String recordId, MealRecordUpdate updates);

  /// 食事記録を削除する
  Future<bool> deleteMealRecord(String recordId);

  /// 食事履歴を取得する
  Future<List<MealRecord>> getMealHistory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    MealType? mealType,
  });

  /// 日次栄養統計を取得する
  Future<DailyNutritionStats> getDailyNutritionStats({
    required String userId,
    required DateTime date,
  });

  /// 週次栄養トレンドを取得する
  Future<WeeklyNutritionTrends> getWeeklyNutritionTrends({
    required String userId,
    required DateTime weekStartDate,
  });
}

// 食事分析サービス実装
class MealAnalyzerImpl implements MealAnalyzer {
  final PromptBuilder promptBuilder;
  final SecureApiClient apiClient;

  static const int _maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const List<ImageFormat> _supportedFormats = [
    ImageFormat.jpeg,
    ImageFormat.png,
    ImageFormat.webp,
  ];

  const MealAnalyzerImpl({
    required this.promptBuilder,
    required this.apiClient,
  });

  @override
  List<ImageFormat> get supportedImageFormats => _supportedFormats;

  @override
  int get maxImageSizeBytes => _maxImageSizeBytes;

  @override
  Future<FoodRecognitionResult> recognizeFood(
    File imageFile, {
    double minConfidence = 0.5,
  }) async {
    // 画像ファイルの検証
    _validateImageFile(imageFile);

    final startTime = DateTime.now();

    try {
      // 画像データを読み込み
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // API呼び出し用のデータを準備
      final requestData = {
        'image': base64Image,
        'min_confidence': minConfidence,
        'max_detections': 20,
        'include_bounding_boxes': true,
      };

      // Gemini APIで画像認識を実行
      final response = await apiClient.post(
        '/ai/food-recognition',
        apiProvider: ApiProvider.gemini,
        data: requestData,
      );

      final processingTime = DateTime.now().difference(startTime);

      // レスポンスを解析
      final responseData = response.data as Map<String, dynamic>;
      final detectedFoods = _parseDetectedFoods(responseData['foods'] as List);
      final imageMetadata = _extractImageMetadata(imageFile, imageBytes);

      return FoodRecognitionResult(
        detectedFoods: detectedFoods,
        processingTime: processingTime,
        imageMetadata: imageMetadata,
        warnings: responseData['warnings'] as List<String>?,
      );
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AIException(
        message: 'Food recognition failed: ${e.toString()}',
        data: {'image_path': imageFile.path},
      );
    }
  }

  @override
  Future<NutritionEstimate> estimateNutrition(
    List<DetectedFood> detectedFoods, {
    List<CustomPortion>? customPortions,
  }) async {
    if (detectedFoods.isEmpty) {
      throw ValidationException(message: 'No detected foods provided');
    }

    try {
      // API呼び出し用のデータを準備
      final requestData = {
        'detected_foods': detectedFoods.map((food) => {
              'name': food.name,
              'confidence': food.confidence,
              'category': food.category.name,
              'bounding_box': {
                'x': food.boundingBox.x,
                'y': food.boundingBox.y,
                'width': food.boundingBox.width,
                'height': food.boundingBox.height,
              },
            }).toList(),
        if (customPortions != null)
          'custom_portions': customPortions.map((portion) => {
                'food_name': portion.foodName,
                'weight': portion.weight,
                'unit': portion.unit.name,
              }).toList(),
      };

      // Gemini APIで栄養素推定を実行
      final response = await apiClient.post(
        '/ai/nutrition-estimation',
        apiProvider: ApiProvider.gemini,
        data: requestData,
      );

      // レスポンスを解析
      return _parseNutritionEstimate(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AIException(
        message: 'Nutrition estimation failed: ${e.toString()}',
        data: {'foods_count': detectedFoods.length},
      );
    }
  }

  @override
  Future<MealRecord> saveMealRecord(MealRecord record) async {
    try {
      // TODO: データベースに保存する実装
      // 現在はモックとして同じレコードを返す
      return record.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to save meal record: ${e.toString()}',
        data: {'record_id': record.id},
      );
    }
  }

  @override
  Future<MealRecord> updateMealRecord(String recordId, MealRecordUpdate updates) async {
    try {
      // TODO: データベースから既存レコードを取得し、更新する実装
      // 現在はモックとして新しいレコードを返す
      final now = DateTime.now();
      return MealRecord(
        id: recordId,
        userId: 'user-456', // モック値
        timestamp: now,
        mealType: updates.mealType ?? MealType.lunch,
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
            lastUpdated: now,
          ),
        ),
        imageMetadata: const ImageMetadata(
          width: 800,
          height: 600,
          format: ImageFormat.jpeg,
          sizeBytes: 2048,
        ),
        userNotes: updates.userNotes,
        isVerified: updates.isVerified ?? false,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to update meal record: ${e.toString()}',
        data: {'record_id': recordId},
      );
    }
  }

  @override
  Future<bool> deleteMealRecord(String recordId) async {
    try {
      // TODO: データベースからレコードを削除する実装
      // 現在はモックとして成功を返す
      return true;
    } catch (e) {
      throw CacheException(
        message: 'Failed to delete meal record: ${e.toString()}',
        data: {'record_id': recordId},
      );
    }
  }

  @override
  Future<List<MealRecord>> getMealHistory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    MealType? mealType,
  }) async {
    if (userId.isEmpty) {
      throw ValidationException(message: 'User ID cannot be empty');
    }

    try {
      // TODO: データベースから食事履歴を取得する実装
      // 現在はモックデータを返す
      final now = DateTime.now();
      return [
        MealRecord(
          id: 'meal-1',
          userId: userId,
          timestamp: now.subtract(const Duration(days: 1)),
          mealType: MealType.breakfast,
          detectedFoods: const [],
          nutritionEstimate: NutritionEstimate(
            totalCalories: 300,
            macronutrients: const Macronutrients(
              carbohydrates: 45.0,
              protein: 10.0,
              fat: 8.0,
              fiber: 5.0,
            ),
            portionSizes: const [],
            analysisMetadata: NutritionAnalysisMetadata(
              dataSource: 'USDA Food Database',
              analysisMethod: 'AI-powered estimation',
              confidenceScore: 0.8,
              lastUpdated: now,
            ),
          ),
          imageMetadata: const ImageMetadata(
            width: 800,
            height: 600,
            format: ImageFormat.jpeg,
            sizeBytes: 1024,
          ),
          isVerified: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    } catch (e) {
      throw CacheException(
        message: 'Failed to get meal history: ${e.toString()}',
        data: {'user_id': userId},
      );
    }
  }

  @override
  Future<DailyNutritionStats> getDailyNutritionStats({
    required String userId,
    required DateTime date,
  }) async {
    try {
      // TODO: データベースから日次統計を計算する実装
      // 現在はモックデータを返す
      return DailyNutritionStats(
        date: date,
        totalCalories: 1800,
        macronutrients: const Macronutrients(
          carbohydrates: 225.0,
          protein: 90.0,
          fat: 60.0,
          fiber: 25.0,
        ),
        mealBreakdown: const {
          MealType.breakfast: 400,
          MealType.lunch: 600,
          MealType.dinner: 650,
          MealType.snack: 150,
        },
        nutritionGoals: const NutritionGoals(
          calorieTarget: 2000,
          proteinTarget: 100.0,
          carbTarget: 250.0,
          fatTarget: 65.0,
        ),
        achievementPercentage: 0.9,
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to get daily nutrition stats: ${e.toString()}',
        data: {'user_id': userId, 'date': date.toIso8601String()},
      );
    }
  }

  @override
  Future<WeeklyNutritionTrends> getWeeklyNutritionTrends({
    required String userId,
    required DateTime weekStartDate,
  }) async {
    try {
      // TODO: データベースから週次トレンドを計算する実装
      // 現在はモックデータを返す
      return WeeklyNutritionTrends(
        weekStartDate: weekStartDate,
        dailyStats: const [],
        averageCalories: 1850,
        calorieVariation: 150,
        macronutrientTrends: const {
          'carbohydrates': TrendDirection.stable,
          'protein': TrendDirection.increasing,
          'fat': TrendDirection.decreasing,
        },
        goalAchievementRate: 0.85,
        recommendations: const [
          'Increase fiber intake',
          'Maintain current protein levels',
          'Consider more consistent meal timing',
        ],
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to get weekly nutrition trends: ${e.toString()}',
        data: {'user_id': userId, 'week_start': weekStartDate.toIso8601String()},
      );
    }
  }

  // プライベートメソッド
  void _validateImageFile(File imageFile) {
    // ファイルサイズチェック
    final fileSize = imageFile.lengthSync();
    if (fileSize > _maxImageSizeBytes) {
      throw ValidationException(
        message: 'Image file size exceeds maximum limit of ${_maxImageSizeBytes / (1024 * 1024)}MB',
        data: {'file_size': fileSize, 'max_size': _maxImageSizeBytes},
      );
    }

    // ファイル形式チェック
    final extension = imageFile.path.split('.').last.toLowerCase();
    final isSupported = _supportedFormats.any((format) {
      switch (format) {
        case ImageFormat.jpeg:
          return extension == 'jpg' || extension == 'jpeg';
        case ImageFormat.png:
          return extension == 'png';
        case ImageFormat.webp:
          return extension == 'webp';
        case ImageFormat.gif:
          return extension == 'gif';
      }
    });

    if (!isSupported) {
      throw ValidationException(
        message: 'Unsupported image format: $extension',
        data: {'file_extension': extension, 'supported_formats': _supportedFormats.map((f) => f.name).toList()},
      );
    }
  }

  List<DetectedFood> _parseDetectedFoods(List foodsData) {
    return foodsData.map((foodData) {
      final boundingBoxData = foodData['bounding_box'] as Map<String, dynamic>;
      return DetectedFood(
        name: foodData['name'] as String,
        confidence: (foodData['confidence'] as num).toDouble(),
        boundingBox: BoundingBox(
          x: (boundingBoxData['x'] as num).toDouble(),
          y: (boundingBoxData['y'] as num).toDouble(),
          width: (boundingBoxData['width'] as num).toDouble(),
          height: (boundingBoxData['height'] as num).toDouble(),
        ),
        category: FoodCategory.values.firstWhere(
          (cat) => cat.name == foodData['category'],
          orElse: () => FoodCategory.unknown,
        ),
      );
    }).toList();
  }

  ImageMetadata _extractImageMetadata(File imageFile, Uint8List imageBytes) {
    final extension = imageFile.path.split('.').last.toLowerCase();
    ImageFormat format;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        format = ImageFormat.jpeg;
        break;
      case 'png':
        format = ImageFormat.png;
        break;
      case 'webp':
        format = ImageFormat.webp;
        break;
      default:
        format = ImageFormat.jpeg;
    }

    return ImageMetadata(
      width: 800, // TODO: 実際の画像サイズを取得
      height: 600, // TODO: 実際の画像サイズを取得
      format: format,
      sizeBytes: imageBytes.length,
      capturedAt: DateTime.now(),
    );
  }

  NutritionEstimate _parseNutritionEstimate(Map<String, dynamic> response) {
    final macroData = response['macronutrients'] as Map<String, dynamic>;
    final portionData = response['portion_sizes'] as List? ?? [];
    final metadataData = response['analysis_metadata'] as Map<String, dynamic>? ?? {};

    return NutritionEstimate(
      totalCalories: response['total_calories'] as int,
      macronutrients: Macronutrients(
        carbohydrates: (macroData['carbohydrates'] as num).toDouble(),
        protein: (macroData['protein'] as num).toDouble(),
        fat: (macroData['fat'] as num).toDouble(),
        fiber: (macroData['fiber'] as num).toDouble(),
      ),
      micronutrients: response['micronutrients'] as Map<String, double>?,
      portionSizes: portionData.map((portionItem) {
        return PortionSize(
          foodName: portionItem['food_name'] as String,
          estimatedWeight: (portionItem['estimated_weight'] as num).toDouble(),
          unit: WeightUnit.values.firstWhere(
            (unit) => unit.name == portionItem['unit'],
            orElse: () => WeightUnit.grams,
          ),
          confidence: (portionItem['confidence'] as num).toDouble(),
        );
      }).toList(),
      analysisMetadata: NutritionAnalysisMetadata(
        dataSource: metadataData['data_source'] as String? ?? 'Unknown',
        analysisMethod: metadataData['analysis_method'] as String? ?? 'AI-powered estimation',
        confidenceScore: (metadataData['confidence_score'] as num?)?.toDouble() ?? 0.5,
        lastUpdated: DateTime.now(),
      ),
      warnings: response['warnings'] as List<String>?,
    );
  }
}

// MealRecord の copyWith メソッド拡張
extension MealRecordCopyWith on MealRecord {
  MealRecord copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    MealType? mealType,
    List<DetectedFood>? detectedFoods,
    NutritionEstimate? nutritionEstimate,
    ImageMetadata? imageMetadata,
    String? userNotes,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      mealType: mealType ?? this.mealType,
      detectedFoods: detectedFoods ?? this.detectedFoods,
      nutritionEstimate: nutritionEstimate ?? this.nutritionEstimate,
      imageMetadata: imageMetadata ?? this.imageMetadata,
      userNotes: userNotes ?? this.userNotes,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}