import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/style/particle_effect.dart';
import 'particle_painter.dart';

class ParticleBackground extends StatefulWidget {
  final ParticleEffect effect;

  const ParticleBackground({super.key, required this.effect});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    particles = List.generate(
      widget.effect.particleCount,
      (index) => Particle(
        position: Offset(
          math.Random().nextDouble() * 1920,
          math.Random().nextDouble() * 1080,
        ),
        velocity: Offset(
          (math.Random().nextDouble() - 0.5) * widget.effect.speed,
          (math.Random().nextDouble() - 0.5) * widget.effect.speed,
        ),
        size: widget.effect.size,
        color: widget.effect.color,
      ),
    );

    _controller.addListener(() {
      setState(() {
        for (var particle in particles) {
          particle.update();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(particles: particles),
      child: Container(),
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  double size;
  Color color;

  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
  });

  void update() {
    position += velocity;

    if (position.dx < 0 || position.dx > 1920) {
      velocity = Offset(-velocity.dx, velocity.dy);
    }
    if (position.dy < 0 || position.dy > 1080) {
      velocity = Offset(velocity.dx, -velocity.dy);
    }
  }
}
