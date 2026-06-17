import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'sound_service.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen>
    with TickerProviderStateMixin {
  String _filter = 'All';
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeIn;

  static const _skinTypes = ['All', 'Oily', 'Dry', 'Combination', 'Sensitive', 'Normal'];
  static const _categories = ['Tip', 'Question', 'Progress', 'Review'];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _stream {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('community_posts')
        .orderBy('timestamp', descending: true)
        .limit(60);
    if (_filter != 'All') {
      q = q.where('skinType', isEqualTo: _filter);
    }
    return q.snapshots();
  }

  Future<void> _toggleLike(String docId, List likes) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    SoundService.tap();
    final ref = FirebaseFirestore.instance.collection('community_posts').doc(docId);
    if (likes.contains(uid)) {
      await ref.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await ref.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  void _showPostDialog() {
    final textCtrl = TextEditingController();
    String selectedCategory = 'Tip';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1a0533), Color(0xFF0d1f3c), Color(0xFF0a0a1a)],
              ),
              border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFB76EF5), Color(0xFF6EE4F5)],
                  ).createShader(b),
                  child: const Text('Share with the Community',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(height: 6),
                Text('What\'s on your skin journey?',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _categories.map((cat) {
                    final selected = cat == selectedCategory;
                    return GestureDetector(
                      onTap: () { SoundService.tap(); setModal(() => selectedCategory = cat); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: selected
                              ? const Color(0xFF7B2FBE)
                              : const Color(0xFF7B2FBE).withValues(alpha: 0.1),
                          border: Border.all(
                              color: const Color(0xFF7B2FBE).withValues(alpha: selected ? 0 : 0.3)),
                        ),
                        child: Text(cat,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : const Color(0xFFB76EF5))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    controller: textCtrl,
                    maxLines: 4,
                    maxLength: 280,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                    decoration: InputDecoration(
                      hintText: selectedCategory == 'Tip'
                          ? 'Share a skin tip that\'s been working for you...'
                          : selectedCategory == 'Question'
                              ? 'Ask the community something about skincare...'
                              : selectedCategory == 'Progress'
                                  ? 'How has your skin been this week?'
                                  : 'Review a product you\'ve been using...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () async {
                      final text = textCtrl.text.trim();
                      if (text.isEmpty) return;
                      SoundService.success();
                      final user = AuthService.currentUser;
                      if (user == null) return;
                      final userDoc = await AuthService.getUserDoc(user.uid);
                      final data = userDoc.data() ?? {};
                      final skinProfile = data['skinProfile'] as Map?;
                      final skinType = skinProfile?['skinType'] as String? ?? 'Unknown';
                      await FirebaseFirestore.instance.collection('community_posts').add({
                        'uid': user.uid,
                        'displayName': user.displayName ?? 'Skin Lover',
                        'photoURL': user.photoURL,
                        'skinType': skinType,
                        'text': text,
                        'category': selectedCategory,
                        'timestamp': FieldValue.serverTimestamp(),
                        'likes': <String>[],
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)]),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text('Post to Community',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser?.uid ?? '';

    return FadeTransition(
      opacity: _fadeIn,
      child: Scaffold(
        backgroundColor: const Color(0xFF0a0a1a),
        floatingActionButton: GestureDetector(
          onTap: _showPostDialog,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)]),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF7B2FBE).withValues(alpha: 0.5),
                    blurRadius: 20, spreadRadius: 2)
              ],
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 130,
              pinned: true,
              backgroundColor: const Color(0xFF0a0a1a),
              leading: GestureDetector(
                onTap: () { SoundService.tap(); Navigator.pop(context); },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 18),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                title: ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFB76EF5), Color(0xFF6EE4F5), Color(0xFFF56EB7)],
                  ).createShader(b),
                  child: const Text('Community',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5)),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1a0533), Color(0xFF0a0a1a)],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _skinTypes.map((type) {
                      final active = type == _filter;
                      return GestureDetector(
                        onTap: () {
                          SoundService.tap();
                          setState(() => _filter = type);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: active
                                ? const LinearGradient(
                                    colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)])
                                : null,
                            color: active ? null : Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                                color: active
                                    ? Colors.transparent
                                    : Colors.white.withValues(alpha: 0.12)),
                            boxShadow: active
                                ? [BoxShadow(
                                    color: const Color(0xFF7B2FBE).withValues(alpha: 0.4),
                                    blurRadius: 12)]
                                : null,
                          ),
                          child: Text(type,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: active ? Colors.white : Colors.white54)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7B2FBE), strokeWidth: 2),
                    ),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 16),
                          Text('Be the first to post!',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.5))),
                          const SizedBox(height: 8),
                          Text('Share a skin tip or question with the community.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.3)),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final doc = docs[i];
                        final data = doc.data();
                        return _PostCard(
                          docId: doc.id,
                          data: data,
                          uid: uid,
                          index: i,
                          onLike: () => _toggleLike(doc.id, List.from(data['likes'] ?? [])),
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String uid;
  final int index;
  final VoidCallback onLike;

  const _PostCard({
    required this.docId,
    required this.data,
    required this.uid,
    required this.index,
    required this.onLike,
  });

  static const _categoryColors = {
    'Tip': Color(0xFF2ED573),
    'Question': Color(0xFF00D2FF),
    'Progress': Color(0xFF9B4DCA),
    'Review': Color(0xFFFF9F43),
  };

  @override
  Widget build(BuildContext context) {
    final likes = List<String>.from(data['likes'] ?? []);
    final liked = likes.contains(uid);
    final category = data['category'] as String? ?? 'Tip';
    final accent = _categoryColors[category] ?? const Color(0xFF9B4DCA);
    final ts = data['timestamp'] as Timestamp?;
    final timeAgo = ts != null ? _formatTime(ts.toDate()) : '';
    final photo = data['photoURL'] as String?;
    final skinType = data['skinType'] as String? ?? '';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOutQuart,
      builder: (_, v, child) =>
          Transform.translate(offset: Offset(0, 20 * (1 - v)), child: Opacity(opacity: v, child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
          gradient: LinearGradient(colors: [
            accent.withValues(alpha: 0.06),
            const Color(0xFF1e1e2e).withValues(alpha: 0.9),
          ]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Color(0xFF7B2FBE), Color(0xFF2F7BBE)]),
                  ),
                  child: ClipOval(
                    child: photo != null
                        ? Image.network(photo, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person_rounded, color: Colors.white, size: 18))
                        : const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['displayName'] as String? ?? 'Skin Lover',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      Row(
                        children: [
                          if (skinType.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: accent.withValues(alpha: 0.15),
                              ),
                              child: Text(skinType,
                                  style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(timeAgo,
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: accent.withValues(alpha: 0.15),
                    border: Border.all(color: accent.withValues(alpha: 0.25)),
                  ),
                  child: Text(category,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(data['text'] as String? ?? '',
                style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.white.withValues(alpha: 0.88))),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: liked
                          ? const Color(0xFFFF6B9D).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                          color: liked
                              ? const Color(0xFFFF6B9D).withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 14,
                          color: liked ? const Color(0xFFFF6B9D) : Colors.white38,
                        ),
                        const SizedBox(width: 5),
                        Text('${likes.length}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: liked ? const Color(0xFFFF6B9D) : Colors.white38)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}
