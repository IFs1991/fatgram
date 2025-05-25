import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fatgram/core/error/exceptions.dart';
import 'package:fatgram/data/datasources/ai/web_search_api_client.dart';
import 'package:fatgram/domain/models/ai/web_search_result.dart';
import 'package:fatgram/domain/repositories/ai/web_search_repository.dart';
import 'package:logger/logger.dart';

final webSearchRepositoryProvider = Provider<WebSearchRepository>((ref) {
  final webSearchClient = ref.watch(webSearchClientProvider);
  final webSearchService = WebSearchService(
    client: webSearchClient,
    logger: Logger(),
    apiKey: ref.read(envConfigProvider).webSearchApiKey,
    searchEngineId: ref.read(envConfigProvider).searchEngineId,
  );

  return WebSearchRepositoryImpl(
    webSearchService: webSearchService,
    logger: Logger(),
  );
});

// 環境設定用プロバイダー
final envConfigProvider = Provider((ref) => EnvConfigService());

class EnvConfigService {
  String get webSearchApiKey => 'YOUR_API_KEY'; // 実際には環境変数から取得
  String get searchEngineId => 'YOUR_SEARCH_ENGINE_ID'; // 実際には環境変数から取得
}

class WebSearchRepositoryImpl implements WebSearchRepository {
  final WebSearchService webSearchService;
  final Logger logger;
  final Uuid _uuid = const Uuid();

  // キャッシュ
  final Map<String, WebSearchResult> _resultCache = {};
  List<String> _searchHistory = [];
  List<String> _savedResultIds = [];

  WebSearchRepositoryImpl({
    required this.webSearchService,
    required this.logger,
  });

  @override
  Future<WebSearchResponse> searchWeb({
    required String query,
    int limit = 5,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // 検索履歴に追加
      if (!_searchHistory.contains(query)) {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 100) { // 履歴を100件に制限
          _searchHistory = _searchHistory.sublist(0, 100);
        }
      }

      // Web検索を実行
      final response = await webSearchService.search(
        query: query,
        limit: limit,
      );

      // 結果をキャッシュに格納
      for (final result in response.results) {
        _resultCache[result.id] = result;
      }

      return response;
    } catch (e) {
      logger.e('Error in searchWeb: $e');
      throw ServerException(
        message: 'Web search failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<WebSearchResult> getSearchResultDetails(String resultId) async {
    if (_resultCache.containsKey(resultId)) {
      return _resultCache[resultId]!;
    }

    throw NotFoundException(
      message: 'Search result not found: $resultId',
    );
  }

  @override
  Future<List<String>> getSearchHistory({int limit = 10}) async {
    return _searchHistory.take(limit).toList();
  }

  @override
  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
  }

  @override
  Future<void> removeFromSearchHistory(String query) async {
    _searchHistory.remove(query);
  }

  @override
  Future<void> saveSearchResult(String resultId) async {
    if (!_resultCache.containsKey(resultId)) {
      throw NotFoundException(
        message: 'Search result not found: $resultId',
      );
    }

    if (!_savedResultIds.contains(resultId)) {
      _savedResultIds.add(resultId);
    }
  }

  @override
  Future<List<WebSearchResult>> getSavedSearchResults() async {
    return _savedResultIds
        .where(_resultCache.containsKey)
        .map((id) => _resultCache[id]!)
        .toList();
  }

  @override
  Future<void> removeSavedSearchResult(String resultId) async {
    _savedResultIds.remove(resultId);
  }
}