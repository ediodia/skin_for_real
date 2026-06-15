import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:js' as js;
import 'skin_profile_onboarding.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  final User user;
  const OnboardingWelcomeScreen({super.key, required this.user});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _gradientController;
  late AnimationController _pulseController;
  late AnimationController _textController;
  late Animation<double> _fadeIn;
  late Animation<double> _pulse;
  late Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _textSlide = CurvedAnimation(
        parent: _textController, curve: Curves.easeOutBack);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _gradientController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _startOnboarding() {
    try { js.context.callMethod('sfr_soundAdvance', []); } catch (_) {}
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => SkinProfileOnboarding(user: widget.user),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
              begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        widget.user.displayName?.split(' ').first ?? 'Beautiful';

    return Scaffold(
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
                  Color.lerp(const Color(0xFF1a0533),
                      const Color(0xFF0a1628), t)!,
                  Color.lerp(const Color(0xFF0d1f3c),
                      const Color(0xFF1a0533), t)!,
                  Color.lerp(const Color(0xFF0f2027),
                      const Color(0xFF120a1a), t)!,
                ],
              ),
            ),
            child: child,
          );
        },
        child: FadeTransition(
          opacity: _fadeIn,
          child: SafeArea(
            child: Stack(
              children: [
                ..._buildOrbs(),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Glowing avatar
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) => Container(
                            width: 100 + _pulse.value * 2,
                            height: 100 + _pulse.value * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF7B2FBE),
                                  Color(0xFF2F7BBE),
                                  Color(0xFFBE2F7B),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7B2FBE).withValues(
                                      alpha: 0.4 + _pulse.value * 0.15),
                                  blurRadius: 40 + _pulse.value * 10,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF2F7BBE)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: widget.user.photoURL != null
                                  ? Image.network(
                                      widget.user.photoURL!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.face_rounded,
                                              color: Colors.white, size: 44),
                                    )
                                  : const Icon(Icons.face_rounded,
                                      color: Colors.white, size: 44),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Animated welcome text
                        AnimatedBuilder(
                          animation: _textController,
                          builder: (_, __) => Transform.translate(
                            offset: Offset(0, 40 * (1 - _textSlide.value)),
                            child: Opacity(
                              opacity: _textSlide.value.clamp(0.0, 1.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Hey, $firstName 👋',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      colors: [
                                        Color(0xFFB76EF5),
                                        Color(0xFF6EE4F5),
                                        Color(0xFFF56EB7),
                                        Color(0xFFFFD93D),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ).createShader(bounds),
                                    child: const Text(
                                      'Welcome to\nSkinForReal ✨',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -1,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Let's get to know your skin.\nTakes less than 2 minutes. 🧬",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white.withValues(alpha: 0.45),
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 52),

                        // Feature pills
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _pill('🧬 AI Skin Analysis',
                                const Color(0xFF9B4DCA)),
                            _pill('☀️ Custom Routines',
                                const Color(0xFFFF9F43)),
                            _pill('💧 Ingredient Intel',
                                const Color(0xFF00D2FF)),
                            _pill('📈 Progress Tracking',
                                const Color(0xFF2ED573)),
                          ],
                        ),
                        const SizedBox(height: 52),

                        // CTA button
                        ScaleTransition(
                          scale: _pulse,
                          child: GestureDetector(
                            onTap: _startOnboarding,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7B2FBE),
                                    Color(0xFF2F7BBE),
                                    Color(0xFFBE2F7B),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7B2FBE)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 32,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Build My Skin Profile',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      )),
                                  SizedBox(width: 8),
                                  Text('→',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }

  List<Widget> _buildOrbs() {
    return [
      Positioned(
        top: -60,
        left: -60,
        child: AnimatedBuilder(
          animation: _gradientController,
          builder: (_, __) => Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF7B2FBE).withValues(
                    alpha: 0.15 + _gradientController.value * 0.05),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: -40,
        right: -40,
        child: AnimatedBuilder(
          animation: _gradientController,
          builder: (_, __) => Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFBE2F7B).withValues(
                    alpha: 0.12 + _gradientController.value * 0.05),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
    ];
  }
}
