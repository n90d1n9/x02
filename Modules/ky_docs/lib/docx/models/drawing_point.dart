import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset point;
  final Paint paint;
  DrawingPoint(this.point, this.paint);
  Map<String, dynamic> toJson() => {
    'x': point.dx,
    'y': point.dy,
    'color': paint.color.toARGB32(),
    'strokeWidth': paint.strokeWidth,
  };
  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    final paint = Paint()
      ..color = Color(json['color'])
      ..strokeWidth = json['strokeWidth']
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    return DrawingPoint(Offset(json['x'], json['y']), paint);
  }
}
