import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'main.dart';
import 'shatter_transition.dart';

class WelcomeBackScreen extends StatefulWidget {
  final User user;
  const WelcomeBackScreen({super.key, required this.user});

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _gradientController;
  late Animation<double> _fadeIn;
  late Animation<double> _pulse;
  final ShatterController _shatterController = ShatterController();

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    await _shatterController.trigger();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.user.displayName?.split(' ').first ?? 'you';
    final photoUrl = widget.user.photoURL;

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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) => Container(
                            width: 110 + _pulse.value * 4,
                            height: 110 + _pulse.value * 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF7B2FBE)
                                      .withValues(alpha: 0.3 + _pulse.value * 0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B2FBE).withValues(alpha: 0.5),
                                blurRadius: 28, spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: photoUrl != null
                                ? Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (_, child, progress) =>
                                        progress == null
                                            ? child
                                            : const Icon(Icons.person_rounded,
                                                color: Colors.white, size: 40),
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person_rounded,
                                        color: Colors.white, size: 40),
                                  )
                                : const Icon(Icons.person_rounded,
                                    color: Colors.white, size: 40),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFB76EF5), Color(0xFF6EE4F5), Color(0xFFF56EB7)],
                      ).createShader(bounds),
                      child: Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFB76EF5), Color(0xFF6EE4F5), Color(0xFFF56EB7)],
                      ).createShader(bounds),
                      child: Text(
                        firstName,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ready to check in with your skin?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.4),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 56),
                    ScaleTransition(
                      scale: _pulse,
                      child: GestureDetector(
                        onTap: _continue,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B2FBE).withValues(alpha: 0.5),
                                blurRadius: 28, offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Let's dive in ✨",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async => await AuthService.signOut(),
                      child: Text(
                        'Not $firstName? Sign out',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
