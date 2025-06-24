import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:fatgram/data/datasources/ai/secure_api_client.dart';
import 'package:fatgram/core/security/api_key_manager.dart';
import 'package:fatgram/core/error/exceptions.dart';
// import 'package:fatgram/core/error/failures.dart'; // 未使用のため削除

// Mock classes
class MockDio extends Mock implements Dio {}
class MockApiKeyManager extends Mock implements ApiKeyManager {}
class MockResponse extends Mock implements Response<dynamic> {}
class MockRequestOptions extends Mock implements RequestOptions {}
class MockInterceptor extends Mock implements Interceptor {}
class MockInterceptors extends Mock implements Interceptors {}
class MockBaseOptions extends Mock implements BaseOptions {}

// Fake classes for registerFallbackValue
class FakeInterceptor extends Fake implements Interceptor {}

void main() {
  setUpAll(() {
    // mocktailのfallback値を登録
    registerFallbackValue(FakeInterceptor());
  });

  late SecureApiClient secureApiClient;
  late MockDio mockDio;
  late MockApiKeyManager mockApiKeyManager;
  late MockResponse mockResponse;
  late MockInterceptors mockInterceptors;
  late MockBaseOptions mockBaseOptions;

  setUp(() {
    mockDio = MockDio();
    mockApiKeyManager = MockApiKeyManager();
    mockResponse = MockResponse();
    mockInterceptors = MockInterceptors();
    mockBaseOptions = MockBaseOptions();

    // MockDioのセットアップ
    when(() => mockDio.interceptors).thenReturn(mockInterceptors);
    when(() => mockInterceptors.add(any())).thenReturn(null);
    when(() => mockDio.options).thenReturn(mockBaseOptions);
    when(() => mockBaseOptions.headers).thenReturn(<String, dynamic>{});

    secureApiClient = SecureApiClient(
      dio: mockDio,
      apiKeyManager: mockApiKeyManager,
    );
  });

  // ヘルパー関数: APIキー設定のモックをセットアップ
  void setupApiKeyMocks(ApiProvider provider, String apiKey) {
    when(() => mockApiKeyManager.getApiKey(provider))
        .thenAnswer((_) async => apiKey);
    when(() => mockApiKeyManager.storeApiKey(provider, apiKey))
        .thenAnswer((_) async => 'encrypted-$apiKey');
  }

  group('SecureApiClient - 初期化とセットアップ', () {
    test('正常に初期化される', () {
      // Arrange & Act & Assert
      expect(secureApiClient, isNotNull);
      expect(secureApiClient.isInitialized, isFalse);
    });

    test('APIキーマネージャーの初期化が成功する', () async {
      // Arrange
      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);

      // Act
      await secureApiClient.initialize();

      // Assert
      expect(secureApiClient.isInitialized, isTrue);
      verify(() => mockApiKeyManager.initialize()).called(1);
    });

    test('APIキーマネージャーの初期化に失敗した場合例外を投げる', () async {
      // Arrange
      when(() => mockApiKeyManager.initialize())
          .thenThrow(const CacheException(message: 'Initialization failed'));

      // Act & Assert
      expect(
        () => secureApiClient.initialize(),
        throwsA(isA<CacheException>()),
      );
    });
  });

  group('SecureApiClient - APIキー暗号化管理', () {
    test('APIキーの暗号化と復号化が正常に動作する', () async {
      // Arrange
      const apiKey = 'test-api-key-12345';
      const encryptedKey = 'encrypted-test-key';
      const apiProvider = ApiProvider.openai;

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.storeApiKey(apiProvider, apiKey))
          .thenAnswer((_) async => encryptedKey);
      when(() => mockApiKeyManager.getApiKey(apiProvider))
          .thenAnswer((_) async => apiKey);

      await secureApiClient.initialize();

      // Act
      await secureApiClient.setApiKey(apiProvider, apiKey);
      final retrievedKey = await secureApiClient.getApiKey(apiProvider);

      // Assert
      expect(retrievedKey, equals(apiKey));
      verify(() => mockApiKeyManager.storeApiKey(apiProvider, apiKey)).called(1);
      verify(() => mockApiKeyManager.getApiKey(apiProvider)).called(1);
    });

    test('無効なAPIキーを設定した場合例外を投げる', () async {
      // Arrange
      const invalidApiKey = '';
      const apiProvider = ApiProvider.openai;

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);

      await secureApiClient.initialize();

      // Act & Assert
      expect(
        () => secureApiClient.setApiKey(apiProvider, invalidApiKey),
        throwsA(isA<ValidationException>()),
      );
    });

    test('存在しないAPIキーを取得しようとした場合例外を投げる', () async {
      // Arrange
      const apiProvider = ApiProvider.gemini;

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.getApiKey(apiProvider))
          .thenThrow(const CacheException(message: 'API key not found'));

      await secureApiClient.initialize();

      // Act & Assert
      expect(
        () => secureApiClient.getApiKey(apiProvider),
        throwsA(isA<CacheException>()),
      );
    });
  });

  group('SecureApiClient - HTTP リクエスト処理', () {
    test('GET リクエストが正常に実行される', () async {
      // Arrange
      const url = '/test-endpoint';
      const responseData = {'message': 'success'};
      const apiProvider = ApiProvider.openai;
      const apiKey = 'test-api-key';

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.getApiKey(apiProvider))
          .thenAnswer((_) async => apiKey);
      when(() => mockApiKeyManager.storeApiKey(apiProvider, apiKey))
          .thenAnswer((_) async => 'encrypted-key');
      when(() => mockResponse.data).thenReturn(responseData);
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockDio.get(
            url,
            options: any(named: 'options'),
          )).thenAnswer((_) async => mockResponse);

      await secureApiClient.initialize();
      await secureApiClient.setApiKey(apiProvider, apiKey);

      // Act
      final result = await secureApiClient.get(
        url,
        apiProvider: apiProvider,
      );

      // Assert
      expect(result.data, equals(responseData));
      expect(result.statusCode, equals(200));
      verify(() => mockDio.get(url, options: any(named: 'options'))).called(1);
    });

    test('POST リクエストが正常に実行される', () async {
      // Arrange
      const url = '/test-endpoint';
      const requestData = {'input': 'test'};
      const responseData = {'output': 'result'};
      const apiProvider = ApiProvider.gemini;
      const apiKey = 'test-gemini-key';

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.getApiKey(apiProvider))
          .thenAnswer((_) async => apiKey);
      when(() => mockApiKeyManager.storeApiKey(apiProvider, apiKey))
          .thenAnswer((_) async => 'encrypted-key');
      when(() => mockResponse.data).thenReturn(responseData);
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockDio.post(
            url,
            data: requestData,
            options: any(named: 'options'),
          )).thenAnswer((_) async => mockResponse);

      await secureApiClient.initialize();
      await secureApiClient.setApiKey(apiProvider, apiKey);

      // Act
      final result = await secureApiClient.post(
        url,
        data: requestData,
        apiProvider: apiProvider,
      );

      // Assert
      expect(result.data, equals(responseData));
      expect(result.statusCode, equals(200));
      verify(() => mockDio.post(
            url,
            data: requestData,
            options: any(named: 'options'),
          )).called(1);
    });

    test('HTTPエラーレスポンスを適切に処理する', () async {
      // Arrange
      const url = '/error-endpoint';
      const apiProvider = ApiProvider.openai;
      const apiKey = 'test-api-key';
      final requestOptions = RequestOptions(path: '/error-endpoint');
      final dioError = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
          data: {'error': 'Unauthorized'},
        ),
        type: DioExceptionType.badResponse,
      );

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.getApiKey(apiProvider))
          .thenAnswer((_) async => apiKey);
      when(() => mockApiKeyManager.storeApiKey(apiProvider, apiKey))
          .thenAnswer((_) async => 'encrypted-key');
      when(() => mockDio.get(
            url,
            options: any(named: 'options'),
          )).thenThrow(dioError);

      await secureApiClient.initialize();
      await secureApiClient.setApiKey(apiProvider, apiKey);

      // Act & Assert
      expect(
        () => secureApiClient.get(url, apiProvider: apiProvider),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('SecureApiClient - レート制限機能', () {
    test('レート制限が正常に動作する', () async {
      // Arrange
      const url = '/rate-limited-endpoint';
      const apiProvider = ApiProvider.openai;
      const apiKey = 'test-api-key';
      const rateLimitPerMinute = 2;

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.getApiKey(apiProvider))
          .thenAnswer((_) async => apiKey);
      when(() => mockResponse.data).thenReturn({'success': true});
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockDio.get(
            url,
            options: any(named: 'options'),
          )).thenAnswer((_) async => mockResponse);

      await secureApiClient.initialize();
      await secureApiClient.setApiKey(apiProvider, apiKey);
      secureApiClient.setRateLimit(apiProvider, rateLimitPerMinute);

      // Act - 制限内でのリクエスト
      await secureApiClient.get(url, apiProvider: apiProvider);
      await secureApiClient.get(url, apiProvider: apiProvider);

      // Assert - 3回目のリクエストはレート制限にかかる
      expect(
        () => secureApiClient.get(url, apiProvider: apiProvider),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('レート制限がリセットされる', () async {
      // Arrange
      const url = '/rate-limited-endpoint';
      const apiProvider = ApiProvider.openai;
      const apiKey = 'test-api-key';
      const rateLimitPerMinute = 1;

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.getApiKey(apiProvider))
          .thenAnswer((_) async => apiKey);
      when(() => mockResponse.data).thenReturn({'success': true});
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockDio.get(
            url,
            options: any(named: 'options'),
          )).thenAnswer((_) async => mockResponse);

      await secureApiClient.initialize();
      await secureApiClient.setApiKey(apiProvider, apiKey);
      secureApiClient.setRateLimit(apiProvider, rateLimitPerMinute);

      // Act
      await secureApiClient.get(url, apiProvider: apiProvider);

      // レート制限をリセット
      secureApiClient.resetRateLimit(apiProvider);

      // Assert - リセット後は再度リクエストできる
      await expectLater(
        secureApiClient.get(url, apiProvider: apiProvider),
        completes,
      );
    });

    test('異なるAPIプロバイダーのレート制限は独立している', () async {
      // Arrange
      const url = '/test-endpoint';
      const apiKeyOpenAI = 'openai-key';
      const apiKeyGemini = 'gemini-key';
      const rateLimitPerMinute = 1;

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.getApiKey(ApiProvider.openai))
          .thenAnswer((_) async => apiKeyOpenAI);
      when(() => mockApiKeyManager.getApiKey(ApiProvider.gemini))
          .thenAnswer((_) async => apiKeyGemini);
      when(() => mockResponse.data).thenReturn({'success': true});
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockDio.get(
            url,
            options: any(named: 'options'),
          )).thenAnswer((_) async => mockResponse);

      await secureApiClient.initialize();
      await secureApiClient.setApiKey(ApiProvider.openai, apiKeyOpenAI);
      await secureApiClient.setApiKey(ApiProvider.gemini, apiKeyGemini);
      secureApiClient.setRateLimit(ApiProvider.openai, rateLimitPerMinute);
      secureApiClient.setRateLimit(ApiProvider.gemini, rateLimitPerMinute);

      // Act & Assert
      await secureApiClient.get(url, apiProvider: ApiProvider.openai);
      await secureApiClient.get(url, apiProvider: ApiProvider.gemini);

      // OpenAIは制限に達している
      expect(
        () => secureApiClient.get(url, apiProvider: ApiProvider.openai),
        throwsA(isA<RateLimitException>()),
      );

      // Geminiは制限に達している
      expect(
        () => secureApiClient.get(url, apiProvider: ApiProvider.gemini),
        throwsA(isA<RateLimitException>()),
      );
    });
  });

  group('SecureApiClient - トークンリフレッシュ機能', () {
    test('APIキーの自動リフレッシュが動作する', () async {
      // Arrange
      const url = '/test-endpoint';
      const apiProvider = ApiProvider.openai;
      const oldApiKey = 'old-api-key';
      const newApiKey = 'new-api-key';

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.getApiKey(apiProvider))
          .thenAnswer((_) async => oldApiKey);
      when(() => mockApiKeyManager.refreshApiKey(apiProvider))
          .thenAnswer((_) async => newApiKey);
      when(() => mockResponse.data).thenReturn({'success': true});
      when(() => mockResponse.statusCode).thenReturn(200);

      // 最初のリクエストは401エラー、2回目は成功
      var callCount = 0;
      when(() => mockDio.get(
            url,
            options: any(named: 'options'),
          )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw DioException(
            requestOptions: MockRequestOptions(),
            response: Response(
              requestOptions: MockRequestOptions(),
              statusCode: 401,
              data: {'error': 'Invalid API key'},
            ),
            type: DioExceptionType.badResponse,
          );
        }
        return mockResponse;
      });

      await secureApiClient.initialize();
      await secureApiClient.setApiKey(apiProvider, oldApiKey);

      // Act
      final result = await secureApiClient.get(
        url,
        apiProvider: apiProvider,
        enableAutoRefresh: true,
      );

      // Assert
      expect(result.data, equals({'success': true}));
      verify(() => mockApiKeyManager.refreshApiKey(apiProvider)).called(1);
    });

    test('手動でのAPIキーリフレッシュが動作する', () async {
      // Arrange
      const apiProvider = ApiProvider.gemini;
      const newApiKey = 'refreshed-gemini-key';

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.refreshApiKey(apiProvider))
          .thenAnswer((_) async => newApiKey);

      await secureApiClient.initialize();

      // Act
      final result = await secureApiClient.refreshApiKey(apiProvider);

      // Assert
      expect(result, equals(newApiKey));
      verify(() => mockApiKeyManager.refreshApiKey(apiProvider)).called(1);
    });

    test('リフレッシュに失敗した場合例外を投げる', () async {
      // Arrange
      const apiProvider = ApiProvider.openai;

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.refreshApiKey(apiProvider))
          .thenThrow(const NetworkException(message: 'Refresh failed'));

      await secureApiClient.initialize();

      // Act & Assert
      expect(
        () => secureApiClient.refreshApiKey(apiProvider),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('SecureApiClient - セキュリティとログ機能', () {
    test('APIリクエストが適切にログ記録される', () async {
      // Arrange
      const url = '/logged-endpoint';
      const apiProvider = ApiProvider.openai;
      const apiKey = 'test-api-key';

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.getApiKey(apiProvider))
          .thenAnswer((_) async => apiKey);
      when(() => mockResponse.data).thenReturn({'logged': true});
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockDio.get(
            url,
            options: any(named: 'options'),
          )).thenAnswer((_) async => mockResponse);

      await secureApiClient.initialize();
      await secureApiClient.setApiKey(apiProvider, apiKey);

      // Act
      await secureApiClient.get(url, apiProvider: apiProvider);

      // Assert
      final logs = secureApiClient.getRequestLogs(apiProvider);
      expect(logs, isNotEmpty);
      expect(logs.first.url, contains(url));
      expect(logs.first.method, equals('GET'));
      expect(logs.first.statusCode, equals(200));
    });

    test('セキュリティ情報が適切にマスクされる', () async {
      // Arrange
      const url = '/secure-endpoint';
      const apiProvider = ApiProvider.openai;
      const apiKey = 'secret-api-key-12345';

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.getApiKey(apiProvider))
          .thenAnswer((_) async => apiKey);
      when(() => mockResponse.data).thenReturn({'secure': true});
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockDio.get(
            url,
            options: any(named: 'options'),
          )).thenAnswer((_) async => mockResponse);

      await secureApiClient.initialize();
      await secureApiClient.setApiKey(apiProvider, apiKey);

      // Act
      await secureApiClient.get(url, apiProvider: apiProvider);

      // Assert
      final logs = secureApiClient.getRequestLogs(apiProvider);
      final logString = logs.first.toString();
      expect(logString, isNot(contains(apiKey)));
      expect(logString, contains('***'));
    });

    test('最大ログ保持数が制限される', () async {
      // Arrange
      const url = '/test-endpoint';
      const apiProvider = ApiProvider.openai;
      const apiKey = 'test-api-key';
      const maxLogs = 100;

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.getApiKey(apiProvider))
          .thenAnswer((_) async => apiKey);
      when(() => mockResponse.data).thenReturn({'test': true});
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockDio.get(
            url,
            options: any(named: 'options'),
          )).thenAnswer((_) async => mockResponse);

      await secureApiClient.initialize();
      await secureApiClient.setApiKey(apiProvider, apiKey);

      // Act - maxLogs を超えるリクエストを実行
      for (int i = 0; i < maxLogs + 10; i++) {
        await secureApiClient.get('$url/$i', apiProvider: apiProvider);
      }

      // Assert
      final logs = secureApiClient.getRequestLogs(apiProvider);
      expect(logs.length, equals(maxLogs));
    });
  });

  group('SecureApiClient - エラーハンドリング', () {
    test('初期化前のリクエストでエラーを投げる', () async {
      // Arrange
      const url = '/test-endpoint';
      const apiProvider = ApiProvider.openai;

      // Act & Assert
      expect(
        () => secureApiClient.get(url, apiProvider: apiProvider),
        throwsA(isA<StateError>()),
      );
    });

    test('ネットワークエラーを適切に処理する', () async {
      // Arrange
      const url = '/network-error-endpoint';
      const apiProvider = ApiProvider.openai;
      const apiKey = 'test-api-key';

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.getApiKey(apiProvider))
          .thenAnswer((_) async => apiKey);
      when(() => mockDio.get(
            url,
            options: any(named: 'options'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: url),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      await secureApiClient.initialize();
      await secureApiClient.setApiKey(apiProvider, apiKey);

      // Act & Assert
      expect(
        () => secureApiClient.get(url, apiProvider: apiProvider),
        throwsA(isA<NetworkException>()),
      );
    });

    test('不正なレスポンスデータを処理する', () async {
      // Arrange
      const url = '/invalid-response-endpoint';
      const apiProvider = ApiProvider.openai;
      const apiKey = 'test-api-key';

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.getApiKey(apiProvider))
          .thenAnswer((_) async => apiKey);
      when(() => mockResponse.data).thenReturn(null);
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockDio.get(
            url,
            options: any(named: 'options'),
          )).thenAnswer((_) async => mockResponse);

      await secureApiClient.initialize();
      await secureApiClient.setApiKey(apiProvider, apiKey);

      // Act & Assert
      expect(
        () => secureApiClient.get(url, apiProvider: apiProvider),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('SecureApiClient - 統合テスト', () {
    test('完全なワークフローが正常に動作する', () async {
      // Arrange
      const url = '/integration-test';
      const apiProvider = ApiProvider.openai;
      const apiKey = 'integration-test-key';
      const responseData = {'integration': 'success'};

      when(() => mockApiKeyManager.initialize())
          .thenAnswer((_) async => {});
      when(() => mockApiKeyManager.isInitialized)
          .thenReturn(true);
      when(() => mockApiKeyManager.storeApiKey(apiProvider, apiKey))
          .thenAnswer((_) async => 'encrypted-key');
      when(() => mockApiKeyManager.getApiKey(apiProvider))
          .thenAnswer((_) async => apiKey);
      when(() => mockResponse.data).thenReturn(responseData);
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockDio.get(
            url,
            options: any(named: 'options'),
          )).thenAnswer((_) async => mockResponse);

      // Act
      await secureApiClient.initialize();
      await secureApiClient.setApiKey(apiProvider, apiKey);
      secureApiClient.setRateLimit(apiProvider, 10);

      final result = await secureApiClient.get(url, apiProvider: apiProvider);

      // Assert
      expect(secureApiClient.isInitialized, isTrue);
      expect(result.data, equals(responseData));
      expect(result.statusCode, equals(200));

      final logs = secureApiClient.getRequestLogs(apiProvider);
      expect(logs, hasLength(1));
      expect(logs.first.statusCode, equals(200));
    });
  });
}