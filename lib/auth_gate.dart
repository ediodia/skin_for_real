import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'landing_page.dart';
import 'skin_profile_onboarding.dart';
import 'onboarding_welcome_screen.dart';
import 'main.dart';
import 'welcome_back_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        final user = authSnapshot.data;
        if (user == null) return const LandingPage();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: AuthService.userDocStream(user.uid),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const _SplashScreen();
            }
            if (docSnapshot.hasError) {
              return SkinProfileOnboarding(user: user);
            }
            if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
              Future.microtask(() => AuthService.getOrCreateUserDocument(user));
              return SkinProfileOnboarding(user: user);
            }
            final data = docSnapshot.data!.data() ?? {};
            final skinProfile = data['skinProfile'];
            if (skinProfile == null) return OnboardingWelcomeScreen(user: user);
            final completed = skinProfile['completedAt'] != null ||
                skinProfile['skipped'] == true;
            if (!completed) return SkinProfileOnboarding(user: user);
            return WelcomeBackScreen(user: user);
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    // Safety timeout — force sign out so user lands on LandingPage
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) AuthService.signOut();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a1a),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)]),
                  boxShadow: [BoxShadow(
                      color: const Color(0xFF7B2FBE).withValues(alpha: 0.5),
                      blurRadius: 28, spreadRadius: 2)],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFB76EF5), Color(0xFF6EE4F5), Color(0xFFF56EB7)],
              ).createShader(bounds),
              child: const Text('SkinForReal',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
