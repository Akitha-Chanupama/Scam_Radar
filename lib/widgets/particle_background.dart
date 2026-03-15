import 'dart:math';
import 'package:flutter/material.dart';

class ParticleBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final bool dense;

  const ParticleBackground({
    super.key,
    required this.child,
    this.particleCount = 40,
    this.dense = false,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _particles = List.generate(
      widget.particleCount,
      (_) => _Particle.random(_rng),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, anim) {
            // Tick each particle
            for (final p in _particles) {
              p.update(0.003);
            }
            return CustomPaint(
              painter: _NetworkPainter(_particles, widget.dense),
              child: const SizedBox.expand(),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _Particle {
  double x, y; // 0..1 normalized
  double vx, vy; // velocity
  double radius;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
  });

  factory _Particle.random(Random rng) {
    final angle = rng.nextDouble() * 2 * pi;
    final speed = 0.03 + rng.nextDouble() * 0.07;
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      vx: cos(angle) * speed,
      vy: sin(angle) * speed,
      radius: 1.5 + rng.nextDouble() * 2.5,
      opacity: 0.3 + rng.nextDouble() * 0.5,
    );
  }

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    // Wrap around edges
    if (x < 0) x += 1;
    if (x > 1) x -= 1;
    if (y < 0) y += 1;
    if (y > 1) y -= 1;
  }
}

class _NetworkPainter extends CustomPainter {
  final List<_Particle> particles;
  final bool dense;

  _NetworkPainter(this.particles, this.dense);

  static const _cyan = Color(0xFF00D4FF);
  static const _blue = Color(0xFF0057FF);
  static const double _connectDist = 0.18;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..strokeWidth = 0.5;
    final dotPaint = Paint();

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final px = p.x * size.width;
      final py = p.y * size.height;

      // Draw connections
      for (int j = i + 1; j < particles.length; j++) {
        final q = particles[j];
        final dx = p.x - q.x;
        final dy = p.y - q.y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < _connectDist) {
          final alpha = (1 - dist / _connectDist) * 0.35;
          linePaint.color = _cyan.withValues(alpha: alpha);
          canvas.drawLine(
            Offset(px, py),
            Offset(q.x * size.width, q.y * size.height),
            linePaint,
          );
        }
      }

      // Draw particle dot
      dotPaint.color = (i % 3 == 0 ? _blue : _cyan).withValues(
        alpha: p.opacity * 0.7,
      );
      canvas.drawCircle(Offset(px, py), p.radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_NetworkPainter old) => true;
}
