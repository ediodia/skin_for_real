import 'dart:math';
import 'dart:js' as js;
import 'package:flutter/material.dart';

class ShatterController {
  _ShatterTransitionState? _state;

  void _attach(_ShatterTransitionState s) => _state = s;
  void _detach() => _state = null;

  Future<void> trigger() async {
    if (_state != null) {
      await _state!.startShatter();
    }
  }
}

class ShatterTransition extends StatefulWidget {
  final Widget child;
  final VoidCallback onComplete;
  final ShatterController controller;

  const ShatterTransition({
    super.key,
    required this.child,
    required this.onComplete,
    required this.controller,
  });

  @override
  State<ShatterTransition> createState() => _ShatterTransitionState();
}

class _ShatterTransitionState extends State<ShatterTransition>
    with TickerProviderStateMixin {
  late AnimationController _scatterController;
  late AnimationController _reassembleController;
  late AnimationController _flashController;
  bool _shattering = false;
  bool _reassembling = false;
  final List<_Shard> _shards = [];
  final Random _random = Random();
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);

    _scatterController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));
    _reassembleController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));
    _flashController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));

    _scatterController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() => _reassembling = true);
          _reassembleController.forward();
        }
      }
    });

    _reassembleController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await _flashController.forward();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    widget.controller._detach();
    _scatterController.dispose();
    _reassembleController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _generateShards(Size size) {
    _shards.clear();
    _size = size;

    // Voronoi-like irregular shards — more realistic glass
    final points = <Offset>[];
    const shardCount = 140;

    // Seed points — denser near center (impact point)
    for (int i = 0; i < shardCount; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final radius = _random.nextDouble() < 0.4
          ? _random.nextDouble() * size.width * 0.3
          : _random.nextDouble() * size.width * 0.7;
      points.add(Offset(
        size.width / 2 + cos(angle) * radius,
        size.height / 2 + sin(angle) * radius,
      ));
    }

    // Build triangulated shards from points
    for (int i = 0; i < points.length - 2; i += 2) {
      if (i + 2 >= points.length) break;
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[i + 2];

      // Clamp to screen bounds
      final clamped = [p1, p2, p3].map((p) => Offset(
        p.dx.clamp(0, size.width),
        p.dy.clamp(0, size.height),
      )).toList();

      final center = Offset(
        (clamped[0].dx + clamped[1].dx + clamped[2].dx) / 3,
        (clamped[0].dy + clamped[1].dy + clamped[2].dy) / 3,
      );

      final distFromCenter = (center -
          Offset(size.width / 2, size.height / 2)).distance;
      final maxDist = sqrt(
          size.width * size.width + size.height * size.height) / 2;
      final normalizedDist = (distFromCenter / maxDist).clamp(0.0, 1.0);

      final angle = atan2(
        center.dy - size.height / 2,
        center.dx - size.width / 2,
      );

      final speed = 0.5 + normalizedDist * 0.5 + _random.nextDouble() * 0.3;
      final scatterDist = size.width * (0.5 + speed * 0.9);

      _shards.add(_Shard(
        vertices: clamped,
        center: center,
        scatterOffset: Offset(
          cos(angle) * scatterDist + (_random.nextDouble() - 0.5) * 120,
          sin(angle) * scatterDist + (_random.nextDouble() - 0.5) * 120,
        ),
        rotation: (_random.nextDouble() - 0.5) * pi * 3,
        delay: normalizedDist * 0.25 + _random.nextDouble() * 0.1,
        scaleTarget: 0.05 + _random.nextDouble() * 0.2,
      ));
    }

    // Add rectangular shards for better coverage
    const cols = 12;
    const rows = 18;
    final w = size.width / cols;
    final h = size.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final bx = c * w;
        final by = r * h;
        final jx = w * 0.25;
        final jy = h * 0.25;

        final vertices = [
          Offset(bx + _jitter(jx), by + _jitter(jy)),
          Offset(bx + w + _jitter(jx), by + _jitter(jy)),
          Offset(bx + w + _jitter(jx), by + h + _jitter(jy)),
          Offset(bx + _jitter(jx), by + h + _jitter(jy)),
        ];

        final center = Offset(bx + w / 2, by + h / 2);
        final dist = (center - Offset(size.width / 2, size.height / 2)).distance;
        final maxD = sqrt(size.width * size.width + size.height * size.height) / 2;
        final nd = (dist / maxD).clamp(0.0, 1.0);
        final angle = atan2(center.dy - size.height / 2, center.dx - size.width / 2);
        final scatter = size.width * (0.4 + nd * 0.8);

        _shards.add(_Shard(
          vertices: vertices,
          center: center,
          scatterOffset: Offset(
            cos(angle) * scatter + (_random.nextDouble() - 0.5) * 80,
            sin(angle) * scatter + (_random.nextDouble() - 0.5) * 80,
          ),
          rotation: (_random.nextDouble() - 0.5) * pi * 2.5,
          delay: nd * 0.2 + _random.nextDouble() * 0.12,
          scaleTarget: 0.08 + _random.nextDouble() * 0.25,
        ));
      }
    }
  }

  double _jitter(double max) =>
      (_random.nextDouble() - 0.5) * max * 2;

  Future<void> startShatter() async {
    if (_shattering) return;
    _generateShards(_size);
    try { js.context.callMethod('sfr_soundGlassShatter', []); } catch (_) {}
    setState(() => _shattering = true);
    _scatterController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      if (!_shattering) _size = size;

      return Stack(children: [
        if (!_shattering) widget.child
        else Opacity(opacity: 0, child: widget.child),

        if (_shattering)
          AnimatedBuilder(
            animation: Listenable.merge(
                [_scatterController, _reassembleController]),
            builder: (context, _) => CustomPaint(
              painter: _ShatterPainter(
                shards: _shards,
                scatterProgress: CurvedAnimation(
                  parent: _scatterController,
                  curve: Curves.easeInQuart,
                ).value,
                reassembleProgress: CurvedAnimation(
                  parent: _reassembleController,
                  curve: Curves.easeOutCubic,
                ).value,
                isReassembling: _reassembling,
              ),
              size: size,
            ),
          ),

        // Crack lines overlay at impact
        if (_shattering && _scatterController.value < 0.3)
          AnimatedBuilder(
            animation: _scatterController,
            builder: (context, _) => CustomPaint(
              painter: _CrackLinePainter(
                progress: _scatterController.value / 0.3,
                center: Offset(size.width / 2, size.height / 2),
              ),
              size: size,
            ),
          ),

        // Purple flash at reassembly
        AnimatedBuilder(
          animation: _flashController,
          builder: (context, _) {
            if (_flashController.value == 0) return const SizedBox.shrink();
            return Container(
              color: const Color(0xFF7B2FBE)
                  .withValues(alpha: (1 - _flashController.value) * 0.7),
            );
          },
        ),
      ]);
    });
  }
}

