// lib/models/style/particle_effect.dart
import 'package:flutter/material.dart';

class ParticleEffect {
  final int particleCount;
  final Color color;
  final double speed;
  final double size;

  ParticleEffect({
    this.particleCount = 50,
    this.color = Colors.white,
    this.speed = 1.0,
    this.size = 3.0,
  });

  factory ParticleEffect.fromJson(Map<String, dynamic> json) {
    return ParticleEffect(
      particleCount: json['particleCount'] as int? ?? 50,
      color: json['color'] != null ? Color(json['color'] as int) : Colors.white,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      size: (json['size'] as num?)?.toDouble() ?? 3.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'particleCount': particleCount,
      'color': color.toARGB32(),
      'speed': speed,
      'size': size,
    };
  }
}
