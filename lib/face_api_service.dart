import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FaceApiService {
  static const String _endpoint = 'https://skinforreal-face-api.cognitiveservices.azure.com';
  static const String _subscriptionKey = '28KSrbOasu14DIsNO2oD6UpLeu2tZC79WB17K9WPbYwppTnjMA4RJQQJ99CEACYeBjFXJ3w3AAAKACOGZi8j';
  static const String _groqKey = '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';

  static Future<Map<String, dynamic>> analyzeFaceFromImage(XFile imageFile) async {
    final uri = Uri.parse('$_endpoint/face/v1.0/detect?returnFaceAttributes=blur,exposure,noise,occlusion,glasses,headPose');
    final bytes = await imageFile.readAsBytes();

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/octet-stream',
        'Ocp-Apim-Subscription-Key': _subscriptionKey,
      },
      body: bytes,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty && data[0]['faceAttributes'] != null) {
        return data[0]['faceAttributes'];
      } else {
        return {'error': 'No face detected'};
      }
    } else {
      throw Exception('Azure error: ${response.body}');
    }
  }

  static String estimateSkinColorLabel(Map<String, dynamic> attr) {
    final exposure = attr['exposure']?['value'] ?? 0.0;
    if (exposure >= 0.75) return 'Light';
    if (exposure >= 0.55) return 'Medium';
    if (exposure >= 0.35) return 'Tan/Olive';
    if (exposure >= 0.2) return 'Brown';
    return 'Deep/Dark';
  }

  static String detectSkinType(Map<String, dynamic> attr) {
    final blur = attr['blur']?['blurLevel'] ?? 'low';
    final noise = attr['noise']?['value'] ?? 0.0;
    final exposure = attr['exposure']?['value'] ?? 0.0;

    if (noise > 0.5 && blur == 'high') return 'Acne-prone';
    if (exposure > 0.6 && noise < 0.3) return 'Oily';
    if (exposure < 0.3 && noise < 0.3) return 'Dry';
    return 'Combination/Normal';
  }

  static Future<String> getAIRecommendations(String skinType, String skinTone) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final prompt = '''You are a professional dermatologist and skincare expert. A user has had their skin analyzed with the following results:

Skin Type: $skinType
Skin Tone: $skinTone

Please provide:
1. A brief explanation of what this skin type means
2. A personalized AM and PM skincare routine with specific product recommendations (include US, European, and Korean options where relevant)
3. Key ingredients to look for and avoid
4. Any advanced treatments to consider (retinoids, acids, etc.)
5. Lifestyle tips relevant to this skin type and tone

Keep it practical, specific, and easy to follow. Use emojis to make it readable.''';

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_groqKey',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_tokens': 1000,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Groq error: ${response.body}');
    }
  }

  static String suggestCulprit(String prev, String current) {
    if (prev != 'Acne-prone' && current == 'Acne-prone') {
      return '⚠️ Flare-up detected. Recheck new products or actives. Use fewer steps.';
    }
    if (prev == 'Dry' && current == 'Oily') {
      return '🔁 Could be rebound oil from over-cleansing. Use barrier-repair creams.';
    }
    return '✅ No concerning pattern detected.';
  }

  static Future<String> analyzeTrendsAndSuggest() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final logs = <String>[];

    for (int i = 0; i <= 14; i++) {
      final day = now.subtract(Duration(days: i)).toIso8601String().split('T').first;
      final log = prefs.getString('progress_$day');
      if (log != null) logs.add(log);
    }

    final counts = <String, int>{};
    for (final t in logs) {
      counts[t] = (counts[t] ?? 0) + 1;
    }

    if (logs.length >= 7 && counts.values.every((v) => v == 1)) {
      return '⚠️ No consistent pattern in skin state. Consider simplifying your skincare.';
    }

    if ((counts['Acne-prone'] ?? 0) >= 5) {
      return '🚨 Frequent acne results. Check actives or base products like moisturizers or SPF.';
    }

    return '✅ No concerning trends detected.';
  }
}