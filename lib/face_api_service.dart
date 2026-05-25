import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FaceApiService {
  static const String _endpoint = 'https://skinforreal-face-api.cognitiveservices.azure.com';
  static const String _subscriptionKey = const String.fromEnvironment('AZURE_KEY'),
  static const String _groqKey = const String.fromEnvironment('GROQ_KEY');

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
    if (exposure >= 0.65) return 'Light';
    if (exposure >= 0.50) return 'Medium';
    if (exposure >= 0.45) return 'Tan/Olive';
    if (exposure >= 0.30) return 'Brown';
    return 'Deep/Dark';
  }

  static String detectSkinType(Map<String, dynamic> attr) {
    final blur = attr['blur']?['blurLevel'] ?? 'low';
    final noise = attr['noise']?['value'] ?? 0.0;
    final exposure = attr['exposure']?['value'] ?? 0.0;

    if (noise > 0.5 && blur == 'high') return 'Acne-prone';
    if (exposure > 0.6 && noise < 0.3) return 'Oily';
    if (exposure < 0.2 && noise < 0.2) return 'Dry';
    return 'Combination/Normal';
  }

  static Future<String> getAIRecommendations(String skinType, String skinTone) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final prompt = '''You are a next-generation AI dermatologist built into SkinForReal, a skincare app for Gen Z. You speak like a knowledgeable best friend who happens to have a medical degree. You are direct, specific, and never give generic advice.

The user's skin has been analyzed:
Skin Type: $skinType
Skin Tone: $skinTone

Write a personalized skincare guide in this EXACT structure with these EXACT headers (use these exact labels, no markdown symbols):

SKIN SUMMARY
Write 2-3 sentences explaining what their specific skin type and tone combination means, what challenges they face, and what their skin is capable of. Be specific to their combination, not generic. Sound like you actually analyzed their face.

MORNING ROUTINE
List 4-5 steps numbered. For each step include a specific product recommendation for US, Korean, and budget option. Format each as: Step name: explanation. Products: [US option] / [Korean option] / [Budget pick]

EVENING ROUTINE
List 4-6 steps numbered. Include cleansing, actives, and moisturizing. Same format as morning.

RETINOID ROADMAP
This is critical. Explain the retinoid journey specifically for their skin type and tone. Start with: "Begin with tretinoin 0.025% (prescription) or over-the-counter retinol 0.025% 2x per week. After 4-6 weeks with no irritation, increase to 3x per week. Goal is nightly use within 3 months. Then upgrade to tretinoin 0.05% after 6 months of tolerating 0.025% nightly. Eventually 0.1% for advanced users." Explain purging vs reaction. Tell them to see a dermatologist before starting prescription tret. Mention azelaic acid 15% as a gentler alternative or complement that targets pigmentation, redness, and acne simultaneously and pairs well with tret. Mention that for $skinTone skin, azelaic acid is especially powerful for fading post-acne marks.

POWER INGREDIENTS
List 5-7 ingredients they should add to their routine with a one-line explanation of why it works for their specific skin type and tone. Include niacinamide, vitamin C, hyaluronic acid, and others relevant to their type.

INGREDIENTS TO AVOID
List 3-5 specific ingredients that are bad for their skin type and tone. Explain why briefly.

DERMATOLOGIST ALERT
Write 2-3 sentences about when they should see a real dermatologist. Be specific to their skin type. Mention that prescription tretinoin, spironolactone for hormonal acne, and professional treatments like chemical peels are only available through a derm.

LIFESTYLE UPGRADES
List 3-4 specific lifestyle changes that will directly impact their skin based on their type and tone. Include diet, sleep, stress, and environment.

Do not use any asterisks, hashtags, or markdown. Use plain text only. Be specific, personal, and Gen Z in tone. Never be generic.''';

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_groqKey',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 2000,
        'temperature': 0.75,
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
      return 'Flare-up detected. Recheck new products or actives. Use fewer steps.';
    }
    if (prev == 'Dry' && current == 'Oily') {
      return 'Could be rebound oil from over-cleansing. Use barrier-repair creams.';
    }
    return 'No concerning pattern detected.';
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
      return 'No consistent pattern in skin state. Consider simplifying your skincare.';
    }

    if ((counts['Acne-prone'] ?? 0) >= 5) {
      return 'Frequent acne results. Check actives or base products like moisturizers or SPF.';
    }

    return 'No concerning trends detected.';
  }
}