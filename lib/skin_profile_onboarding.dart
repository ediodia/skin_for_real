import 'dart:math';
import 'dart:js' as js;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'onboarding_result_screen.dart';
import 'product_search_field.dart';
import 'welcome_back_screen.dart';

class SkinProfileOnboarding extends StatefulWidget {
  final User user;
  const SkinProfileOnboarding({super.key, required this.user});

  @override
  State<SkinProfileOnboarding> createState() => _SkinProfileOnboardingState();
}

class _SkinProfileOnboardingState extends State<SkinProfileOnboarding> with TickerProviderStateMixin {
  int _currentPage = 0;
  bool _saving = false;
  String? _skinType;
  final Set<String> _concerns = {};
  List<String> _amProducts = [];
  List<String> _pmProducts = [];
  late AnimationController _gradientController, _pulseController;
  late Animation<double> _pulse;

  final List<String> _skinTypes = ['Oily', 'Dry', 'Combination', 'Sensitive', 'Normal'];
  final List<(String, IconData, Color)> _concernsList = [
    ('Acne', Icons.warning_amber_rounded, const Color(0xFFFF4757)),
    ('Hyperpigmentation', Icons.circle_rounded, const Color(0xFF9B4DCA)),
    ('Dryness', Icons.water_drop_outlined, const Color(0xFF00D2FF)),
    ('Texture', Icons.grain_rounded, const Color(0xFFFF9F43)),
    ('Aging', Icons.hourglass_top_rounded, const Color(0xFF2ED573)),
    ('Redness', Icons.favorite_rounded, const Color(0xFFFF6B9D)),
  ];

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _gradientController.dispose(); _pulseController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) setState(() => _currentPage++);
  }

  void _prevPage() {
    if (_currentPage > 0) setState(() => _currentPage--);
  }

  Future<void> _saveAndFinish() async {
    debugPrint('_saveAndFinish called');
    setState(() => _saving = true);

    final skinProfile = {
      'skinType': _skinType,
      'concerns': _concerns.toList(),
      'amRoutine': _amProducts.join(', '),
      'pmRoutine': _pmProducts.join(', '),
      'completedAt': DateTime.now().toIso8601String(),
    };

    try {
      debugPrint('About to navigate to OnboardingResultScreen');
      if (mounted) {
        await Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => OnboardingResultScreen(
            user: widget.user,
            skinProfile: skinProfile,
          ),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ));
      }
      debugPrint('Navigation completed');
    } catch (e, stack) {
      debugPrint('Navigation error: $e');
      debugPrint('Stack: $stack');
      if (mounted) setState(() => _saving = false);
    }

    AuthService.saveSkinProfile(
      uid: widget.user.uid,
      skinProfile: skinProfile,
    );
  }

  Future<void> _skip() async {
    debugPrint('_skip called');
    setState(() => _saving = true);

    final skinProfile = {
      'skinType': _skinType != null && _skinType!.isNotEmpty ? _skinType : 'Unknown',
      'concerns': _concerns.toList(),
      'amRoutine': '',
      'pmRoutine': '',
      'skipped': true,
      'completedAt': DateTime.now().toIso8601String(),
    };

    try {
      if (mounted) {
        await Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => WelcomeBackScreen(user: widget.user),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ));
      }
    } catch (e, stack) {
      debugPrint('Skip navigation error: $e');
      debugPrint('Stack: $stack');
      if (mounted) setState(() => _saving = false);
    }

    AuthService.saveSkinProfile(
      uid: widget.user.uid,
      skinProfile: skinProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  Color.lerp(const Color(0xFF1a0533), const Color(0xFF0a1628), t)!,
                  Color.lerp(const Color(0xFF0d1f3c), const Color(0xFF1a0533), t)!,
                  Color.lerp(const Color(0xFF0f2027), const Color(0xFF120a1a), t)!,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(children: [
            _topBar(),
            _progressDots(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return _HolographicPageTransition(
                    animation: animation,
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_currentPage),
                  child: _currentPage == 0
                      ? _skinTypeScreen()
                      : _currentPage == 1
                          ? _concernsScreen()
                          : _routineScreen(),
                ),
              ),
            ),
            _bottomNav(),
          ]),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFFB76EF5), Color(0xFF6EE4F5), Color(0xFFF56EB7)]).createShader(bounds),
          child: const Text('SkinForReal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
        ),
        const Spacer(),
        if (_currentPage == 2)
          GestureDetector(
            onTap: _saving ? null : _skip,
            child: Text('Skip', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.35), fontWeight: FontWeight.w500)),
          ),
      ]),
    );
  }

  Widget _progressDots() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final active = i == _currentPage;
          final done = i < _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 28 : 8, height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: active || done ? const LinearGradient(colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)]) : null,
              color: (!active && !done) ? Colors.white.withValues(alpha: 0.15) : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _screenHeader(String title, String subtitle, IconData icon, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color, size: 22),
      ),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5, height: 1.2)),
      const SizedBox(height: 8),
      Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4), height: 1.5)),
    ]);
  }

  Widget _skinTypeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _screenHeader('What\'s your skin type?', 'We\'ll build your routine around this.', Icons.face_retouching_natural_rounded, const Color(0xFF9B4DCA)),
        const SizedBox(height: 28),
        ..._skinTypes.map((type) {
          final selected = _skinType == type;
          return GestureDetector(
            onTap: () {
              setState(() => _skinType = type);
              try { js.context.callMethod('sfr_soundSelect', []); } catch (_) {}
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? const Color(0xFF9B4DCA) : Colors.white.withValues(alpha: 0.1), width: selected ? 1.5 : 1),
                gradient: LinearGradient(colors: selected
                    ? [const Color(0xFF9B4DCA).withValues(alpha: 0.15), const Color(0xFF7B2FBE).withValues(alpha: 0.05)]
                    : [Colors.white.withValues(alpha: 0.04), Colors.white.withValues(alpha: 0.02)]),
                boxShadow: selected ? [BoxShadow(color: const Color(0xFF9B4DCA).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))] : [],
              ),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? const Color(0xFF9B4DCA) : Colors.white.withValues(alpha: 0.3), width: 1.5),
                    color: selected ? const Color(0xFF9B4DCA) : Colors.transparent,
                  ),
                  child: selected ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
                ),
                const SizedBox(width: 14),
                Text(type, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.white.withValues(alpha: 0.7))),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _concernsScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _screenHeader('What are your skin goals?', 'Pick up to 3 concerns to focus on.', Icons.track_changes_rounded, const Color(0xFF00D2FF)),
        const SizedBox(height: 28),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: _concernsList.map((c) {
            final (label, icon, color) = c;
            final selected = _concerns.contains(label);
            final atMax = _concerns.length >= 3 && !selected;
            return GestureDetector(
              onTap: atMax ? null : () {
                setState(() { selected ? _concerns.remove(label) : _concerns.add(label); });
                try { js.context.callMethod('sfr_soundSelect', []); } catch (_) {}
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? color : Colors.white.withValues(alpha: atMax ? 0.05 : 0.12), width: selected ? 1.5 : 1),
                  gradient: selected ? LinearGradient(colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.06)]) : null,
                  color: selected ? null : Colors.white.withValues(alpha: atMax ? 0.01 : 0.04),
                  boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 4))] : [],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 16, color: selected ? color : Colors.white.withValues(alpha: atMax ? 0.2 : 0.5)),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? color : Colors.white.withValues(alpha: atMax ? 0.2 : 0.65))),
                ]),
              ),
            );
          }).toList(),
        ),
        if (_concerns.length == 3)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text('Max 3 selected', style: TextStyle(fontSize: 12, color: const Color(0xFF00D2FF).withValues(alpha: 0.6))),
          ),
      ]),
    );
  }

  Widget _routineScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _screenHeader('What\'s your current routine?', 'Optional — helps us give better recommendations.', Icons.auto_awesome_rounded, const Color(0xFFFF9F43)),
        const SizedBox(height: 28),
        ProductSearchField(
          label: 'Morning Routine',
          icon: Icons.wb_sunny_rounded,
          color: const Color(0xFFFF9F43),
          selectedProducts: _amProducts,
          onChanged: (updated) => setState(() => _amProducts = updated),
        ),
        const SizedBox(height: 16),
        ProductSearchField(
          label: 'Evening Routine',
          icon: Icons.nightlight_round,
          color: const Color(0xFF5C5FED),
          selectedProducts: _pmProducts,
          onChanged: (updated) => setState(() => _pmProducts = updated),
        ),
      ]),
    );
  }

  Widget _bottomNav() {
    final isLastPage = _currentPage == 2;
    final canAdvance = _currentPage == 0 ? _skinType != null : _currentPage == 1 ? _concerns.isNotEmpty : true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Row(children: [
        if (_currentPage > 0) ...[
          GestureDetector(
            onTap: _prevPage,
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ScaleTransition(
            scale: _pulse,
            child: GestureDetector(
              onTap: (_saving || !canAdvance) ? null : (isLastPage ? _saveAndFinish : _nextPage),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: canAdvance ? const LinearGradient(colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)]) : null,
                  color: canAdvance ? null : Colors.white.withValues(alpha: 0.06),
                  boxShadow: canAdvance ? [BoxShadow(color: const Color(0xFF7B2FBE).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))] : [],
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          isLastPage ? 'Get My Routine' : 'Continue',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: canAdvance ? Colors.white : Colors.white.withValues(alpha: 0.25), letterSpacing: 0.2),
                        ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _HolographicPageTransition extends StatefulWidget {
  final Animation<double> animation;
  final Widget child;

  const _HolographicPageTransition({
    required this.animation,
    required this.child,
  });

  @override
  State<_HolographicPageTransition> createState() =>
      _HolographicPageTransitionState();
}

class _HolographicPageTransitionState extends State<_HolographicPageTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _glitchController;
  late Animation<double> _glitch;

  @override
  void initState() {
    super.initState();
    _glitchController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _glitch = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _glitchController, curve: Curves.easeOut));
    _glitchController.forward();
  }

  @override
  void dispose() {
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _glitchController]),
      builder: (context, child) {
        final t = widget.animation.value;
        final glitch = _glitch.value;

        return Stack(children: [
          Transform.translate(
            offset: Offset(0, 30 * (1 - t)),
            child: Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: child,
            ),
          ),
          if (glitch > 0.01)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _GlitchPainter(glitch)),
              ),
            ),
          if (t < 0.8)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _OrbParticlePainter(t)),
              ),
            ),
        ]);
      },
      child: widget.child,
    );
  }
}

