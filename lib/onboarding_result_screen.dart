import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import 'main.dart';
import 'shatter_transition.dart';

class OnboardingResultScreen extends StatefulWidget {
  final User user;
  final Map<String, dynamic> skinProfile;

  const OnboardingResultScreen({
    super.key,
    required this.user,
    required this.skinProfile,
  });

  @override
  State<OnboardingResultScreen> createState() => _OnboardingResultScreenState();
}

class _OnboardingResultScreenState extends State<OnboardingResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _gradientController;
  late Animation<double> _fadeIn;
  final ShatterController _shatterController = ShatterController();
  String _aiPlan = '';
  bool _loading = true;
  String _error = '';
  List<_PlanSection> _sections = [];

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _generatePlan();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    debugPrint('_generatePlan START');
    try {
      final skinType = widget.skinProfile['skinType'] ?? 'Unknown';
      final concerns = (widget.skinProfile['concerns'] as List?)
              ?.cast<String>()
              .join(', ') ??
          'none';
      final amRoutine = widget.skinProfile['amRoutine'] ?? '';
      final pmRoutine = widget.skinProfile['pmRoutine'] ?? '';

      final prompt = '''
IMPORTANT: You MUST respond using EXACTLY these section headers with no deviation. Do not add any text before the first header. Do not use markdown, asterisks, or bullet symbols.

SKIN ASSESSMENT
Write 2-3 sentences analyzing their skin type and concerns.

MORNING ROUTINE
Write a step by step AM routine with specific product recommendations for their skin type.

EVENING ROUTINE
Write a step by step PM routine with specific product recommendations for their skin type.

KEY INGREDIENTS
List 3-5 power ingredients they should look for and why.

WHAT TO AVOID
List ingredients or habits to avoid for their specific skin type and concerns.

QUICK WIN
Give one immediate change they can make today that will show results fast.

User Profile:
- Skin Type: $skinType
- Primary Concerns: $concerns
- Current AM Routine: ${amRoutine.isEmpty ? 'Not provided' : amRoutine}
- Current PM Routine: ${pmRoutine.isEmpty ? 'Not provided' : pmRoutine}
''';

      final url = Uri.parse(
        'https://us-central1-skinforreal-aa846.cloudfunctions.net/claudeProxy',
      );

      print('Calling Claude proxy at: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'max_tokens': 1000,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final content = data['content'];
        if (content == null || (content as List).isEmpty) {
          setState(() {
            _error = 'Empty response from AI. Tap to retry.';
            _loading = false;
          });
          return;
        }

        final text = content[0]['text'] as String? ?? '';
        if (text.isEmpty) {
          setState(() {
            _error = 'Empty response from AI. Tap to retry.';
            _loading = false;
          });
          return;
        }

        setState(() {
          _aiPlan = text;
          _sections = _parseSections(text);
          _loading = false;
        });

        await AuthService.saveSkinProfile(
          uid: widget.user.uid,
          skinProfile: {
            ...widget.skinProfile,
            'aiPlan': text,
            'aiPlanGeneratedAt': DateTime.now().toIso8601String(),
            'completedAt': DateTime.now().toIso8601String(),
          },
        );
      } else {
        print('Claude API error: ${response.statusCode} ${response.body}');
        setState(() {
          _error = 'Error ${response.statusCode}. Tap to retry.';
          _loading = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _error = 'Request timed out. Check your connection and tap to retry.';
        _loading = false;
      });
    } catch (e) {
      print('Exception: $e');
      setState(() {
        _error = 'Error: $e — tap to retry.';
        _loading = false;
      });
    }
  }

  List<_PlanSection> _parseSections(String raw) {
    final sectionDefs = [
      ('SKIN ASSESSMENT', Icons.face_retouching_natural_rounded, const Color(0xFF9B4DCA)),
      ('MORNING ROUTINE', Icons.wb_sunny_rounded, const Color(0xFFFF9F43)),
      ('EVENING ROUTINE', Icons.nightlight_round, const Color(0xFF5C5FED)),
      ('KEY INGREDIENTS', Icons.bolt_rounded, const Color(0xFF00D2FF)),
      ('WHAT TO AVOID', Icons.block_rounded, const Color(0xFFFF4757)),
      ('QUICK WIN', Icons.rocket_launch_rounded, const Color(0xFF2ED573)),
    ];

    final sections = <_PlanSection>[];
    for (int i = 0; i < sectionDefs.length; i++) {
      final (title, icon, color) = sectionDefs[i];
      final nextTitle = i + 1 < sectionDefs.length ? sectionDefs[i + 1].$1 : null;
      final startIdx = raw.indexOf(title);
      if (startIdx == -1) continue;
      final contentStart = startIdx + title.length;
      final endIdx = nextTitle != null
          ? raw.indexOf(nextTitle, contentStart)
          : raw.length;
      final content = raw
          .substring(contentStart, endIdx == -1 ? raw.length : endIdx)
          .trim();
      if (content.isNotEmpty) {
        sections.add(_PlanSection(title: title, content: content, icon: icon, color: color));
      }
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _aiPlan.isEmpty && _error.isEmpty) {
      debugPrint('build: triggering generatePlan');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _loading && _aiPlan.isEmpty) {
          debugPrint('postFrame: calling generatePlan');
          _generatePlan();
        }
      });
    }
    return ShatterTransition(
      controller: _shatterController,
      onComplete: () {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SkinAnalyzer(),
          transitionDuration: Duration.zero,
        ));
      },
      child: Scaffold(
          backgroundColor: const Color(0xFF0a0a1a),
          body: AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            final t = _gradientController.value;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(t * 0.6 - 0.3, -0.5),
                  end: Alignment(0.3 - t * 0.6, 0.8),
                  colors: [
                    Color.lerp(const Color(0xFF1a0533), const Color(0xFF0a1628), t)!,
                    Color.lerp(const Color(0xFF0d1f3c), const Color(0xFF1a0533), t)!,
                    Color.lerp(const Color(0xFF0f2027), const Color(0xFF120a1a), t)!,
                  ],
                ),
              ),
              child: child,
            );
          },
          child: FadeTransition(
            opacity: _fadeIn,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFB76EF5), Color(0xFF6EE4F5), Color(0xFFF56EB7)],
                          ).createShader(bounds),
                          child: const Text('Your Skin Plan',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                        const Spacer(),
                        if (!_loading)
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushReplacement(PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const SkinAnalyzer(),
                                transitionsBuilder: (_, anim, __, child) =>
                                    FadeTransition(opacity: anim, child: child),
                              ));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                    colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)]),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF7B2FBE)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 12)
                                ],
                              ),
                              child: const Text('Try Analyzer ✨',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _loading
                          ? 'Building your personalized routine...'
                          : 'Powered by AI • Based on your skin profile',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.35)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _loading
                        ? _buildLoading()
                        : _error.isNotEmpty
                            ? _buildError()
                            : _buildPlan(),
                  ),
                  if (!_loading && _error.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushReplacement(PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const SkinAnalyzer(),
                                transitionsBuilder: (_, anim, __, child) =>
                                    FadeTransition(opacity: anim, child: child),
                              ));
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                    colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)]),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF7B2FBE)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8))
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.face_retouching_natural_rounded,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 10),
                                  Text('Scan My Face for Deeper Analysis',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => const SkinAnalyzer(),
                                  transitionsBuilder: (_, anim, __, child) =>
                                      FadeTransition(opacity: anim, child: child),
                                ),
                              );
                            },
                            child: Text('Skip for now, go to app',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.3))),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)]),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF7B2FBE).withValues(alpha: 0.5),
                    blurRadius: 24,
                    spreadRadius: 2)
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            ),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE), Color(0xFFBE2F7B)],
            ).createShader(bounds),
            child: const Text('Analyzing your skin profile...',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text('AI is building your routine',
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.35))),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _loading = true;
            _error = '';
          });
          _generatePlan();
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFFFF4757).withValues(alpha: 0.3)),
            color: const Color(0xFFFF4757).withValues(alpha: 0.06),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh_rounded, color: Color(0xFFFF4757), size: 32),
              const SizedBox(height: 12),
              Text(_error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFF4757), fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlan() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _sections.length,
      itemBuilder: (context, i) {
        final section = _sections[i];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + i * 80),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) => Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: section.color.withValues(alpha: 0.3)),
              gradient: LinearGradient(
                colors: [
                  section.color.withValues(alpha: 0.08),
                  const Color(0xFF1e1e2e).withValues(alpha: 0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                    color: section.color.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: section.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9)),
                    child: Icon(section.icon, size: 14, color: section.color),
                  ),
                  const SizedBox(width: 10),
                  Text(section.title,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: section.color,
                          letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 10),
                Text(section.content,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.65,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlanSection {
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  const _PlanSection(
      {required this.title,
      required this.content,
      required this.icon,
      required this.color});
}
