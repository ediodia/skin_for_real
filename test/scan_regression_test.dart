import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skin_for_real/ai_text.dart';
import 'package:skin_for_real/scan_streak.dart';
import 'package:skin_for_real/face_api_service.dart';

void main() {
  test('streak awards at most one day and resets after a missed day', () {
    expect(nextScanStreak(0, null, DateTime(2026, 9, 10)), 1);
    expect(nextScanStreak(4, '2026-09-10', DateTime(2026, 9, 10, 23)), 4);
    expect(nextScanStreak(4, '2026-09-10', DateTime(2026, 9, 11)), 5);
    expect(nextScanStreak(4, '2026-09-10', DateTime(2026, 9, 12)), 1);
    expect(nextScanStreak(4, '2026-09-10', DateTime(2026, 9, 9)), 4);
  });
  test('streak handles DST boundaries, leap days, and year rollover', () {
    expect(nextScanStreak(2, '2026-03-08', DateTime(2026, 3, 9)), 3);
    expect(nextScanStreak(2, '2026-11-01', DateTime(2026, 11, 2)), 3);
    expect(nextScanStreak(2, '2028-02-29', DateTime(2028, 3, 1)), 3);
    expect(nextScanStreak(2, '2026-12-31', DateTime(2027, 1, 1)), 3);
  });
  test('text preserves Unicode punctuation, ranges, and word boundaries', () {
    const text = 'Hyaluronic‑Acid • 7–9 hours — 40–50%\nYou’ve got café skin';
    expect(cleanAiText('## Summary\n**$text**'), 'Summary\n$text');
    expect(cleanAiText('<think>private reasoning</think>Final'), 'Final');
    expect(cleanAiText('<think>unfinished'), '');
  });

  Future<void> withVision(dynamic payload, Future<void> Function() check,
      {int status = 200}) async {
    await http.runWithClient(() async {
      await FaceApiService.analyzeFaceFromImage(XFile.fromData(
          Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]),
          mimeType: 'image/png'));
      await check();
    },
        () => MockClient((request) async {
              if (request.url.host.startsWith('analyzeface')) {
                return http.Response(
                    '[{"faceAttributes":{"exposure":{"value":0.5}}}]', 200);
              }
              final body = jsonDecode(request.body);
              expect(body['model'], 'qwen/qwen3.8-27b');
              expect(body['reasoning_effort'], 'none');
              expect(body['messages'][0]['content'][0]['image_url']['url'],
                  startsWith('data:image/png;base64,'));
              return http.Response(jsonEncode(payload), status);
            }));
  }

  test('vision rejects upstream errors even if proxy reports HTTP 200',
      () async {
    await withVision({
      'error': {'message': 'model unavailable'}
    }, () async {
      await expectLater(
          FaceApiService.analyzeBreakoutsFromImage(), throwsException);
    });
  });
  test('vision rejects HTTP failures', () async {
    await withVision({}, () async {
      await expectLater(
          FaceApiService.analyzeBreakoutsFromImage(), throwsException);
    }, status: 429);
  });
  test('vision rejects incomplete JSON instead of inventing healthy defaults',
      () async {
    await withVision({
      'choices': [
        {
          'message': {'content': '{"severity":"Clear"}'}
        }
      ]
    }, () async {
      await expectLater(
          FaceApiService.analyzeBreakoutsFromImage(), throwsException);
    });
  });
  test('vision accepts valid observations and reuses them for the same image',
      () async {
    final observation = {
      'severity': 'Mild',
      'breakout_detected': true,
      'zones': ['chin'],
      'summary': 'Visible spots on chin.',
      'skin_score': 65,
      'oiliness_score': 4,
      'redness': 'Low',
      'pigmentation': 'None',
      'fine_lines': 'None',
      'pore_visibility': 'Minimal',
      'texture': 'Smooth',
      'hydration': 'Normal',
    };
    await withVision({
      'choices': [
        {
          'message': {'content': jsonEncode(observation)}
        }
      ]
    }, () async {
      final result = await FaceApiService.analyzeBreakoutsFromImage();
      expect(result['severity'], 'Mild');
      expect(result['skin_score'], '65');
      expect(await FaceApiService.analyzeBreakoutsFromImage(), result);
    });
  });

  test('recommendations reuse supplied observations and preserve punctuation', () async {
    var requests = 0;
    await http.runWithClient(() async {
      final result = await FaceApiService.getAIRecommendations('Normal', 'Medium',
          breakoutData: {'severity': 'Clear', 'summary': 'No visible spots.'});
      expect(requests, 1);
      expect(result.recommendations, contains('7–9 hours'));
    }, () => MockClient((request) async {
      requests++;
      expect(jsonDecode(request.body)['model'], 'openai/gpt-oss-120b');
      return http.Response(jsonEncode({'choices': [{
        'finish_reason': 'stop',
        'message': {'content': 'SKIN SUMMARY\nSleep 7–9 hours.\n---PRODUCTS_JSON---\n{"morning":[],"evening":[],"power_ingredients":[],"retinoids":[]}'}
      }]}), 200, headers: {'content-type': 'application/json; charset=utf-8'});
    }));
  });

  test('incomplete recommendations do not count as a completed result', () async {
    await http.runWithClient(() async {
      await expectLater(FaceApiService.getAIRecommendations('Normal', 'Medium',
          breakoutData: {'severity': 'Clear'}), throwsException);
    }, () => MockClient((_) async => http.Response(jsonEncode({'choices': [{
      'finish_reason': 'length', 'message': {'content': 'Partial plan'}
    }]}), 200)));
  });
}