class _Shard {
  final List<Offset> vertices;
  final Offset center;
  final Offset scatterOffset;
  final double rotation;
  final double delay;
  final double scaleTarget;

  const _Shard({
    required this.vertices,
    required this.center,
    required this.scatterOffset,
    required this.rotation,
    required this.delay,
    required this.scaleTarget,
  });
}

class _ShatterPainter extends CustomPainter {
  final List<_Shard> shards;
  final double scatterProgress;
  final double reassembleProgress;
  final bool isReassembling;

  _ShatterPainter({
    required this.shards,
    required this.scatterProgress,
    required this.reassembleProgress,
    required this.isReassembling,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final shard in shards) {
      double t;
      Offset offset;
      double rotation;
      double scale;
      double opacity;

      if (isReassembling) {
        t = _easeOutCubic(reassembleProgress);
        offset = Offset.lerp(shard.scatterOffset, Offset.zero, t)!;
        rotation = shard.rotation * (1 - t);
        scale = _lerp(shard.scaleTarget, 1.0, t);
        opacity = _lerp(0.5, 1.0, t);
      } else {
        final delayed = ((scatterProgress - shard.delay) /
            (1.0 - shard.delay)).clamp(0.0, 1.0);
        t = _easeIn(delayed);
        if (t <= 0) continue;
        offset = Offset.lerp(Offset.zero, shard.scatterOffset, t)!;
        rotation = shard.rotation * t;
        scale = _lerp(1.0, shard.scaleTarget, t);
        opacity = _lerp(1.0, 0.0, t * 0.7);
      }

      if (opacity <= 0.01) continue;

      final shardCenter = shard.center + offset;
      canvas.save();
      canvas.translate(shardCenter.dx, shardCenter.dy);
      canvas.rotate(rotation);
      canvas.scale(scale);

      final path = Path();
      final local = shard.vertices.map((v) => v - shard.center).toList();
      path.moveTo(local[0].dx, local[0].dy);
      for (int i = 1; i < local.length; i++) {
        path.lineTo(local[i].dx, local[i].dy);
      }
      path.close();

      // Glass fill — very transparent white/blue tint
      final fillPaint = Paint()
        ..color = const Color(0xFFE8F4FF).withValues(alpha: opacity * 0.12)
        ..style = PaintingStyle.fill;

      // Glass highlight — bright edge
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      // Inner refraction tint
      final tintPaint = Paint()
        ..color = const Color(0xFF7B2FBE).withValues(alpha: opacity * 0.06)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, tintPaint);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, highlightPaint);

      canvas.restore();
    }
  }

  double _easeIn(double t) => t * t * t;
  double _easeOutCubic(double t) => 1 - pow(1 - t, 3).toDouble();
  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_ShatterPainter old) =>
      old.scatterProgress != scatterProgress ||
      old.reassembleProgress != reassembleProgress;
}

class _CrackLinePainter extends CustomPainter {
  final double progress;
  final Offset center;

  _CrackLinePainter({required this.progress, required this.center});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(7);
    const crackCount = 12;

    for (int i = 0; i < crackCount; i++) {
      final angle = (i / crackCount) * 2 * pi +
          random.nextDouble() * 0.4;
      final length = size.width * (0.2 + random.nextDouble() * 0.4) * progress;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: progress * 0.9)
        ..strokeWidth = 0.8 + random.nextDouble() * 1.2
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(center.dx, center.dy);

      var x = center.dx;
      var y = center.dy;
      final segments = 4 + random.nextInt(3);

      for (int s = 0; s < segments; s++) {
        final segLen = length / segments;
        final jitter = (random.nextDouble() - 0.5) * 0.4;
        x += cos(angle + jitter) * segLen;
        y += sin(angle + jitter) * segLen;
        path.lineTo(x, y);

        // Branch cracks
        if (s == 2 && random.nextBool()) {
          final branchAngle = angle + (random.nextDouble() - 0.5) * 1.2;
          final branchLen = segLen * 0.5 * progress;
          path.moveTo(x, y);
          path.lineTo(
            x + cos(branchAngle) * branchLen,
            y + sin(branchAngle) * branchLen,
          );
          path.moveTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CrackLinePainter old) =>
      old.progress != progress;
}
