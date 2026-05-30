import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart';
import 'face_api_service.dart';
import 'theme_provider.dart';
import 'calendar.dart';
import 'chatbot.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBVklbTmc1l99JThg-GnMqOIgHd3ppyCpg",
      authDomain: "skinforreal-aa846.firebaseapp.com",
      projectId: "skinforreal-aa846",
      storageBucket: "skinforreal-aa846.firebasestorage.app",
      messagingSenderId: "503120417178",
      appId: "1:503120417178:web:2a72d2183678fb96af6a23",
      measurementId: "G-0MXG9G58NF",
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SkinForRealApp(),
    ),
  );
}

class SkinForRealApp extends StatelessWidget {
  const SkinForRealApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'SkinForReal',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme:
          ThemeData(brightness: Brightness.light, fontFamily: 'San Francisco'),
      darkTheme:
          ThemeData(brightness: Brightness.dark, fontFamily: 'San Francisco'),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      home: const SkinAnalyzer(),
    );
  }
}

class _Ripple {
  final Offset position;
  final AnimationController controller;
  final Animation<double> radius;
  final Animation<double> opacity;
  final Color color;

  _Ripple(
      {required this.position,
      required this.controller,
      required this.radius,
      required this.opacity,
      required this.color});
}

class HolographicBackground extends StatefulWidget {
  final bool isDark;
  final Widget child;
  const HolographicBackground(
      {super.key, required this.isDark, required this.child});

  @override
  State<HolographicBackground> createState() => _HolographicBackgroundState();
}

