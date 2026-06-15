import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'calendar.dart';

class ProfileHub extends StatefulWidget {
  final Map<String, dynamic>? preloadedData;
  const ProfileHub({super.key, this.preloadedData});

  @override
  State<ProfileHub> createState() => _ProfileHubState();
}

class _ProfileHubState extends State<ProfileHub>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideIn;
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slideIn = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeOutCubic));
    _slideController.forward();

    if (widget.preloadedData != null) {
      _userData = widget.preloadedData;
      _loading = false;
    } else {
      _loadUserData();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    final doc = await AuthService.getUserDoc(user.uid);
    if (mounted) {
      setState(() {
        _userData = doc.data();
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _slideController.reverse();
    await AuthService.signOut();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return SlideTransition(
      position: _slideIn,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a0533).withValues(alpha: 0.98),
              const Color(0xFF0d1f3c).withValues(alpha: 0.98),
              const Color(0xFF0a0a1a).withValues(alpha: 0.98),
            ],
          ),
          border: Border(
            left: BorderSide(
              color: const Color(0xFF7B2FBE).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2FBE).withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(-10, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7B2FBE)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () async {
                            await _slideController.reverse();
                            if (mounted) Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white70, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7B2FBE)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: user?.photoURL != null
                                    ? Image.network(user!.photoURL!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.person_rounded,
                                                color: Colors.white, size: 36))
                                    : const Icon(Icons.person_rounded,
                                        color: Colors.white, size: 36),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFB76EF5),
                                  Color(0xFF6EE4F5),
                                  Color(0xFFF56EB7)
                                ],
                              ).createShader(bounds),
                              child: Text(
                                user?.displayName ?? 'Skin Lover',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          _statCard(
                              'Streak',
                              '${_userData?['streak'] ?? 0} days',
                              Icons.local_fire_department_rounded,
                              const Color(0xFFFF9F43)),
                          const SizedBox(width: 12),
                          _statCard(
                              'Check-ins',
                              '${_userData?['totalCheckIns'] ?? 0}',
                              Icons.check_circle_rounded,
                              const Color(0xFF2ED573)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_userData?['skinProfile'] != null) ...[
                        _sectionLabel('Your Skin Profile'),
                        const SizedBox(height: 12),
                        _profileCard(),
                        const SizedBox(height: 24),
                      ],
                      _sectionLabel('Account'),
                      const SizedBox(height: 12),
                      _menuItem(
                        Icons.calendar_month_rounded,
                        'Skin Progress',
                        'View your skin journey',
                        const Color(0xFF9B4DCA),
                        () async {
                          await _slideController.reverse();
                          if (mounted) {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  const SkinProgressCalendar(),
                              transitionsBuilder: (_, animation, __, child) =>
                                  FadeTransition(
                                      opacity: animation, child: child),
                            ));
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _menuItem(
                        Icons.edit_rounded,
                        'Edit Skin Profile',
                        'Update your skin type and concerns',
                        const Color(0xFF00D2FF),
                        () async {
                          await _slideController.reverse();
                          if (mounted) {
                            Navigator.of(context).pop();
                            final user = AuthService.currentUser;
                            if (user != null) {
                              await AuthService.saveSkinProfile(
                                uid: user.uid,
                                skinProfile: {
                                  'skinType': null,
                                  'concerns': [],
                                  'amRoutine': '',
                                  'pmRoutine': '',
                                  'completedAt': null,
                                },
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _menuItem(
                        Icons.notifications_rounded,
                        'Reminders',
                        'Coming soon',
                        const Color(0xFFFF9F43),
                        () {},
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: _signOut,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFFF4757).withValues(alpha: 0.3),
                            ),
                            color: const Color(0xFFFF4757).withValues(alpha: 0.06),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded,
                                  color: Color(0xFFFF4757), size: 16),
                              SizedBox(width: 8),
                              Text('Sign Out',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFF4757),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'SkinForReal v1.0',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.15),
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

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.08),
              const Color(0xFF0a0a1a).withValues(alpha: 0.5),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.3),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _profileCard() {
    final profile = Map<String, dynamic>.from(_userData!['skinProfile'] as Map);
    final skinType = profile['skinType'] ?? 'Unknown';
    final concerns = (profile['concerns'] as List?)?.cast<String>() ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF7B2FBE).withValues(alpha: 0.25)),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7B2FBE).withValues(alpha: 0.08),
            const Color(0xFF0a0a1a).withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.face_retouching_natural_rounded,
                  color: Color(0xFF9B4DCA), size: 16),
              const SizedBox(width: 8),
              Text('Skin Type: $skinType',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
          if (concerns.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: concerns
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color:
                              const Color(0xFF7B2FBE).withValues(alpha: 0.15),
                          border: Border.all(
                              color: const Color(0xFF7B2FBE)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Text(c,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFB76EF5),
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.35))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.2), size: 18),
          ],
        ),
      ),
    );
  }
}
