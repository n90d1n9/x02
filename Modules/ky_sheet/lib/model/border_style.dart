import 'package:flutter/material.dart';

class BorderStyle {
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final Color color;
  final double width;

  BorderStyle({
    this.top = false,
    this.bottom = false,
    this.left = false,
    this.right = false,
    this.color = Colors.black,
    this.width = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'top': top,
    'bottom': bottom,
    'left': left,
    'right': right,
    'color': color.toARGB32(),
    'width': width,
  };

  factory BorderStyle.fromJson(Map<String, dynamic> json) => BorderStyle(
    top: json['top'] ?? false,
    bottom: json['bottom'] ?? false,
    left: json['left'] ?? false,
    right: json['right'] ?? false,
    color: Color(json['color'] ?? Colors.black.toARGB32()),
    width: json['width']?.toDouble() ?? 1.0,
  );
}