class _GlitchPainter extends CustomPainter {
  final double progress;
  _GlitchPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final lineCount = (progress * 20).round();

    for (int i = 0; i < lineCount; i++) {
      final y = random.nextDouble() * size.height;
      final w = random.nextDouble() * size.width * 0.4;
      final x = random.nextDouble() * (size.width - w);
      final colors = [
        const Color(0xFF7B2FBE),
        const Color(0xFF2F7BBE),
        const Color(0xFF6EE4F5),
      ];
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: progress * 0.15)
        ..strokeWidth = 1.0 + random.nextDouble();
      canvas.drawLine(Offset(x, y), Offset(x + w, y), paint);
    }

    final scanY = size.height * (1 - progress);
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF6EE4F5).withValues(alpha: progress * 0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 2, size.width, 4));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 2, size.width, 4), scanPaint);
  }

  @override
  bool shouldRepaint(_GlitchPainter old) => old.progress != progress;
}

class _OrbParticlePainter extends CustomPainter {
  final double progress;
  _OrbParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(12);
    final colors = [
      const Color(0xFF7B2FBE),
      const Color(0xFF2F7BBE),
      const Color(0xFFBE2F7B),
      const Color(0xFF6EE4F5),
    ];

    for (int i = 0; i < 12; i++) {
      final startX = random.nextDouble() < 0.5 ? -20.0 : size.width + 20;
      final startY = random.nextDouble() * size.height;
      final endX = size.width * (0.2 + random.nextDouble() * 0.6);
      final endY = size.height * (0.2 + random.nextDouble() * 0.6);
      final t = (progress * 1.5 - random.nextDouble() * 0.3).clamp(0.0, 1.0);

      final x = startX + (endX - startX) * _easeOut(t);
      final y = startY + (endY - startY) * _easeOut(t);
      final opacity = (t * (1 - progress * 1.2)).clamp(0.0, 0.6);
      final radius = 2.0 + random.nextDouble() * 4;

      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  double _easeOut(double t) => 1 - pow(1 - t, 2).toDouble();

  @override
  bool shouldRepaint(_OrbParticlePainter old) => old.progress != progress;
}