class _HolographicBackgroundState extends State<HolographicBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  late AnimationController _swirlController;
  final List<_Ripple> _ripples = [];
  Offset _mousePosition = Offset.zero;
  Offset _targetPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller1 =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
    _controller2 =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat(reverse: true);
    _controller3 =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat(reverse: true);
    _swirlController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 50))
      ..addListener(() {
        setState(() {
          _mousePosition = Offset.lerp(_mousePosition, _targetPosition, 0.08)!;
        });
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _swirlController.dispose();
    for (final r in _ripples) r.controller.dispose();
    super.dispose();
  }

  void _addRipple(Offset position) {
    final hue = (position.dx + position.dy) % 360;
    final color = HSVColor.fromAHSV(1.0, hue, 0.7, 1.0).toColor();
    final controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    final radius = Tween<double>(begin: 0, end: 300)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    final opacity = Tween<double>(begin: 0.5, end: 0.0)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    final ripple = _Ripple(
        position: position,
        controller: controller,
        radius: radius,
        opacity: opacity,
        color: color);
    setState(() => _ripples.add(ripple));
    controller.forward().then((_) {
      if (mounted) {
        setState(() => _ripples.remove(ripple));
        controller.dispose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final nx = size.width > 0 ? _mousePosition.dx / size.width : 0.5;
    final ny = size.height > 0 ? _mousePosition.dy / size.height : 0.5;
    final t1 = _controller1.value;
    final t2 = _controller2.value;
    final t3 = _controller3.value;

    return MouseRegion(
      onHover: (d) => setState(() => _targetPosition = d.localPosition),
      child: GestureDetector(
        onTapDown: (d) {
          setState(() => _targetPosition = d.localPosition);
          _addRipple(d.localPosition);
        },
        onPanUpdate: (d) {
          setState(() => _targetPosition = d.localPosition);
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_controller1, _controller2, _controller3]),
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment((t1 * 2 - 1) * 0.6 + nx * 0.8 - 0.4, (t2 * 2 - 1) * 0.6 + ny * 0.8 - 0.4),
                  end: Alignment((t3 * 2 - 1) * 0.6 + (1 - nx) * 0.8 - 0.4, (t1 * 2 - 1) * 0.6 + (1 - ny) * 0.8 - 0.4),
                  colors: widget.isDark
                      ? [
                          Color.lerp(const Color(0xFF1a0533), const Color(0xFF0a1628), t1 * 0.8 + nx * 0.2)!,
                          Color.lerp(const Color(0xFF0d1f3c), const Color(0xFF1a0533), t2 * 0.8 + ny * 0.2)!,
                          Color.lerp(const Color(0xFF0f2027), const Color(0xFF1a0533), t3 * 0.8 + nx * 0.2)!,
                          Color.lerp(const Color(0xFF1a0533), const Color(0xFF0a1628), t1 * 0.8 + ny * 0.2)!,
                        ]
                      : [
                          Color.lerp(const Color(0xFFFFE4F5), const Color(0xFFE8D5FF), t1 * 0.8 + nx * 0.2)!,
                          Color.lerp(const Color(0xFFD5EEFF), const Color(0xFFFFE4F5), t2 * 0.8 + ny * 0.2)!,
                          Color.lerp(const Color(0xFFE8FFE4), const Color(0xFFD5EEFF), t3 * 0.8 + nx * 0.2)!,
                          Color.lerp(const Color(0xFFFFE4F5), const Color(0xFFFFD5F5), t1 * 0.8 + ny * 0.2)!,
                        ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: size.width * (t1 * 0.6),
                    top: size.height * (t2 * 0.4),
                    child: Container(
                      width: 220, height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: widget.isDark
                            ? [const Color(0xFF2F7BBE).withValues(alpha: 0.3), Colors.transparent]
                            : [const Color(0xFF6EE4F5).withValues(alpha: 0.25), Colors.transparent]),
                      ),
                    ),
                  ),
                  Positioned(
                    right: size.width * (t3 * 0.5),
                    bottom: size.height * (t1 * 0.3),
                    child: Container(
                      width: 280, height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: widget.isDark
                            ? [const Color(0xFFBE2F7B).withValues(alpha: 0.25), Colors.transparent]
                            : [const Color(0xFFF56EB7).withValues(alpha: 0.25), Colors.transparent]),
                      ),
                    ),
                  ),
                  Positioned(
                    left: size.width * (t2 * 0.4 + 0.2),
                    bottom: size.height * (t3 * 0.4 + 0.1),
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: widget.isDark
                            ? [const Color(0xFF7B2FBE).withValues(alpha: 0.2), Colors.transparent]
                            : [const Color(0xFFB76EF5).withValues(alpha: 0.2), Colors.transparent]),
                      ),
                    ),
                  ),
                  ..._ripples.map((ripple) {
                    return AnimatedBuilder(
                      animation: ripple.controller,
                      builder: (context, _) {
                        return Positioned(
                          left: ripple.position.dx - ripple.radius.value,
                          top: ripple.position.dy - ripple.radius.value,
                          child: Container(
                            width: ripple.radius.value * 2,
                            height: ripple.radius.value * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ripple.color.withValues(alpha: ripple.opacity.value),
                                width: 1.5,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  child!,
                ],
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

class _RecommendationSection {
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  const _RecommendationSection(
      {required this.title,
      required this.content,
      required this.icon,
      required this.color});
}

List<_RecommendationSection> _parseRecommendations(String raw) {
  final sections = <_RecommendationSection>[];
  final sectionDefs = [
    (
      'SKIN SUMMARY',
      Icons.face_retouching_natural_rounded,
      const Color(0xFF9B4DCA)
    ),
    ('MORNING ROUTINE', Icons.wb_sunny_rounded, const Color(0xFFFF9F43)),
    ('EVENING ROUTINE', Icons.nightlight_round, const Color(0xFF5C5FED)),
    ('RETINOID ROADMAP', Icons.rocket_launch_rounded, const Color(0xFFFF6B9D)),
    ('POWER INGREDIENTS', Icons.bolt_rounded, const Color(0xFF00D2FF)),
    ('INGREDIENTS TO AVOID', Icons.block_rounded, const Color(0xFFFF4757)),
    (
      'DERMATOLOGIST ALERT',
      Icons.local_hospital_rounded,
      const Color(0xFFFF6348)
    ),
    (
      'LIFESTYLE UPGRADES',
      Icons.self_improvement_rounded,
      const Color(0xFF2ED573)
    ),
  ];

  for (int i = 0; i < sectionDefs.length; i++) {
    final (title, icon, color) = sectionDefs[i];
    final nextTitle = i + 1 < sectionDefs.length ? sectionDefs[i + 1].$1 : null;
    final startIdx = raw.indexOf(title);
    if (startIdx == -1) continue;
    final contentStart = startIdx + title.length;
    final endIdx =
        nextTitle != null ? raw.indexOf(nextTitle, contentStart) : raw.length;
    final content =
        raw.substring(contentStart, endIdx == -1 ? raw.length : endIdx).trim();
    if (content.isNotEmpty) {
      sections.add(_RecommendationSection(
          title: title, content: content, icon: icon, color: color));
    }
  }

  if (sections.isEmpty) {
    sections.add(_RecommendationSection(
      title: 'AI RECOMMENDATIONS',
      content: raw.trim(),
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFF7B2FBE),
    ));
  }

  return sections;
}

class SkinAnalyzer extends StatefulWidget {
  const SkinAnalyzer({super.key});

  @override
  State<SkinAnalyzer> createState() => _SkinAnalyzerState();
}

class _SkinAnalyzerState extends State<SkinAnalyzer>
    with TickerProviderStateMixin {
  XFile? _imageFile;
  String _skinColor = '';
  String _skinType = '';
  String _tips = '';
  String _culpritMessage = '';
  String _manualOverrideTone = '';
  String _lastSkinType = '';
  bool _loading = false;
  String _debugError = '';
  double _debugExposure = 0.0;
  SkinAnalysisResult? _analysisResult;

  String _breakoutSeverity = '';
  String _breakoutZones = '';
  String _breakoutRedness = '';
  String _breakoutPigmentation = '';
  String _breakoutSummary = '';
  bool _breakoutDetected = false;

  final ScrollController _scrollController = ScrollController();
  final List<String> _skinToneOptions = [
    'Light',
    'Medium',
    'Tan/Olive',
    'Brown',
    'Deep/Dark'
  ];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _fadeIn =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeOutQuart));
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  Future<void> _saveTonePreference(String tone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('manual_override_tone', tone);
  }

  String _cleanText(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('***', '')
        .replaceAll(RegExp(r'#+\s?'), '')
        .replaceAll(RegExp(r'[^\x00-\x7F\n\r\t ]'), '');
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Clear':
        return const Color(0xFF2ED573);
      case 'Mild':
        return const Color(0xFFFFD93D);
      case 'Moderate':
        return const Color(0xFFFF9F43);
      case 'Active Breakout':
        return const Color(0xFFFF4757);
      default:
        return const Color(0xFF818cf8);
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'Clear':
        return Icons.check_circle_rounded;
      case 'Mild':
        return Icons.info_rounded;
      case 'Moderate':
        return Icons.warning_rounded;
      case 'Active Breakout':
        return Icons.crisis_alert_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  List<RecommendedProduct> _productsForSection(String title) {
    if (_analysisResult == null) return [];
    switch (title) {
      case 'MORNING ROUTINE':
        return _analysisResult!.morningProducts;
      case 'EVENING ROUTINE':
        return _analysisResult!.eveningProducts;
      case 'POWER INGREDIENTS':
        return _analysisResult!.powerProducts;
      case 'RETINOID ROADMAP':
        return _analysisResult!.retinoidProducts;
      default:
        return [];
    }
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1e1e2e).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Quick Note",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            "For best results, use natural lighting and face the camera directly. Flash may affect skin tone detection."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it!",
                style: TextStyle(
                    color: Colors.deepPurple, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    ).then((_) async {
      final pickedFile =
          await ImagePicker().pickImage(source: source, imageQuality: 90);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _skinColor = '';
          _skinType = '';
          _tips = '';
          _culpritMessage = '';
          _debugError = '';
          _manualOverrideTone = '';
          _analysisResult = null;
          _breakoutSeverity = '';
          _breakoutZones = '';
          _breakoutRedness = '';
          _breakoutPigmentation = '';
          _breakoutSummary = '';
          _breakoutDetected = false;
          _loading = true;
        });
        _fadeController.reset();
        _slideController.reset();
        await _analyzeImage(pickedFile);
      }
    });
  }

  Future<void> _analyzeImage(XFile image) async {
    try {
      final attributes = await FaceApiService.analyzeFaceFromImage(image);

      if (attributes.containsKey('error')) {
        setState(() {
          _skinColor = 'Error';
          _skinType = 'Error';
          _debugError =
              'No face detected. Please upload a clear photo of your face in good lighting.';
          _loading = false;
        });
        return;
      }

      if (attributes.isEmpty) {
        setState(() {
          _skinColor = 'Error';
          _skinType = 'Error';
          _debugError = 'Could not read face attributes. Try a clearer photo.';
          _loading = false;
        });
        return;
      }
      final exposure = (attributes['exposure']?['value'] ?? 0.0).toDouble();
      final tone = FaceApiService.estimateSkinColorLabel(attributes);
      final type = FaceApiService.detectSkinType(attributes);
      final selectedTone =
          _manualOverrideTone.isNotEmpty ? _manualOverrideTone : tone;

      final breakoutData = await FaceApiService.analyzeBreakoutsFromImage();
      final breakoutDetectedBool = breakoutData['breakout_detected'] == 'true';
      final severity = breakoutData['severity'] ?? 'Unknown';
      final correctedType =
          breakoutDetectedBool && (severity == 'Moderate' || severity == 'Active Breakout')
              ? 'Acne-prone'
              : type;

      final result =
          await FaceApiService.getAIRecommendations(correctedType, selectedTone);

      final prefs = await SharedPreferences.getInstance();
      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString('progress_$dateStr', correctedType);
      await prefs.setString(
          'log_$dateStr',
          jsonEncode({
            'type': correctedType,
            'color': selectedTone,
            'tips': result.recommendations
          }));

      setState(() {
        _skinColor = tone;
        _skinType = correctedType;
        _tips = _cleanText(result.recommendations);
        _debugExposure = exposure;
        _culpritMessage =
            '${FaceApiService.suggestCulprit(_lastSkinType, correctedType)}  |  Exposure: ${exposure.toStringAsFixed(3)}';
        _lastSkinType = correctedType;
        _analysisResult = result;
        _breakoutSeverity = breakoutData['severity'] ?? 'Unknown';
        _breakoutZones = breakoutData['zones'] ?? 'none';
        _breakoutRedness = breakoutData['redness'] ?? 'None';
        _breakoutPigmentation = breakoutData['pigmentation'] ?? 'None';
        _breakoutSummary = breakoutData['summary'] ?? '';
        _breakoutDetected = breakoutData['breakout_detected'] == 'true';
        _loading = false;
      });

      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _skinColor = 'Error';
        _skinType = 'Error';
        _debugError = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateManualTone(String? tone) async {
    if (tone == null) return;
    _saveTonePreference(tone);
    setState(() {
      _manualOverrideTone = tone;
      _loading = true;
    });
    final result = await FaceApiService.getAIRecommendations(_skinType, tone);
    setState(() {
      _tips = _cleanText(result.recommendations);
      _analysisResult = result;
      _loading = false;
    });
    _fadeController.forward(from: 0);
  }

  Widget _buildProductCards(
      List<RecommendedProduct> products, Color accentColor, bool isDark) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 2,
              height: 14,
              decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text('Shop These Products',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.8)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final p = products[i];
              return GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(p.amazonSearchUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Container(
                  width: 148,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: accentColor.withValues(alpha: 0.25)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              accentColor.withValues(alpha: 0.08),
                              const Color(0xFF16162a)
                            ]
                          : [accentColor.withValues(alpha: 0.04), Colors.white],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: accentColor.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(p.category,
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                    letterSpacing: 0.3)),
                          ),
                          Icon(Icons.open_in_new_rounded,
                              size: 12,
                              color: accentColor.withValues(alpha: 0.5)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.brand,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                            letterSpacing: 0.4),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.name,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.whyItWorks,
                        style: TextStyle(
                            fontSize: 9,
                            height: 1.4,
                            color: isDark ? Colors.white38 : Colors.black38),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.priceRange,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Shop',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBreakoutCard(bool isDark) {
    final color = _severityColor(_breakoutSeverity);
    final icon = _severityIcon(_breakoutSeverity);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(opacity: value, child: child));
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    color.withValues(alpha: 0.1),
                    const Color(0xFF1e1e2e).withValues(alpha: 0.95)
                  ]
                : [
                    color.withValues(alpha: 0.07),
                    Colors.white.withValues(alpha: 0.92)
                  ],
          ),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vision Analysis',
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8)),
                      Text(_breakoutSeverity,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                  const Spacer(),
                  if (_breakoutDetected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4757).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                const Color(0xFFFF4757).withValues(alpha: 0.3)),
                      ),
                      child: const Text('Breakout',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFFF4757),
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              if (_breakoutSummary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_breakoutSummary,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: isDark ? Colors.white70 : Colors.black87)),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_breakoutZones.isNotEmpty && _breakoutZones != 'none')
                    _buildVisionChip('Zones: $_breakoutZones',
                        const Color(0xFFFF9F43), isDark),
                  _buildVisionChip('Redness: $_breakoutRedness',
                      const Color(0xFFFF6B9D), isDark),
                  _buildVisionChip('Pigmentation: $_breakoutPigmentation',
                      const Color(0xFF9B4DCA), isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisionChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSectionCard(
      _RecommendationSection section, bool isDark, int index) {
    final products = _productsForSection(section.title);
    final showProducts = [
      'MORNING ROUTINE',
      'EVENING ROUTINE',
      'POWER INGREDIENTS',
      'RETINOID ROADMAP'
    ].contains(section.title);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(opacity: value, child: child));
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: section.color.withValues(alpha: 0.3), width: 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    section.color.withValues(alpha: 0.08),
                    const Color(0xFF1e1e2e).withValues(alpha: 0.95)
                  ]
                : [
                    section.color.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.9)
                  ],
          ),
          boxShadow: [
            BoxShadow(
                color: section.color.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: section.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(section.icon, size: 16, color: section.color),
                  ),
                  const SizedBox(width: 10),
                  Text(section.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: section.color,
                          letterSpacing: 0.8)),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(
                section.content,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.75,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.88)
                        : Colors.black87),
              ),
              if (showProducts)
                _buildProductCards(products, section.color, isDark),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final sections = _tips.isNotEmpty
        ? _parseRecommendations(_tips)
        : <_RecommendationSection>[];

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0a0a1a) : const Color(0xFFF8F0FF),
      floatingActionButton: _skinColor.isNotEmpty && _skinColor != 'Error'
          ? ScaleTransition(
              scale: _pulse,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.deepPurple.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => SkinChatbot(
                        skinType: _skinType,
                        skinTone: _manualOverrideTone.isNotEmpty
                            ? _manualOverrideTone
                            : _skinColor,
                        currentRecommendations: _tips,
                      ),
                    );
                  },
                  backgroundColor: Colors.deepPurple,
                  elevation: 0,
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white),
                ),
              ),
            )
          : null,
      body: HolographicBackground(
        isDark: isDark,
        child: SafeArea(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFFB76EF5),
                                      const Color(0xFF6EE4F5),
                                      const Color(0xFFF56EB7)
                                    ]
                                  : [
                                      const Color(0xFF7B2FBE),
                                      const Color(0xFF2F7BBE),
                                      const Color(0xFFBE2F7B)
                                    ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: const Text(
                              'SkinForReal',
                              style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5),
                            ),
                          ),
                          Text(
                            'Know your skin. For real.',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black38,
                                letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      _ThemeToggle(
                          isDark: isDark,
                          onTap: () => themeProvider.toggleTheme()),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _GlowButton(
                          icon: Icons.upload_rounded,
                          label: 'Upload Photo',
                          onTap: () =>
                              _pickImageFromSource(ImageSource.gallery),
                          isDark: isDark,
                          glowColor: const Color(0xFF7B2FBE),
                          gradientColors: isDark
                              ? [
                                  const Color(0xFF2a1f3d),
                                  const Color(0xFF1a1a2e)
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.95),
                                  Colors.white.withValues(alpha: 0.75)
                                ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GlowButton(
                          icon: Icons.camera_alt_rounded,
                          label: 'Take Photo',
                          onTap: () => _pickImageFromSource(ImageSource.camera),
                          isDark: isDark,
                          glowColor: const Color(0xFF2F7BBE),
                          gradientColors: isDark
                              ? [
                                  const Color(0xFF1f2a3d),
                                  const Color(0xFF1a1a2e)
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.95),
                                  Colors.white.withValues(alpha: 0.75)
                                ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _GlowButton(
                    icon: Icons.calendar_month_rounded,
                    label: 'Track Skin Progress',
                    onTap: () {
                      Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const SkinProgressCalendar(),
                            transitionsBuilder: (_, animation, __, child) =>
                                FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                        begin: const Offset(0, 0.05),
                                        end: Offset.zero)
                                    .animate(animation),
                                child: child,
                              ),
                            ),
                          ));
                    },
                    isDark: isDark,
                    fullWidth: true,
                    glowColor: const Color(0xFF7B2FBE),
                    gradientColors: [
                      const Color(0xFF7B2FBE),
                      const Color(0xFF2F7BBE)
                    ],
                    textColor: Colors.white,
                    iconColor: Colors.white,
                  ),
                  const SizedBox(height: 28),
                  if (_imageFile != null)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: Opacity(
                            opacity: value.clamp(0.0, 1.0), child: child),
                      ),
                      child: FutureBuilder<dynamic>(
                        future:
                            _imageFile!.readAsBytes().then((bytes) => bytes),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                    maxHeight: 320, maxWidth: 420),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFF7B2FBE)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 40,
                                        offset: const Offset(0, 12)),
                                    BoxShadow(
                                        color: const Color(0xFF2F7BBE)
                                            .withValues(alpha: 0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6)),
                                  ],
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.3),
                                      width: 1.5),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.memory(snapshot.data!,
                                      fit: BoxFit.contain),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  if (_debugError.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Text(_debugError,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                  if (_skinColor.isNotEmpty && _skinColor != 'Error')
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.deepPurple.withValues(alpha: 0.25)),
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF2a2a3e)
                                        .withValues(alpha: 0.9),
                                    const Color(0xFF1e1e2e)
                                        .withValues(alpha: 0.9)
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.9),
                                    Colors.white.withValues(alpha: 0.7)
                                  ],
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _manualOverrideTone.isNotEmpty
                                ? _manualOverrideTone
                                : _skinColor,
                            isExpanded: true,
                            dropdownColor:
                                isDark ? const Color(0xFF2a2a3e) : Colors.white,
                            icon: const Icon(Icons.expand_more_rounded,
                                color: Colors.deepPurple),
                            items: _skinToneOptions.map((tone) {
                              return DropdownMenuItem<String>(
                                value: tone,
                                child: Text(tone,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87)),
                              );
                            }).toList(),
                            onChanged: _updateManualTone,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Column(
                        children: [
                          ScaleTransition(
                            scale: _pulse,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [
                                  Color(0xFF7B2FBE),
                                  Color(0xFF2F7BBE)
                                ]),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF7B2FBE)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 24,
                                      spreadRadius: 2)
                                ],
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF7B2FBE),
                                Color(0xFF2F7BBE),
                                Color(0xFFBE2F7B)
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'Analyzing your skin...',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Running vision analysis + building your routine',
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDark ? Colors.white38 : Colors.black38),
                          ),
                        ],
                      ),
                    )
                  else if (_skinColor.isNotEmpty && _skinColor != 'Error') ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Your Skin Analysis',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _QuickStat(
                            label: 'Skin Type',
                            value: _skinType,
                            color: const Color(0xFF4D7CCF),
                            isDark: isDark),
                        const SizedBox(width: 10),
                        _QuickStat(
                            label: 'Skin Tone',
                            value: _manualOverrideTone.isNotEmpty
                                ? _manualOverrideTone
                                : _skinColor,
                            color: const Color(0xFF9B4DCA),
                            isDark: isDark),
                        const SizedBox(width: 10),
                        _QuickStat(
                            label: 'Exposure',
                            value: _debugExposure.toStringAsFixed(2),
                            color: const Color(0xFF2FBEBE),
                            isDark: isDark),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFF2FBEBE).withValues(alpha: 0.1),
                        border: Border.all(
                            color:
                                const Color(0xFF2FBEBE).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insights_rounded,
                              size: 16, color: Color(0xFF2FBEBE)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _culpritMessage,
                              style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_breakoutSeverity.isNotEmpty)
                      _buildBreakoutCard(isDark),
                    const SizedBox(height: 4),
                    if (sections.isNotEmpty)
                      ...sections.asMap().entries.map((entry) =>
                          _buildSectionCard(entry.value, isDark, entry.key))
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: isDark
                              ? const Color(0xFF2a2a3e)
                              : Colors.white.withValues(alpha: 0.9),
                        ),
                        child: SelectableText(
                          _tips,
                          style: TextStyle(
                              fontSize: 14,
                              height: 1.7,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.88)
                                  : Colors.black87),
                        ),
                      ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _QuickStat(
      {required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    color.withValues(alpha: 0.08),
                    const Color(0xFF1e1e2e).withValues(alpha: 0.9)
                  ]
                : [
                    color.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.9)
                  ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeToggle({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => RotationTransition(
                turns: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                key: ValueKey(isDark),
                size: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                isDark ? 'Dark' : 'Light',
                key: ValueKey(isDark),
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool fullWidth;
  final List<Color> gradientColors;
  final Color? textColor;
  final Color? iconColor;
  final Color glowColor;

  const _GlowButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.glowColor,
    this.fullWidth = false,
    required this.gradientColors,
    this.textColor,
    this.iconColor,
  });

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelColor =
        widget.textColor ?? (widget.isDark ? Colors.white : Colors.black87);
    final iconColor = widget.iconColor ??
        (widget.isDark ? Colors.white70 : Colors.deepPurple);

    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) {
            setState(() => _pressed = pressed);
            pressed ? _controller.forward() : _controller.reverse();
          },
          borderRadius: BorderRadius.circular(18),
          splashColor: widget.glowColor.withValues(alpha: 0.3),
          highlightColor: widget.glowColor.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.gradientColors,
              ),
              border: Border.all(
                  color:
                      widget.glowColor.withValues(alpha: _pressed ? 0.6 : 0.2),
                  width: 1),
              boxShadow: [
                BoxShadow(
                  color:
                      widget.glowColor.withValues(alpha: _pressed ? 0.6 : 0.25),
                  blurRadius: _pressed ? 28 : 15,
                  spreadRadius: _pressed ? 2 : 0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 18, color: iconColor),
                const SizedBox(width: 10),
                Text(widget.label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                        fontSize: 14,
                        letterSpacing: 0.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
