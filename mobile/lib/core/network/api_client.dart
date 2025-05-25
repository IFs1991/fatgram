import 'dart:convert';
import 'package:http/http.dart' as http;

import '../error/exceptions.dart';

/// APIクライアントクラス
///
/// バックエンドAPIとの通信を担当します
class ApiClient {
  final http.Client httpClient;
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  ApiClient({
    required this.httpClient,
    required this.baseUrl,
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  });

  /// 認証トークンの設定
  Map<String, String> _getHeaders(String? token) {
    final headers = Map<String, String>.from(defaultHeaders);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// GETリクエスト
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await httpClient.get(
        uri,
        headers: _getHeaders(token),
      );

      return _processResponse(response);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  /// POSTリクエスト
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await httpClient.post(
        uri,
        headers: _getHeaders(token),
        body: body != null ? json.encode(body) : null,
      );

      return _processResponse(response);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  /// PUTリクエスト
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await httpClient.put(
        uri,
        headers: _getHeaders(token),
        body: body != null ? json.encode(body) : null,
      );

      return _processResponse(response);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  /// DELETEリクエスト
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await httpClient.delete(
        uri,
        headers: _getHeaders(token),
        body: body != null ? json.encode(body) : null,
      );

      return _processResponse(response);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  /// レスポンス処理
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      final error = errorBody['error'] ?? {'message': 'Unknown error'};
      final errorMessage = error['message'] ?? 'Unknown error';

      switch (response.statusCode) {
        case 400:
          throw BadRequestException(message: errorMessage);
        case 401:
          throw UnauthorizedException(message: errorMessage);
        case 402:
          throw PaymentRequiredException(message: errorMessage);
        case 403:
          throw ForbiddenException(message: errorMessage);
        case 404:
          throw NotFoundException(message: errorMessage);
        case 409:
          throw ConflictException(message: errorMessage);
        case 500:
        case 502:
        case 503:
          throw ServerException(message: errorMessage);
        default:
          throw ServerException(message: 'HTTP Error: ${response.statusCode}');
      }
    }
  }
}