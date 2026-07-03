// lib/models/style/neumorphism_style.dart
import 'package:flutter/material.dart';

class NeumorphismStyle {
  final Color baseColor;
  final double depth;
  final bool isPressed;
  final double borderRadius;

  NeumorphismStyle({
    required this.baseColor,
    this.depth = 10,
    this.isPressed = false,
    this.borderRadius = 16,
  });

  factory NeumorphismStyle.fromJson(Map<String, dynamic> json) {
    return NeumorphismStyle(
      baseColor: json['baseColor'] != null
          ? Color(json['baseColor'] as int)
          : Colors.white,
      depth: (json['depth'] as num?)?.toDouble() ?? 10.0,
      isPressed: json['isPressed'] as bool? ?? false,
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 16.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseColor': baseColor.toARGB32(),
      'depth': depth,
      'isPressed': isPressed,
      'borderRadius': borderRadius,
    };
  }
}
