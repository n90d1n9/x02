import 'package:flutter/material.dart';

import 'drawing_point.dart';

class DrawingBoardState {
  final List<DrawingPoint?> points;
  final Color currentColor;
  final double strokeWidth;
  final bool isErasing;
  DrawingBoardState({
    this.points = const [],
    this.currentColor = Colors.black,
    this.strokeWidth = 3.0,
    this.isErasing = false,
  });
  DrawingBoardState copyWith({
    List<DrawingPoint?>? points,
    Color? currentColor,
    double? strokeWidth,
    bool? isErasing,
  }) {
    return DrawingBoardState(
      points: points ?? this.points,
      currentColor: currentColor ?? this.currentColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isErasing: isErasing ?? this.isErasing,
    );
  }
}
