import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:fatgram/core/config/env_config.dart';
import 'package:fatgram/domain/models/ai/web_search_result.dart';
import 'package:logger/logger.dart';

part 'web_search_api_client.g.dart';

final webSearchClientProvider = Provider<WebSearchApiClient>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://www.googleapis.com/customsearch/v1',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  return WebSearchApiClient(dio, baseUrl: 'https://www.googleapis.com/customsearch/v1');
});

@RestApi()
abstract class WebSearchApiClient {
  factory WebSearchApiClient(Dio dio, {String baseUrl}) = _WebSearchApiClient;

  @GET('')
  Future<Map<String, dynamic>> search(
    @Query('key') String apiKey,
    @Query('cx') String searchEngineId,
    @Query('q') String query,
    @Query('num') int limit,
  );
}

class WebSearchService {
  final WebSearchApiClient client;
  final Logger logger;
  final String apiKey;
  final String searchEngineId;

  WebSearchService({
    required this.client,
    required this.logger,
    required this.apiKey,
    required this.searchEngineId,
  });

  Future<WebSearchResponse> search({
    required String query,
    int limit = 5,
  }) async {
    try {
      final response = await client.search(
        apiKey,
        searchEngineId,
        query,
        limit,
      );

      final items = response['items'] as List<dynamic>;
      final results = items.map((item) {
        return WebSearchResult(
          id: item['cacheId'] ?? item['link'],
          title: item['title'] ?? '',
          snippet: item['snippet'] ?? '',
          url: item['link'] ?? '',
          sourceDisplayName: item['displayLink'] ?? '',
          imageUrl: item['pagemap']?['cse_image']?[0]?['src'],
        );
      }).toList();

      return WebSearchResponse(
        query: query,
        results: results,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      logger.e('Error during web search: $e');
      rethrow;
    }
  }
}