// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'landing_page.dart';
import 'main.dart';
import 'skin_profile_onboarding.dart';
import 'onboarding_welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _calledReady = false;

  void _signalReady() {
    if (_calledReady) return;
    _calledReady = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        js.context.callMethod('sfr_appReady', []);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _BlankScreen();
        }
        final user = authSnapshot.data;
        if (user == null) {
          _signalReady();
          return const LandingPage();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: AuthService.userDocStream(user.uid),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const _BlankScreen();
            }
            if (docSnapshot.hasError) {
              _signalReady();
              return SkinProfileOnboarding(user: user);
            }
            if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
              Future.microtask(() => AuthService.getOrCreateUserDocument(user));
              _signalReady();
              return SkinProfileOnboarding(user: user);
            }
            final data = docSnapshot.data!.data() ?? {};
            final skinProfile = data['skinProfile'];
            _signalReady();
            if (skinProfile == null) return OnboardingWelcomeScreen(user: user);
            final completed = skinProfile['completedAt'] != null ||
                skinProfile['skipped'] == true ||
                skinProfile['aiPlan'] != null;
            if (!completed) return SkinProfileOnboarding(user: user);
            return const SkinAnalyzer();
          },
        );
      },
    );
  }
}

class _BlankScreen extends StatelessWidget {
  const _BlankScreen();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: Color(0xFF0a0a1a));
}
