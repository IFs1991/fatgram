import 'package:fatgram/domain/models/ai/web_search_result.dart';

abstract class WebSearchRepository {
  /// 指定したクエリに基づいてウェブ検索を実行する
  Future<WebSearchResponse> searchWeb({
    required String query,
    int limit = 5,
    Map<String, dynamic>? filters,
  });

  /// 検索結果の詳細情報を取得する
  Future<WebSearchResult> getSearchResultDetails(String resultId);

  /// 検索履歴を取得する
  Future<List<String>> getSearchHistory({int limit = 10});

  /// 検索履歴を削除する
  Future<void> clearSearchHistory();

  /// 特定の検索クエリを検索履歴から削除する
  Future<void> removeFromSearchHistory(String query);

  /// 検索結果を保存する
  Future<void> saveSearchResult(String resultId);

  /// 保存した検索結果を取得する
  Future<List<WebSearchResult>> getSavedSearchResults();

  /// 保存した検索結果を削除する
  Future<void> removeSavedSearchResult(String resultId);
}