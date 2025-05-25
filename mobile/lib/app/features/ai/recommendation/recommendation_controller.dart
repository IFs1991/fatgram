import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fatgram/domain/models/ai/user_recommendation.dart';
import 'package:fatgram/domain/repositories/ai/recommendation_repository.dart';
import 'package:fatgram/data/repositories/ai/recommendation_repository_impl.dart';

// レコメンデーションコントローラーの状態
class RecommendationState {
  final bool isLoading;
  final String? error;
  final List<UserRecommendation> recommendations;

  RecommendationState({
    this.isLoading = false,
    this.error,
    this.recommendations = const [],
  });

  RecommendationState copyWith({
    bool? isLoading,
    String? error,
    List<UserRecommendation>? recommendations,
  }) {
    return RecommendationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      recommendations: recommendations ?? this.recommendations,
    );
  }
}

final recommendationControllerProvider = StateNotifierProvider<RecommendationController, RecommendationState>((ref) {
  final repository = ref.watch(recommendationRepositoryProvider);
  return RecommendationController(repository);
});

class RecommendationController extends StateNotifier<RecommendationState> {
  final RecommendationRepository _repository;

  RecommendationController(this._repository) : super(RecommendationState());

  Future<void> generateRecommendations({
    required RecommendationType type,
    int limit = 5,
    Map<String, dynamic>? filters,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 同じ種類の推奨が既に存在するかチェック
      final existingRecommendations = state.recommendations
          .where((rec) => rec.type == type)
          .toList();

      // 既存の推奨がない場合のみ新しく生成
      if (existingRecommendations.isEmpty) {
        final recommendations = await _repository.generateRecommendations(
          type: type,
          limit: limit,
          filters: filters,
        );

        // 新しい推奨を既存の推奨と結合
        final updatedRecommendations = [
          ...state.recommendations.where((rec) => rec.type != type),
          ...recommendations,
        ];

        state = state.copyWith(
          isLoading: false,
          recommendations: updatedRecommendations,
        );
      } else {
        // 既に推奨がある場合は、ロード状態のみを更新
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<UserRecommendation> getRecommendationDetails(String recommendationId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final recommendation = await _repository.getRecommendationDetails(recommendationId);
      state = state.copyWith(isLoading: false);
      return recommendation;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> saveRecommendationFeedback({
    required String recommendationId,
    required bool isHelpful,
    String? feedbackText,
  }) async {
    try {
      await _repository.saveRecommendationFeedback(
        recommendationId: recommendationId,
        isHelpful: isHelpful,
        feedbackText: feedbackText,
      );

      // 推奨を既読としてマーク
      await _repository.markRecommendationAsSeen(recommendationId);
    } catch (e) {
      // フィードバックの保存エラーはUI側に通知しない（バックグラウンド処理）
      // ロギングのみ行う
    }
  }

  Future<void> deleteRecommendation(String recommendationId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repository.deleteRecommendation(recommendationId);

      // 推奨リストを更新
      final updatedRecommendations = state.recommendations
          .where((rec) => rec.id != recommendationId)
          .toList();

      state = state.copyWith(
        isLoading: false,
        recommendations: updatedRecommendations,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
}