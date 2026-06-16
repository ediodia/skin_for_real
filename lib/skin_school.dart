import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SkinSchoolScreen extends StatefulWidget {
  final String skinType;
  final List<String> concerns;
  const SkinSchoolScreen({super.key, required this.skinType, required this.concerns});

  @override
  State<SkinSchoolScreen> createState() => _SkinSchoolScreenState();
}

class _SkinSchoolScreenState extends State<SkinSchoolScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _fadeController;
  late AnimationController _scanController;
  late Animation<double> _fadeIn;
  late Animation<double> _scanLine;

  String? _aiLesson;
  bool _loadingLesson = false;
  int _expandedModule = -1;

  static const _proxyUrl =
      'https://us-central1-skinforreal-aa846.cloudfunctions.net/claudeProxy';

  final List<_LessonModule> _modules = const [
    _LessonModule(
      title: 'The Skin Barrier',
      subtitle: 'Your skin\'s first line of defense',
      icon: Icons.shield_rounded,
      color: Color(0xFF00D2FF),
      content:
          'The stratum corneum is a brick-and-mortar structure of corneocytes (bricks) held together by a lipid matrix of ceramides, cholesterol, and fatty acids (mortar). When this matrix is disrupted, moisture escapes and irritants enter.\n\nSigns of a compromised barrier: tightness after cleansing, new sensitivity to products you used to tolerate, redness, patchy dryness.\n\nRepair protocol: strip your routine to 3 steps (gentle cleanser → moisturizer with ceramides → SPF). Avoid all actives for 2 weeks. Look for products containing Ceramides NP, AP, and EOP alongside cholesterol and fatty acids — this specific ratio most closely mimics your skin\'s natural lipid profile.',
    ),
    _LessonModule(
      title: 'Acids 101',
      subtitle: 'AHAs, BHAs, and PHAs decoded',
      icon: Icons.science_rounded,
      color: Color(0xFF9B4DCA),
      content:
          'Chemical exfoliants work by loosening the bonds between dead skin cells. The key is matching acid type to skin concern.\n\nAHA (glycolic, lactic): Water-soluble. Works on skin surface. Best for dullness, texture, and hyperpigmentation. Glycolic penetrates deepest; lactic is gentler and also hydrating.\n\nBHA (salicylic acid): Oil-soluble, penetrates pores. Only exfoliant that works inside the follicle. Non-negotiable for acne-prone or congested skin. Use 0.5–2%.\n\nPHA (gluconolactone, lactobionic): Larger molecule, stays on surface. Best for reactive or rosacea-prone skin. All exfoliation benefits, minimal irritation.\n\nCritical rule: never use an acid and retinol on the same night. If stacking, apply the acid then wait 30 minutes before retinol.',
    ),
    _LessonModule(
      title: 'SPF Science',
      subtitle: 'The single most evidence-based step',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFFF9F43),
      content:
          'UV radiation accounts for up to 90% of visible skin aging (photoaging). UVA penetrates glass and causes collagen breakdown and pigmentation. UVB causes sunburn and directly damages DNA.\n\nSPF numbers: SPF 30 blocks 97% UVB. SPF 50 blocks 98%. The difference matters more if you\'re skipping reapplication.\n\nMineral (zinc oxide, titanium dioxide): Sits on skin, reflects UV, immediate protection, photostable, best for sensitive and acne-prone skin.\n\nChemical: Absorbed into skin, converts UV to heat, lighter texture. Some (avobenzone) degrade in sunlight — look for photostabilized formulas.\n\nApplication math: You need 2mg per cm² — roughly 1/4 teaspoon for face and neck. Most people apply 20–25% of the required amount. Reapply every 2 hours of sun exposure.',
    ),
    _LessonModule(
      title: 'Retinoid Roadmap',
      subtitle: 'Vitamin A — the gold standard',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFFFF6B9D),
      content:
          'Retinoids are the most clinically proven anti-aging ingredient class, with 40+ years of peer-reviewed research. They work by binding to nuclear receptors and upregulating collagen synthesis while increasing cell turnover.\n\nThe potency ladder (weakest → strongest):\nRetinyl palmitate → Retinol → Retinaldehyde → Tretinoin (Rx)\n\nHow to start: 0.025% retinol, two nights per week. Apply to dry skin after cleansing. Follow immediately with moisturizer. Increase frequency over 8–12 weeks. Always wear SPF the next morning — non-negotiable.\n\nPurging: 4–8 weeks of increased breakouts is expected as cell turnover accelerates. This is not a reaction — it\'s the process working. Stop only if you develop actual irritation (burning, peeling, dermatitis).',
    ),
    _LessonModule(
      title: 'Vitamin C Mastery',
      subtitle: 'Brighten, protect, and build collagen',
      icon: Icons.bolt_rounded,
      color: Color(0xFF2ED573),
      content:
          'L-ascorbic acid (pure Vitamin C) is an antioxidant that neutralizes free radicals, inhibits melanin synthesis, and stimulates collagen production. Clinical studies show 10–20% concentrations reduce fine lines and dark spots in 12 weeks.\n\nFormulation matters: LAA requires a pH below 3.5 to penetrate. At this pH, it\'s unstable — oxidizes within weeks of opening. Orange/brown discoloration = oxidized = no longer active. Store in a cool, dark place.\n\nStable alternatives: Ascorbyl glucoside (converts to LAA in skin, gentler, slower); Sodium ascorbyl phosphate (best for acne-prone, also antimicrobial); 3-O-Ethyl ascorbic acid (potent, stable, penetrates well).\n\nSynergy: Vitamin C + Vitamin E + Ferulic acid is the most evidence-backed antioxidant combination. This triple combination multiplies photoprotection 8x compared to Vitamin C alone.',
    ),
    _LessonModule(
      title: 'Hydration vs Moisture',
      subtitle: 'Two different systems, one goal',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF6EE4F5),
      content:
          'This distinction transforms how you build a routine. Hydration = water content. Moisture = oil/lipid content. Oily skin can be severely dehydrated. Dry skin can also lack both.\n\nHumectants (attract water): Hyaluronic acid, glycerin, aloe vera, urea, sodium PCA. Apply to damp skin — they pull moisture from environment. In very dry climates, seal immediately with an occlusive or they pull from deeper skin layers.\n\nEmollients (smooth and soften): Ceramides, squalane, fatty acids, niacinamide. Fill gaps between skin cells. Essential for barrier repair.\n\nOcclusives (lock it all in): Petrolatum (most effective), dimethicone, beeswax, shea butter. Create a physical barrier over skin. Use as final step, PM only if acne-prone.\n\nLayering rule: thinnest to thickest. Water-based → gel → serum → moisturizer → oil. Always apply humectants before emollients.',
    ),
    _LessonModule(
      title: 'Niacinamide Deep Dive',
      subtitle: 'The multitasker your routine needs',
      icon: Icons.stars_rounded,
      color: Color(0xFFFFD93D),
      content:
          'Niacinamide (Vitamin B3) is one of the most versatile and well-tolerated active ingredients. It works via multiple mechanisms simultaneously — a rarity in skincare.\n\nClinically proven benefits at specific concentrations:\n• 2–4%: Reduces sebum production, minimizes pore appearance\n• 4%: Fades hyperpigmentation (comparable to 4% hydroquinone in some studies)\n• 5%: Reduces barrier permeability, increases ceramide synthesis\n• 10%: Anti-inflammatory, reduces redness and acne frequency\n\nCompatibility: Niacinamide is compatible with nearly every other active. The old myth about mixing it with Vitamin C causing niacin flush is based on outdated science — modern formulations at pH 3–5 do not cause this reaction at standard concentrations.\n\nBest use: Morning or evening, any step after cleansing. If using 10%+ in a serum, apply before moisturizer.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _scanController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _fadeIn =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scanLine = CurvedAnimation(parent: _scanController, curve: Curves.linear);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _fadeController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _generatePersonalizedLesson() async {
    setState(() => _loadingLesson = true);
    try {
      final concernStr = widget.concerns.isNotEmpty
          ? ' and primary concerns: ${widget.concerns.join(', ')}'
          : '';
      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'max_tokens': 700,
          'messages': [
            {
              'role': 'user',
              'content':
                  'Write a hyper-personalized skincare science lesson for someone with ${widget.skinType} skin type$concernStr.\n\nFormat:\nLESSON: [title]\nSUBTITLE: [one line]\n\n[4 paragraphs of specific, actionable, evidence-based advice targeting their exact profile. Include ingredient percentages, mechanisms, and timing. Write like a dermatologist briefing a patient — precise, confident, no filler.]\n\nPOWER MOVE TODAY:\n[One specific action they can take right now]\n\nNo markdown. No asterisks. Plain text only.'
            }
          ],
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = (data['content'] as List?)
                ?.firstOrNull?['text'] as String? ??
            '';
        setState(() {
          _aiLesson = text.trim();
          _loadingLesson = false;
        });
      } else {
        setState(() => _loadingLesson = false);
      }
    } catch (_) {
      setState(() => _loadingLesson = false);
    }
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
                  Color.lerp(
                      const Color(0xFF1a0533), const Color(0xFF0a1628), t)!,
                  Color.lerp(
                      const Color(0xFF0d1f3c), const Color(0xFF1a0533), t)!,
                  Color.lerp(
                      const Color(0xFF0f2027), const Color(0xFF120a1a), t)!,
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
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    children: [
                      _buildPersonalizedCard(),
                      const SizedBox(height: 24),
                      _buildSectionLabel('CORE MODULES'),
                      const SizedBox(height: 12),
                      ..._modules.asMap().entries
                          .map((e) => _buildModuleCard(e.key, e.value)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(colors: [
                    Color(0xFFB76EF5),
                    Color(0xFF6EE4F5),
                    Color(0xFFF56EB7),
                  ]).createShader(b),
                  child: const Text('SKIN SCHOOL',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2.5)),
                ),
                Text('Evidence-based skincare science',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.35),
                        letterSpacing: 0.3)),
              ],
            ),
          ),
          if (widget.skinType.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                    colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)]),
              ),
              child: Text(widget.skinType,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(children: [
      Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.3),
              letterSpacing: 2)),
      const SizedBox(width: 10),
      Expanded(
          child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06))),
    ]);
  }

  Widget _buildPersonalizedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: const Color(0xFF7B2FBE).withValues(alpha: 0.45),
            width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7B2FBE).withValues(alpha: 0.14),
            const Color(0xFF2F7BBE).withValues(alpha: 0.07),
          ],
        ),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF7B2FBE).withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            AnimatedBuilder(
              animation: _scanController,
              builder: (_, __) => Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFF7B2FBE).withValues(alpha: 0.2),
                    const Color(0xFF2F7BBE).withValues(alpha: 0.2),
                    _scanLine.value,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFFB76EF5), size: 16),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI PERSONALIZED LESSON',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB76EF5),
                        letterSpacing: 1.2)),
                Text('Written for your exact skin profile',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white54)),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          if (_aiLesson != null)
            Text(_aiLesson!,
                style: const TextStyle(
                    fontSize: 13,
                    height: 1.75,
                    color: Colors.white,
                    fontWeight: FontWeight.w400))
          else
            Text(
              'Generate a lesson calibrated to ${widget.skinType.isNotEmpty ? widget.skinType.toLowerCase() : 'your'} skin${widget.concerns.isNotEmpty ? ' with ${widget.concerns.first.toLowerCase()} as your primary focus' : ''}.',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: 0.5)),
            ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadingLesson ? null : _generatePersonalizedLesson,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                    colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)]),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF7B2FBE).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Center(
                child: _loadingLesson
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        _aiLesson != null
                            ? 'Regenerate ↺'
                            : 'Generate My Lesson  ✦',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(int index, _LessonModule module) {
    final isExpanded = _expandedModule == index;
    return GestureDetector(
      onTap: () =>
          setState(() => _expandedModule = isExpanded ? -1 : index),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 280 + index * 55),
        curve: Curves.easeOutQuart,
        builder: (_, v, child) => Transform.translate(
          offset: Offset(0, 18 * (1 - v)),
          child: Opacity(opacity: v, child: child),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(isExpanded ? 18 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: module.color
                    .withValues(alpha: isExpanded ? 0.5 : 0.18),
                width: isExpanded ? 1.5 : 1),
            gradient: LinearGradient(colors: [
              module.color.withValues(alpha: isExpanded ? 0.12 : 0.05),
              const Color(0xFF1a1a2e).withValues(alpha: 0.95),
            ]),
            boxShadow: isExpanded
                ? [
                    BoxShadow(
                        color: module.color.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 5))
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: module.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(module.icon, size: 15, color: module.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(module.title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isExpanded
                                  ? module.color
                                  : Colors.white)),
                      Text(module.subtitle,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.38))),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 280),
                  child: Icon(Icons.expand_more_rounded,
                      color: module.color.withValues(alpha: 0.6),
                      size: 20),
                ),
              ]),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                height: 1,
                                color: module.color.withValues(alpha: 0.15)),
                            const SizedBox(height: 14),
                            Text(module.content,
                                style: TextStyle(
                                    fontSize: 13,
                                    height: 1.8,
                                    color: Colors.white
                                        .withValues(alpha: 0.85))),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String content;

  const _LessonModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.content,
  });
}
