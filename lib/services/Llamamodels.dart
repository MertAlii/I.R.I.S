import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final geminiServiceProvider = Provider((ref) => GeminiService());

class GeminiService {
  // NOTE: In a production app, use --dart-define or .env files.
  static const String _apiKey = 'AIzaSyDjeSpxmvO3w04M5-jOuJXaO7IZyng2gRE';
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
    );
  }

  Future<String> sendMessage(String message) async {
    final content = [Content.text(message)];
    try {
      final response = await _model.generateContent(content);
      return response.text ?? "Üzgünüm, şu an yanıt veremiyorum.";
    } catch (e) {
      print("Gemini Error: $e");
      return "Bir hata oluştu. Lütfen tekrar deneyin.";
    }
  }

  Stream<GenerateContentResponse> streamMessage(String message) {
    final content = [Content.text(message)];
    return _model.generateContentStream(content);
  }
}
