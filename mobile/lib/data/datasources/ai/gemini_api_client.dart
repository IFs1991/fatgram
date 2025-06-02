import 'package:google_generative_ai/google_generative_ai.dart' as genai;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fatgram/core/config/env_config.dart';
import 'package:fatgram/core/error/exceptions.dart';
import 'package:logger/logger.dart';

final geminiClientProvider = Provider<GeminiApiClient>((ref) {
  return GeminiApiClient(
    apiKey: EnvConfig.geminiApiKey,
    logger: Logger(),
  );
});

class GeminiApiClient {
  final String apiKey;
  final Logger logger;
  genai.GenerativeModel? _chatModel;
  genai.GenerativeModel? _visionModel;

  GeminiApiClient({
    required this.apiKey,
    required this.logger,
  });

  genai.GenerativeModel get chatModel {
    _chatModel ??= genai.GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
      safetySettings: [
        genai.SafetySetting(
          genai.HarmCategory.harassment,
          genai.HarmBlockThreshold.medium,
        ),
        genai.SafetySetting(
          genai.HarmCategory.dangerousContent,
          genai.HarmBlockThreshold.medium,
        ),
      ],
    );
    return _chatModel!;
  }

  genai.GenerativeModel get visionModel {
    _visionModel ??= genai.GenerativeModel(
      model: 'gemini-1.5-pro-vision',
      apiKey: apiKey,
      safetySettings: [
        genai.SafetySetting(
          genai.HarmCategory.harassment,
          genai.HarmBlockThreshold.medium,
        ),
        genai.SafetySetting(
          genai.HarmCategory.dangerousContent,
          genai.HarmBlockThreshold.medium,
        ),
      ],
    );
    return _visionModel!;
  }

  Future<String> generateChatResponse({
    required List<Map<String, dynamic>> history,
    Map<String, String>? systemInstructions,
  }) async {
    try {
      final contents = history.map((item) {
        final role = item['role'] as String;
        final content = item['content'] as String;

        return genai.Content(
          role == 'user' ? 'user' : 'model',
          [genai.TextPart(content)],
        );
      }).toList();

      // システムインストラクションがある場合は先頭に追加
      if (systemInstructions != null && systemInstructions.isNotEmpty) {
        final instructions = systemInstructions.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');

        contents.insert(
          0,
          genai.Content(
            'system',
            [genai.TextPart(instructions)],
          ),
        );
      }

      final response = await chatModel.generateContent(contents);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw const ServerException(
          message: 'Empty response from Gemini API',
        );
      }

      return responseText;
    } catch (e) {
      logger.e('Error generating chat response: $e');
      throw ServerException(
        message: 'Failed to generate response: ${e.toString()}',
      );
    }
  }

  Future<String> generateVisionResponse({
    required String prompt,
    required List<genai.Part> imageParts,
    Map<String, String>? systemInstructions,
  }) async {
    try {
      final parts = <genai.Part>[genai.TextPart(prompt)];
      parts.addAll(imageParts);

      final content = genai.Content('user', parts);

      final response = await visionModel.generateContent([content]);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw const ServerException(
          message: 'Empty response from Gemini Vision API',
        );
      }

      return responseText;
    } catch (e) {
      logger.e('Error generating vision response: $e');
      throw ServerException(
        message: 'Failed to generate vision response: ${e.toString()}',
      );
    }
  }
}