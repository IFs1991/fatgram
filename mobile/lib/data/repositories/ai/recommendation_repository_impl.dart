import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fatgram/core/error/exceptions.dart';
import 'package:fatgram/data/datasources/ai/gemini_api_client.dart';
import 'package:fatgram/domain/models/ai/user_recommendation.dart';
import 'package:fatgram/domain/repositories/ai/recommendation_repository.dart';
import 'package:logger/logger.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;

final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  final geminiClient = ref.watch(geminiClientProvider);
  return RecommendationRepositoryImpl(
    apiClient: geminiClient,
    logger: Logger(),
  );
});

class RecommendationRepositoryImpl implements RecommendationRepository {
  final GeminiApiClient apiClient;
  final Logger logger;
  final Uuid _uuid = const Uuid();

  // メモリ内キャッシュ
  final Map<String, UserRecommendation> _recommendationCache = {};
  final List<UserRecommendation> _recentRecommendations = [];

  RecommendationRepositoryImpl({
    required this.apiClient,
    required this.logger,
  });

  @override
  Future<List<UserRecommendation>> generateRecommendations({
    required RecommendationType type,
    int limit = 5,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // ユーザープロファイルや活動データなどのコンテキスト情報を準備
      // 実際のアプリでは、ユーザーのアクティビティデータなどを取得して利用
      final contextData = {
        'recommendationType': type.toString(),
        'limit': limit.toString(),
        ...?filters?.map((key, value) => MapEntry(key.toString(), value.toString())),
      };

      // 推奨タイプに応じたプロンプトを作成
      String prompt;
      switch (type) {
        case RecommendationType.workout:
          prompt = 'Generate $limit personalized workout recommendations based on user data.';
          break;
        case RecommendationType.nutrition:
          prompt = 'Generate $limit personalized nutrition recommendations based on user data.';
          break;
        case RecommendationType.lifestyle:
          prompt = 'Generate $limit personalized lifestyle recommendations based on user data.';
          break;
        case RecommendationType.goal:
          prompt = 'Generate $limit personalized goal recommendations based on user data.';
          break;
      }

      // AI経由で推奨を生成
      final response = await apiClient.generateChatResponse(
        history: [
          genai.Content(
            role: 'user',
            parts: [genai.TextPart(text: prompt)],
          ),
        ],
        systemInstructions: {
          'role': 'You are a fitness recommendations generator that creates personalized suggestions.',
          'format': 'Return recommendations as a JSON array with objects having title, description, and confidence fields.',
          'context': contextData.toString(),
        },
      );

      // レスポンスをパースして推奨リストを作成（実際のAPIでは適切な処理が必要）
      // 簡略化のため、ダミーデータを生成
      final recommendations = List.generate(
        limit,
        (index) => UserRecommendation(
          id: _uuid.v4(),
          title: 'Sample ${type.toString()} Recommendation ${index + 1}',
          description: 'This is a personalized recommendation based on your activity data.',
          type: type,
          createdAt: DateTime.now(),
          confidenceScore: 0.7 + (index * 0.05),
          tags: ['personalized', type.toString().split('.').last],
          actions: [
            RecommendationAction(
              id: _uuid.v4(),
              title: 'View Details',
              actionType: 'open_details',
            ),
            RecommendationAction(
              id: _uuid.v4(),
              title: 'Save for Later',
              actionType: 'save',
            ),
          ],
        ),
      );

      // 推奨をキャッシュに追加
      for (final recommendation in recommendations) {
        _recommendationCache[recommendation.id] = recommendation;

        // 最近の推奨リストに追加（先頭に挿入）
        _recentRecommendations.insert(0, recommendation);

        // 最近の推奨を最大50件に制限
        if (_recentRecommendations.length > 50) {
          _recentRecommendations.removeRange(50, _recentRecommendations.length);
        }
      }

      return recommendations;
    } catch (e) {
      logger.e('Error generating recommendations: $e');
      throw AIException(
        message: 'Failed to generate recommendations: ${e.toString()}',
      );
    }
  }

  @override
  Future<UserRecommendation> getRecommendationDetails(String recommendationId) async {
    if (_recommendationCache.containsKey(recommendationId)) {
      return _recommendationCache[recommendationId]!;
    }

    throw NotFoundException(
      message: 'Recommendation not found: $recommendationId',
    );
  }

  @override
  Future<List<UserRecommendation>> getRecentRecommendations({
    int limit = 10,
    RecommendationType? type,
  }) async {
    if (type != null) {
      return _recentRecommendations
          .where((rec) => rec.type == type)
          .take(limit)
          .toList();
    }

    return _recentRecommendations.take(limit).toList();
  }

  @override
  Future<void> saveRecommendationFeedback({
    required String recommendationId,
    required bool isHelpful,
    String? feedbackText,
  }) async {
    if (!_recommendationCache.containsKey(recommendationId)) {
      throw NotFoundException(
        message: 'Recommendation not found: $recommendationId',
      );
    }

    // 実際のアプリでは、フィードバックをサーバーに送信して保存する
    logger.i('Saved feedback for recommendation $recommendationId: $isHelpful, $feedbackText');
  }

  @override
  Future<void> markRecommendationAsSeen(String recommendationId) async {
    if (!_recommendationCache.containsKey(recommendationId)) {
      throw NotFoundException(
        message: 'Recommendation not found: $recommendationId',
      );
    }

    // 実際のアプリでは、既読ステータスをサーバーに送信して保存する
    logger.i('Marked recommendation $recommendationId as seen');
  }

  @override
  Future<void> deleteRecommendation(String recommendationId) async {
    if (!_recommendationCache.containsKey(recommendationId)) {
      throw NotFoundException(
        message: 'Recommendation not found: $recommendationId',
      );
    }

    // キャッシュから削除
    final recommendation = _recommendationCache.remove(recommendationId);

    // 最近の推奨リストからも削除
    _recentRecommendations.remove(recommendation);
  }
}