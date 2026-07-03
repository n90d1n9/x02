// lib/models/style/gradient_animation.dart
import 'package:flutter/material.dart';

class GradientAnimation {
  final List<Color> colors;
  final double duration;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  GradientAnimation({
    required this.colors,
    this.duration = 3.0,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  factory GradientAnimation.fromJson(Map<String, dynamic> json) {
    return GradientAnimation(
      colors: (json['colors'] as List<dynamic>? ?? [])
          .map((e) => Color(e as int))
          .toList(),
      duration: (json['duration'] as num?)?.toDouble() ?? 3.0,
      // Defaulting alignment for simplicity as AlignmentGeometry parsing can be complex
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colors': colors.map((color) => color.toARGB32()).toList(),
      'duration': duration,
    };
  }
}
