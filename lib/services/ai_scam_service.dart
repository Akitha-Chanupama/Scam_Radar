import 'package:dio/dio.dart';

/// AI-enhanced scam detection service.
///
/// This service can call an external AI API (e.g., OpenAI, Gemini)
/// via a Supabase Edge Function for more accurate scam detection.
///
/// Setup:
/// 1. Create a Supabase Edge Function named `analyze-scam`
/// 2. In the Edge Function, call your preferred AI API
/// 3. Update [_edgeFunctionUrl] with your function URL
///
/// Example Edge Function (Deno/TypeScript):
/// ```typescript
/// import { serve } from "https://deno.land/std/http/server.ts"
///
/// serve(async (req) => {
///   const { message } = await req.json()
///   // Call OpenAI/Gemini API here
///   // Return { score: number, reasons: string[] }
///   return new Response(JSON.stringify({ score, reasons }))
/// })
/// ```
class AiScamService {
  final Dio _dio;
  final String? _edgeFunctionUrl;

  AiScamService({String? edgeFunctionUrl})
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        )),
        _edgeFunctionUrl = edgeFunctionUrl;

  bool get isConfigured =>
      _edgeFunctionUrl != null && _edgeFunctionUrl.isNotEmpty;

  /// Analyze a message using the AI API.
  /// Returns null if the service is not configured or the request fails.
  Future<AiScamResult?> analyzeMessage(String messageText) async {
    if (!isConfigured) return null;

    try {
      final response = await _dio.post(
        _edgeFunctionUrl!,
        data: {'message': messageText},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return AiScamResult(
          score: data['score'] as int,
          reasons: (data['reasons'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
          confidence: (data['confidence'] as num?)?.toDouble() ?? 0.8,
        );
      }
    } on DioException {
      // AI service unavailable — fall back to rule-based
    }
    return null;
  }
}

class AiScamResult {
  final int score;
  final List<String> reasons;
  final double confidence;

  const AiScamResult({
    required this.score,
    required this.reasons,
    this.confidence = 0.8,
  });
}
