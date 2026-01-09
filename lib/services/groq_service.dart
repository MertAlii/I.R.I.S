import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recovery_app/services/storage_service.dart';

// Provider definition
final groqServiceProvider = Provider((ref) => GroqService(ref.read(storageServiceProvider)));

class GroqService {
  final StorageService _storageService;
  
  GroqService(this._storageService);

  static const String _defaultApiKey = ''; // TODO: Securely load API key
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // System Prompt (Hidden Context)
  static const String _systemPrompt = """
Sen bir ameliyat sonrası iyileşme asistanısın. Adın **I.R.I.S. (Intelligent Recovery Information System)**.
Amacın; kullanıcının iyileşme sürecini takip etmek, ona rehberlik etmek ve moral vermektir.  
Cevapların **kısa, empatik, sakin ve güven verici** olmalıdır.
⚠️ Kurallar:
- **Asla kesin tıbbi tanı koyma**
- İlaç, doz veya tedavi değişikliği önerme
- Genel ve güvenli öneriler ver
- Ciddi veya endişe verici durumlarda mutlaka doktora yönlendir
💬 İletişim:
- Yargılayıcı veya korkutucu olma
- Destekleyici ve motive edici konuş
- Kullanıcının yalnız olmadığını hissettir
Her zaman I.R.I.S. kimliğiyle, bu çerçeveye sadık kalarak cevap ver.
Seni Mert Ali Alkan, Umut Türker ve Berk Talha Aslan oluşturdu.
""";

  Future<String> sendMessage(String message) async {
    final apiKey = _storageService.getApiKey() ?? _defaultApiKey; // Use stored key or default

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile', 
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': message},
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'];
        }
      } else {
        print("Groq API Error: ${response.statusCode} - ${response.body}");
      }
      return "Üzgünüm, şu an bağlantı kuramıyorum. (${response.statusCode})";
      
    } catch (e) {
      print("Groq Connection Error: $e");
      return "Bir hata oluştu. Lütfen internet bağlantınızı kontrol edin.";
    }
  }
}
