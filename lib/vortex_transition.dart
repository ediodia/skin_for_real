import 'dart:math';
import 'package:flutter/material.dart';

class VortexController {
  Future<void> Function()? _triggerFn;

  void _attach(Future<void> Function() fn) => _triggerFn = fn;
  void _detach() => _triggerFn = null;

  Future<void> trigger() async {
    await _triggerFn?.call();
  }
}

class VortexTransitionControlled extends StatefulWidget {
  final Widget child;
  final VoidCallback onComplete;
  final VortexController controller;

  const VortexTransitionControlled({
    super.key,
    required this.child,
    required this.onComplete,
    required this.controller,
  });

  @override
  State<VortexTransitionControlled> createState() =>
      _VortexTransitionControlledState();
}

class _VortexTransitionControlledState
    extends State<VortexTransitionControlled>
    with TickerProviderStateMixin {
  late AnimationController _vortexController;
  late AnimationController _flashController;
  late Animation<double> _scale;
  late Animation<double> _rotation;
  late Animation<double> _suck;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(_startVortex);
    _vortexController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _flashController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scale = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _vortexController, curve: Curves.easeInBack));
    _rotation = Tween<double>(begin: 0.0, end: 4 * pi).animate(
        CurvedAnimation(parent: _vortexController, curve: Curves.easeIn));
    _suck = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
        parent: _vortexController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInExpo)));
  }

  Future<void> _startVortex() async {
    if (_animating) return;
    _animating = true;
    await _vortexController.forward();
    await _flashController.forward();
    widget.onComplete();
  }

  @override
  void dispose() {
    widget.controller._detach();
    _vortexController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      AnimatedBuilder(
        animation: _vortexController,
        builder: (context, child) => Transform.rotate(
          angle: _rotation.value,
          alignment: Alignment.center,
          child: Transform.scale(
            scale: _scale.value * _suck.value,
            alignment: Alignment.center,
            child: Opacity(
              opacity: (1.0 - _vortexController.value * 0.8).clamp(0.0, 1.0),
              child: child,
            ),
          ),
        ),
        child: widget.child,
      ),
      AnimatedBuilder(
        animation: _vortexController,
        builder: (context, _) {
          if (_vortexController.value < 0.1) return const SizedBox.shrink();
          return CustomPaint(
            painter: _VortexPainter(_vortexController.value),
            size: Size.infinite,
          );
        },
      ),
      AnimatedBuilder(
        animation: _flashController,
        builder: (context, _) {
          if (_flashController.value == 0) return const SizedBox.shrink();
          return Container(
            color: const Color(0xFF7B2FBE)
                .withValues(alpha: _flashController.value * 0.6),
          );
        },
      ),
    ]);
  }
}

class _VortexPainter extends CustomPainter {
  final double progress;
  _VortexPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.8;

    final ringColors = [
      const Color(0xFF7B2FBE),
      const Color(0xFF2F7BBE),
      const Color(0xFFBE2F7B),
      const Color(0xFF6EE4F5),
    ];

    for (int i = 0; i < 8; i++) {
      final ringProgress = (progress - i * 0.08).clamp(0.0, 1.0);
      if (ringProgress <= 0) continue;
      final radius = maxRadius * (1.0 - ringProgress) * (1.0 - progress * 0.5);
      final opacity = ringProgress * (1.0 - progress * 0.6) * 0.6;
      final paint = Paint()
        ..color = ringColors[i % ringColors.length].withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2.0 - progress).clamp(0.5, 2.0);
      canvas.drawCircle(center, radius.clamp(0.0, maxRadius), paint);
    }

    final spiralPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFB76EF5).withValues(alpha: progress * 0.4);
    final path = Path();
    for (double angle = 0; angle < 6 * pi; angle += 0.1) {
      final r = maxRadius * (1 - progress) * (1 - angle / (6 * pi)) * 0.8;
      final x = center.dx + r * cos(angle + progress * 4 * pi);
      final y = center.dy + r * sin(angle + progress * 4 * pi);
      if (angle == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, spiralPaint);
  }

  @override
  bool shouldRepaint(_VortexPainter old) => old.progress != progress;
}
