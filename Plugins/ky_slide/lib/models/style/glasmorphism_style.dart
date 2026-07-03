// lib/models/style/glasmorphism_style.dart
import 'package:flutter/material.dart';

class GlassmorphismStyle {
  final double blur;
  final double opacity;
  final Color tintColor;
  final double borderRadius;

  GlassmorphismStyle({
    this.blur = 10,
    this.opacity = 0.2,
    this.tintColor = Colors.white,
    this.borderRadius = 16,
  });

  factory GlassmorphismStyle.fromJson(Map<String, dynamic> json) {
    return GlassmorphismStyle(
      blur: (json['blur'] as num?)?.toDouble() ?? 10.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.2,
      tintColor: json['tintColor'] != null
          ? Color(json['tintColor'] as int)
          : Colors.white,
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 16.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blur': blur,
      'opacity': opacity,
      'tintColor': tintColor.toARGB32(),
      'borderRadius': borderRadius,
    };
  }
}
