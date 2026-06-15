import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecommendedProduct {
  final String name;
  final String brand;
  final String whyItWorks;
  final String category;
  final String priceRange;
  final String amazonSearchUrl;

  const RecommendedProduct({
    required this.name,
    required this.brand,
    required this.whyItWorks,
    required this.category,
    required this.priceRange,
    required this.amazonSearchUrl,
  });

  factory RecommendedProduct.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    final brand = json['brand']?.toString() ?? '';
    final searchQuery = Uri.encodeComponent('$brand $name skincare');
    return RecommendedProduct(
      name: name,
      brand: brand,
      whyItWorks: json['why']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      priceRange: json['price_range']?.toString() ?? '',
      amazonSearchUrl: 'https://www.amazon.com/s?k=$searchQuery',
    );
  }
}

class SkinAnalysisResult {
  final String recommendations;
  final List<RecommendedProduct> morningProducts;
  final List<RecommendedProduct> eveningProducts;
  final List<RecommendedProduct> powerProducts;
  final List<RecommendedProduct> retinoidProducts;

  const SkinAnalysisResult({
    required this.recommendations,
    required this.morningProducts,
    required this.eveningProducts,
    required this.powerProducts,
    required this.retinoidProducts,
  });
}

class FaceApiService {
  static const String _faceProxy =
      'https://analyzeface-yp4lhrod3q-uc.a.run.app';
  static const String _groqProxy = 'https://groqchat-yp4lhrod3q-uc.a.run.app';

  static Uint8List? _lastImageBytes;

  static Future<Map<String, dynamic>> analyzeFaceFromImage(
      XFile imageFile) async {
    final uri = Uri.parse(
        '$_faceProxy?returnFaceAttributes=blur,exposure,noise,occlusion,glasses,headPose');
    final bytes = await imageFile.readAsBytes();
    _lastImageBytes = bytes;

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/octet-stream'},
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
    final exposure = (attr['exposure']?['value'] as num?)?.toDouble() ?? 0.0;
    if (exposure >= 0.65) return 'Light';
    if (exposure >= 0.50) return 'Medium';
    if (exposure >= 0.45) return 'Tan/Olive';
    if (exposure >= 0.30) return 'Brown';
    return 'Deep/Dark';
  }

  static String detectSkinType(Map<String, dynamic> attr) {
    final noise = (attr['noise']?['value'] as num?)?.toDouble() ?? 0.0;
    final exposure = (attr['exposure']?['value'] as num?)?.toDouble() ?? 0.0;

    if (exposure > 0.6 && noise < 0.3) return 'Oily';
    if (exposure < 0.2 && noise < 0.2) return 'Dry';
    return 'Combination/Normal';
  }

