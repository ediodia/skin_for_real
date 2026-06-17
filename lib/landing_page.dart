import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'sound_service.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  bool _signingIn = false;
  String? _errorMessage;
  bool _showEmailForm = false;
  bool _isSignUp = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _signingInMicrosoft = false;
  bool _obscurePassword = true;

  late AnimationController _g1, _g2, _g3, _fadeController, _pulseController;
  late Animation<double> _fadeIn, _pulse;

  @override
  void initState() {
    super.initState();
    _g1 = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _g2 = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat(reverse: true);
    _g3 = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _g1.dispose(); _g2.dispose(); _g3.dispose();
    _fadeController.dispose(); _pulseController.dispose();
    _emailController.dispose(); _passwordController.dispose(); _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() { _signingIn = true; _errorMessage = null; });
    try {
      final user = await AuthService.signInWithGoogle();
      if (user != null) {
        SoundService.success();
      } else if (mounted) {
        setState(() => _signingIn = false);
      }
    } catch (e) {
      SoundService.error();
      if (mounted) setState(() { _signingIn = false; _errorMessage = _friendlyError(e.toString()); });
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('popup-blocked')) return 'Popup was blocked. Allow popups for this site and try again.';
    if (raw.contains('network')) return 'Network error. Check your connection and try again.';
    return 'Sign-in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a1a),
      body: AnimatedBuilder(
        animation: Listenable.merge([_g1, _g2, _g3]),
        builder: (context, child) {
          final t1 = _g1.value; final t2 = _g2.value; final t3 = _g3.value;
          return Container(
            width: double.infinity, height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(t1 * 0.6 - 0.3, t2 * 0.6 - 0.3),
                end: Alignment(0.3 - t1 * 0.6, 0.3 - t2 * 0.6),
                colors: [
                  Color.lerp(const Color(0xFF1a0533), const Color(0xFF0a1628), t1)!,
                  Color.lerp(const Color(0xFF0d1f3c), const Color(0xFF1a0533), t2)!,
                  Color.lerp(const Color(0xFF0f2027), const Color(0xFF120a1a), t3)!,
                  Color.lerp(const Color(0xFF1a0533), const Color(0xFF0a1628), t1)!,
                ],
              ),
            ),
            child: Stack(children: [
              _orb(t1, 0.15, 0.2, 280, const Color(0xFF7B2FBE), 0.18),
              _orb(t2, 0.75, 0.15, 320, const Color(0xFF2F7BBE), 0.15),
              _orb(t3, 0.5, 0.7, 260, const Color(0xFFBE2F7B), 0.14),
              _orb(t1, 0.85, 0.75, 200, const Color(0xFF6EE4F5), 0.1),
              child!,
            ]),
          );
        },
        child: FadeTransition(
          opacity: _fadeIn,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _logoOrb(),
                      const SizedBox(height: 32),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFB76EF5), Color(0xFF6EE4F5), Color(0xFFF56EB7)],
                        ).createShader(bounds),
                        child: const Text('SkinForReal', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
                      ),
                      const SizedBox(height: 10),
                      Text('Know your skin. For real.', style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.45), letterSpacing: 0.5)),
                      const SizedBox(height: 48),
                      _featurePills(),
                      const SizedBox(height: 48),
                      ScaleTransition(scale: _pulse, child: _googleButton()),
                      const SizedBox(height: 12),
                      _microsoftButton(),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or', style: TextStyle(
                            fontSize: 12, color: Colors.white.withValues(alpha: 0.3))),
                        ),
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                      ]),
                      const SizedBox(height: 12),
                      if (!_showEmailForm)
                        GestureDetector(
                          onTap: () => setState(() => _showEmailForm = true),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                              color: Colors.white.withValues(alpha: 0.04),
                            ),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.email_rounded,
                                size: 18, color: Colors.white.withValues(alpha: 0.6)),
                              const SizedBox(width: 10),
                              Text('Continue with Email',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.6))),
                            ]),
                          ),
                        )
                      else
                        _emailForm(),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4757).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFF4757).withValues(alpha: 0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFFF4757)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_errorMessage!, style: const TextStyle(fontSize: 13, color: Color(0xFFFF4757)))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 36),
                      Text(
                        'Your skin data stays yours.\nWe never sell or share your information.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.25), height: 1.6),
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

  Widget _orb(double t, double xf, double yf, double size, Color color, double opacity) {
    final s = MediaQuery.of(context).size;
    return Positioned(
      left: s.width * xf + t * 40 - 20,
      top: s.height * yf + t * 30 - 15,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withValues(alpha: opacity), Colors.transparent]),
        ),
      ),
    );
  }

  Widget _logoOrb() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) => Container(
        width: 88, height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)]),
          boxShadow: [
            BoxShadow(color: const Color(0xFF7B2FBE).withValues(alpha: 0.3 + _pulse.value * 0.2), blurRadius: 32 + _pulse.value * 8, spreadRadius: 2),
            BoxShadow(color: const Color(0xFF2F7BBE).withValues(alpha: 0.2), blurRadius: 20),
          ],
        ),
        child: ClipOval(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE), Color(0xFFBE2F7B)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Image.asset('assets/skinfr_logo.png', color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featurePills() {
    final features = [
      (Icons.biotech_rounded, 'AI Face Analysis', const Color(0xFF9B4DCA)),
      (Icons.wb_sunny_rounded, 'Personalized Routines', const Color(0xFFFF9F43)),
      (Icons.trending_up_rounded, 'Skin Progress Tracking', const Color(0xFF2ED573)),
      (Icons.auto_awesome_rounded, 'Ingredient Insights', const Color(0xFF00D2FF)),
    ];
    return Wrap(
      spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
      children: features.map((f) {
        final (icon, label, color) = f;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ]),
        );
      }).toList(),
    );
  }

  Widget _googleButton() {
    return GestureDetector(
      onTap: _signingIn ? null : _handleGoogleSignIn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _signingIn ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: _signingIn ? 0.1 : 0.2)),
          boxShadow: _signingIn ? [] : [BoxShadow(color: const Color(0xFF7B2FBE).withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: _signingIn
            ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 22, height: 22,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Center(child: Text('G', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4285F4), height: 1))),
                ),
                const SizedBox(width: 12),
                const Text('Continue with Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.2)),
              ]),
      ),
    );
  }


  Widget _microsoftButton() {
    return GestureDetector(
      onTap: _signingInMicrosoft ? null : _handleMicrosoftSignIn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _signingInMicrosoft
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: _signingInMicrosoft
            ? const Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 22, height: 22,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Center(child: Text('M',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                      color: Color(0xFF00A4EF), height: 1))),
                ),
                const SizedBox(width: 12),
                Text('Continue with Microsoft',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7))),
              ]),
      ),
    );
  }

  Future<void> _handleMicrosoftSignIn() async {
    setState(() { _signingInMicrosoft = true; _errorMessage = null; });
    try {
      final user = await AuthService.signInWithMicrosoft();
      if (user != null) {
        SoundService.success();
      } else if (mounted) {
        setState(() => _signingInMicrosoft = false);
      }
    } catch (e) {
      SoundService.error();
      if (mounted) {
        setState(() {
          _signingInMicrosoft = false;
          _errorMessage = _friendlyError(e.toString());
        });
      }
    }
  }

  Widget _emailForm() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        GestureDetector(
          onTap: () => setState(() => _isSignUp = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: !_isSignUp ? const Color(0xFF7B2FBE).withValues(alpha: 0.2) : Colors.transparent,
              border: Border.all(color: !_isSignUp ? const Color(0xFF7B2FBE) : Colors.transparent),
            ),
            child: Text('Sign In',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: !_isSignUp ? const Color(0xFFB76EF5) : Colors.white38)),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _isSignUp = true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _isSignUp ? const Color(0xFF7B2FBE).withValues(alpha: 0.2) : Colors.transparent,
              border: Border.all(color: _isSignUp ? const Color(0xFF7B2FBE) : Colors.transparent),
            ),
            child: Text('Sign Up',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: _isSignUp ? const Color(0xFFB76EF5) : Colors.white38)),
          ),
        ),
      ]),
      const SizedBox(height: 16),
      if (_isSignUp) _inputField(_nameController, 'Full Name', Icons.person_rounded, false),
      if (_isSignUp) const SizedBox(height: 10),
      _inputField(_emailController, 'Email', Icons.email_rounded, false),
      const SizedBox(height: 10),
      _inputField(_passwordController, 'Password', Icons.lock_rounded, true),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: _signingIn ? null : _handleEmailAuth,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)]),
            boxShadow: [BoxShadow(
              color: const Color(0xFF7B2FBE).withValues(alpha: 0.4),
              blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: _signingIn
              ? const Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
              : Center(child: Text(_isSignUp ? 'Create Account' : 'Sign In',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
        ),
      ),
      if (!_isSignUp) ...[
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            if (_emailController.text.trim().isNotEmpty) {
              await AuthService.resetPassword(_emailController.text.trim());
              if (mounted) setState(() => _errorMessage = 'Password reset email sent.');
            }
          },
          child: Text('Forgot password?',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.3))),
        ),
      ],
    ]);
  }

  Widget _inputField(TextEditingController controller, String hint,
      IconData icon, bool isPassword) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 18),
          suffixIcon: isPassword ? GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: Colors.white.withValues(alpha: 0.3), size: 18),
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _handleEmailAuth() async {
    setState(() { _signingIn = true; _errorMessage = null; });
    try {
      if (_isSignUp) {
        await AuthService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
        );
      } else {
        await AuthService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      if (mounted) { setState(() => _signingIn = false); }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _signingIn = false;
          _errorMessage = _friendlyFirebaseError(e.code);
        });
      }
    }
  }

  String _friendlyFirebaseError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with that email.';
      case 'wrong-password': return 'Incorrect password. Try again.';
      case 'email-already-in-use': return 'An account already exists with that email.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'invalid-email': return 'Please enter a valid email address.';
      default: return 'Sign-in failed. Please try again.';
    }
  }
}
