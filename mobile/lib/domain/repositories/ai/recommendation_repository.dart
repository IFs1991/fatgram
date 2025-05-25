import 'package:fatgram/domain/models/ai/user_recommendation.dart';

abstract class RecommendationRepository {
  /// ユーザーのアクティビティデータに基づいた推奨を生成する
  Future<List<UserRecommendation>> generateRecommendations({
    required RecommendationType type,
    int limit = 5,
    Map<String, dynamic>? filters,
  });

  /// 特定の推奨の詳細情報を取得する
  Future<UserRecommendation> getRecommendationDetails(String recommendationId);

  /// ユーザーの最近の推奨を取得する
  Future<List<UserRecommendation>> getRecentRecommendations({
    int limit = 10,
    RecommendationType? type,
  });

  /// 推奨に対するユーザーのフィードバックを保存する
  Future<void> saveRecommendationFeedback({
    required String recommendationId,
    required bool isHelpful,
    String? feedbackText,
  });

  /// 推奨を既読としてマークする
  Future<void> markRecommendationAsSeen(String recommendationId);

  /// 推奨を削除する
  Future<void> deleteRecommendation(String recommendationId);
}