  static Future<Map<String, String>> analyzeBreakoutsFromImage() async {
    if (_lastImageBytes == null) {
      return {'severity': 'Unknown', 'summary': 'No image available.'};
    }

    final base64Image = base64Encode(_lastImageBytes!);

    final response = await http.post(
      Uri.parse(_groqProxy),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
              {
                'type': 'text',
                'text':
                    '''You are a dermatology AI. Analyze this face image and assess the skin condition.

Return ONLY a JSON object with no extra text, no markdown, no backticks:
{
  "severity": "Clear" | "Mild" | "Moderate" | "Active Breakout",
  "breakout_detected": true | false,
  "zones": ["forehead", "cheeks", "chin", "nose"] (only zones with visible issues),
  "redness": "None" | "Low" | "Moderate" | "High",
  "pigmentation": "None" | "Light" | "Moderate" | "Heavy",
  "summary": "One sentence describing what you see on the skin"
}

Be honest and specific. If the image is unclear, say so in summary but still return valid JSON.'''
              }
            ]
          }
        ],
        'max_tokens': 300,
        'temperature': 0.2,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'];
      if (choices == null || (choices as List).isEmpty) {
        return {'severity': 'Unknown', 'summary': 'Vision analysis failed.'};
      }
      final content = choices[0]['message']['content'] as String;
      try {
        final cleaned =
            content.replaceAll('```json', '').replaceAll('```', '').trim();
        final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
        return {
          'severity': parsed['severity']?.toString() ?? 'Unknown',
          'breakout_detected':
              parsed['breakout_detected']?.toString() ?? 'false',
          'zones': (parsed['zones'] as List?)?.join(', ') ?? 'none',
          'redness': parsed['redness']?.toString() ?? 'None',
          'pigmentation': parsed['pigmentation']?.toString() ?? 'None',
          'summary': parsed['summary']?.toString() ?? 'Unable to assess.',
        };
      } catch (_) {
        return {'severity': 'Unknown', 'summary': content};
      }
    } else {
      return {'severity': 'Unknown', 'summary': 'Vision analysis failed.'};
    }
  }

  static List<RecommendedProduct> _parseProducts(dynamic raw) {
    if (raw == null) return [];
    try {
      final list = raw as List<dynamic>;
      return list
          .map((e) => RecommendedProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<SkinAnalysisResult> getAIRecommendations(
      String skinType, String skinTone) async {
    final breakoutData = await analyzeBreakoutsFromImage();
    final severity = breakoutData['severity'] ?? 'Unknown';
    final zones = breakoutData['zones'] ?? 'none';
    final redness = breakoutData['redness'] ?? 'None';
    final pigmentation = breakoutData['pigmentation'] ?? 'None';
    final breakoutSummary = breakoutData['summary'] ?? '';
    final breakoutDetected = breakoutData['breakout_detected'] == 'true';

    final prompt =
        '''You are a next-generation AI dermatologist built into SkinForReal, a skincare app for Gen Z. You speak like a knowledgeable best friend who happens to have a medical degree. You are direct, specific, and never give generic advice.

The user's skin has been analyzed with computer vision:
Skin Type: $skinType
Skin Tone: $skinTone
Breakout Severity: $severity
Breakout Detected: $breakoutDetected
Affected Zones: $zones
Redness Level: $redness
Pigmentation: $pigmentation
Vision Summary: $breakoutSummary

Your response must have TWO parts separated by exactly this delimiter on its own line:
---PRODUCTS_JSON---

PART 1: Write a personalized skincare guide in this EXACT structure with these EXACT headers (use these exact labels, no markdown symbols):

SKIN SUMMARY
Write 2-3 sentences explaining what their specific skin type and tone combination means, referencing the actual vision analysis results (severity, zones, redness). Be specific — mention if breakouts were detected, where, and what that means. Sound like you actually analyzed their face.

MORNING ROUTINE
List 4-5 steps numbered. For each step include a specific product recommendation for US, Korean, and budget option. Format each as: Step name: explanation. Products: [US option] / [Korean option] / [Budget pick]

EVENING ROUTINE
List 4-6 steps numbered. Include cleansing, actives, and moisturizing. Same format as morning. If breakout was detected, include a targeted treatment step.

RETINOID ROADMAP
This is critical. Explain the retinoid journey specifically for their skin type and tone. Start with: "Begin with tretinoin 0.025% (prescription) or over-the-counter retinol 0.025% 2x per week. After 4-6 weeks with no irritation, increase to 3x per week. Goal is nightly use within 3 months. Then upgrade to tretinoin 0.05% after 6 months of tolerating 0.025% nightly. Eventually 0.1% for advanced users." Explain purging vs reaction. Tell them to see a dermatologist before starting prescription tret. Mention azelaic acid 15% as a gentler alternative or complement that targets pigmentation, redness, and acne simultaneously and pairs well with tret. Mention that for $skinTone skin, azelaic acid is especially powerful for fading post-acne marks.

POWER INGREDIENTS
List 5-7 ingredients they should add to their routine with a one-line explanation of why it works for their specific skin type and tone. Include niacinamide, vitamin C, hyaluronic acid, and others relevant to their type. If breakout detected, prioritize salicylic acid and benzoyl peroxide.

INGREDIENTS TO AVOID
List 3-5 specific ingredients that are bad for their skin type and tone. Explain why briefly.

DERMATOLOGIST ALERT
Write 2-3 sentences about when they should see a real dermatologist. Be specific to their skin type. ${breakoutDetected ? 'Since active breakouts were detected in the $zones area, mention that a derm visit is especially recommended soon.' : ''} Mention that prescription tretinoin, spironolactone for hormonal acne, and professional treatments like chemical peels are only available through a derm.

LIFESTYLE UPGRADES
List 3-4 specific lifestyle changes that will directly impact their skin based on their type and tone. Include diet, sleep, stress, and environment.

Do not use any asterisks, hashtags, or markdown. Use plain text only. Be specific, personal, and Gen Z in tone. Never be generic.

---PRODUCTS_JSON---

PART 2: Return ONLY a valid JSON object with no markdown, no backticks, no extra text:
{
  "morning": [
    {"name": "product name", "brand": "brand name", "why": "one sentence why it works for this skin", "category": "Cleanser|Toner|Serum|Moisturizer|Sunscreen|Treatment", "price_range": "\$X-Y"}
  ],
  "evening": [
    {"name": "product name", "brand": "brand name", "why": "one sentence why it works for this skin", "category": "Cleanser|Toner|Serum|Moisturizer|Treatment|Retinoid", "price_range": "\$X-Y"}
  ],
  "power_ingredients": [
    {"name": "ingredient name", "brand": "The Ordinary or best brand", "why": "one sentence why", "category": "Serum|Treatment", "price_range": "\$X-Y"}
  ],
  "retinoids": [
    {"name": "product name", "brand": "brand name", "why": "one sentence why", "category": "Retinoid", "price_range": "\$X-Y"}
  ]
}

Be specific — use real product names and real brands. Match products exactly to the $skinType and $skinTone.

CRITICAL RULES:
- For "morning" and "evening" arrays: return EXACTLY one product per numbered step in that routine. If morning has 5 steps, return 5 products. If evening has 6 steps, return 6 products. The order must match the steps exactly.
- For "power_ingredients" and "retinoids": return 4-6 products.
- Every product must have a real brand name and real product name that exists on Amazon.''';

    final response = await http.post(
      Uri.parse(_groqProxy),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 4500,
        'temperature': 0.75,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'];
      if (choices == null || (choices as List).isEmpty) {
        throw Exception('Groq returned empty response');
      }
      final fullContent = choices[0]['message']['content'] as String;

      const delimiter = '---PRODUCTS_JSON---';
      final parts = fullContent.split(delimiter);

      final recommendations = parts[0].trim();
      List<RecommendedProduct> morningProducts = [];
      List<RecommendedProduct> eveningProducts = [];
      List<RecommendedProduct> powerProducts = [];
      List<RecommendedProduct> retinoidProducts = [];

      if (parts.length > 1) {
        try {
          final jsonStr = parts[1]
              .trim()
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
          morningProducts = _parseProducts(parsed['morning']);
          eveningProducts = _parseProducts(parsed['evening']);
          powerProducts = _parseProducts(parsed['power_ingredients']);
          retinoidProducts = _parseProducts(parsed['retinoids']);
        } catch (_) {}
      }

      return SkinAnalysisResult(
        recommendations: recommendations,
        morningProducts: morningProducts,
        eveningProducts: eveningProducts,
        powerProducts: powerProducts,
        retinoidProducts: retinoidProducts,
      );
    } else {
      throw Exception('Groq error: ${response.body}');
    }
  }

  static String suggestCulprit(String prev, String current) {
    if (prev != 'Acne-prone' && current == 'Acne-prone') {
      return 'Flare-up detected. Recheck new products or actives.';
    }
    if (prev == 'Dry' && current == 'Oily') {
      return 'Rebound oil detected. Try a barrier-repair cream.';
    }
    if (prev == 'Acne-prone' && current != 'Acne-prone') {
      return 'Skin clearing up. Keep your current routine going.';
    }
    if (prev == current && current == 'Acne-prone') {
      return 'Persistent acne-prone skin. Consider seeing a derm.';
    }
    return 'Skin looks stable. Keep up the routine.';
  }

  static Future<String> analyzeTrendsAndSuggest() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final logs = <String>[];

    for (int i = 0; i <= 14; i++) {
      final day =
          now.subtract(Duration(days: i)).toIso8601String().split('T').first;
      final log = prefs.getString('progress_$day');
      if (log != null) logs.add(log);
    }

    final counts = <String, int>{};
    for (final t in logs) {
      counts[t] = (counts[t] ?? 0) + 1;
    }

    if (logs.length >= 7 && counts.values.every((v) => v == 1)) {
      return 'No consistent pattern. Consider simplifying your routine.';
    }
    if ((counts['Acne-prone'] ?? 0) >= 5) {
      return 'Frequent acne detected. Check actives, SPF, or moisturizer.';
    }
    return 'Skin looks stable over the past two weeks.';
  }
}
