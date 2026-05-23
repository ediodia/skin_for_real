import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'face_api_service.dart';
import 'theme_provider.dart';
import 'calendar.dart';

void main() {
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
      theme: ThemeData(brightness: Brightness.light, fontFamily: 'San Francisco'),
      darkTheme: ThemeData(brightness: Brightness.dark, fontFamily: 'San Francisco'),
      home: const SkinAnalyzer(),
    );
  }
}

class SkinAnalyzer extends StatefulWidget {
  const SkinAnalyzer({super.key});

  @override
  State<SkinAnalyzer> createState() => _SkinAnalyzerState();
}

class _SkinAnalyzerState extends State<SkinAnalyzer> with TickerProviderStateMixin {
  XFile? _imageFile;
  String _skinColor = '';
  String _skinType = '';
  String _tips = '';
  String _culpritMessage = '';
  String _manualOverrideTone = '';
  String _lastSkinType = '';
  bool _loading = false;
  String _debugError = '';

  final ScrollController _scrollController = ScrollController();
  final List<String> _skinToneOptions = ['Light', 'Medium', 'Tan/Olive', 'Brown', 'Deep/Dark'];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _loadTonePreference();
  }

  Future<void> _loadTonePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final tone = prefs.getString('manual_override_tone');
    if (tone != null && _skinToneOptions.contains(tone)) {
      setState(() => _manualOverrideTone = tone);
    }
  }

  Future<void> _saveTonePreference(String tone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('manual_override_tone', tone);
  }

  String _cleanText(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll(RegExp(r'[^\x00-\x7F\n\r\t ]'), '');
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Flash Disclaimer", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("If you're using flash or your environment is bright, your skin tone might appear lighter than usual. Adjust using the dropdown after upload."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it!", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    ).then((_) async {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _skinColor = '';
          _skinType = '';
          _tips = '';
          _culpritMessage = '';
          _debugError = '';
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
      final tone = FaceApiService.estimateSkinColorLabel(attributes);
      final type = FaceApiService.detectSkinType(attributes);
      final selectedTone = _manualOverrideTone.isNotEmpty ? _manualOverrideTone : tone;
      final tips = await FaceApiService.getAIRecommendations(type, selectedTone);

      final prefs = await SharedPreferences.getInstance();
      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString('progress_$dateStr', type);
      await prefs.setString('log_$dateStr', jsonEncode({'type': type, 'color': selectedTone, 'tips': tips}));

      setState(() {
        _skinColor = tone;
        _skinType = type;
        _tips = _cleanText(tips);
        _culpritMessage = FaceApiService.suggestCulprit(_lastSkinType, type);
        _lastSkinType = type;
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
    final newTips = await FaceApiService.getAIRecommendations(_skinType, tone);
    setState(() {
      _tips = _cleanText(newTips);
      _loading = false;
    });
    _fadeController.forward(from: 0);
  }

  Widget _buildInfoCard(String title, String content, Color textColor, {IconData? icon, Color? accentColor}) {
    return SlideTransition(
      position: _slideIn,
      child: FadeTransition(
        opacity: _fadeIn,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: (accentColor ?? Colors.deepPurple).withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
            border: Border.all(color: (accentColor ?? Colors.deepPurple).withValues(alpha: 0.15), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (accentColor ?? Colors.deepPurple).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 16, color: accentColor ?? Colors.deepPurple),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor ?? Colors.deepPurple)),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(content, style: TextStyle(fontSize: 14, height: 1.6, color: textColor)),
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
    final textColor = isDark ? Colors.white : Colors.black87;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0f3460) : const Color(0xFFD5ECF5),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFFDEBFF), Color(0xFFE1D8FF), Color(0xFFD5ECF5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: SafeArea(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
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
                          Text('SkinForReal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.deepPurple.shade800)),
                          Text('AI-powered skin analysis', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.deepPurple.shade300)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => themeProvider.toggleTheme(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.deepPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, size: 14, color: isDark ? Colors.white70 : Colors.deepPurple),
                              const SizedBox(width: 6),
                              Text(isDark ? 'Dark' : 'Light', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.deepPurple)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.upload_rounded,
                          label: 'Upload Photo',
                          onTap: () => _pickImageFromSource(ImageSource.gallery),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.camera_alt_rounded,
                          label: 'Take Photo',
                          onTap: () => _pickImageFromSource(ImageSource.camera),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const SkinProgressCalendar(),
                          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
                        ));
                      },
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: const Text('Track Skin Progress', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_imageFile != null)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                      child: FutureBuilder<dynamic>(
                        future: _imageFile!.readAsBytes().then((bytes) => bytes),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Container(
                              height: 260,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Text('Debug: $_debugError', style: const TextStyle(fontSize: 12, color: Colors.red)),
                    ),

                  if (_skinColor.isNotEmpty && _skinColor != 'Error')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _manualOverrideTone.isNotEmpty ? _manualOverrideTone : _skinColor,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.deepPurple),
                            items: _skinToneOptions.map((tone) {
                              return DropdownMenuItem<String>(
                                value: tone,
                                child: Text(tone, style: const TextStyle(fontWeight: FontWeight.w500)),
                              );
                            }).toList(),
                            onChanged: _updateManualTone,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          ScaleTransition(
                            scale: _pulse,
                            child: const CircularProgressIndicator(color: Colors.deepPurple, strokeWidth: 3),
                          ),
                          const SizedBox(height: 16),
                          Text('Analyzing your skin...', style: TextStyle(color: isDark ? Colors.white60 : Colors.deepPurple.shade300, fontSize: 14)),
                        ],
                      ),
                    )
                  else if (_skinColor.isNotEmpty && _skinColor != 'Error')
                    Column(
                      children: [
                        _buildInfoCard('Skin Tone', _manualOverrideTone.isNotEmpty ? _manualOverrideTone : _skinColor, textColor, icon: Icons.palette_rounded, accentColor: Colors.purple),
                        _buildInfoCard('Skin Type', _skinType, textColor, icon: Icons.face_rounded, accentColor: Colors.indigo),
                        _buildInfoCard('AI Recommendations', _tips, textColor, icon: Icons.auto_awesome_rounded, accentColor: Colors.deepPurple),
                        _buildInfoCard('Trend Check', _culpritMessage, textColor, icon: Icons.trending_up_rounded, accentColor: Colors.teal),
                      ],
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({required this.icon, required this.label, required this.onTap, required this.isDark});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.white12 : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 18, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.deepPurple, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}