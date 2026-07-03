import 'package:flutter/material.dart';

/// Lightweight slide grid overlay with configurable spacing.
class GridPainter extends StatelessWidget {
  final double gridSize;

  const GridPainter({super.key, required this.gridSize});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(gridSize: gridSize),
      child: Container(),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double gridSize;

  const _GridPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    final safeGridSize = gridSize.clamp(4.0, 160.0);

    for (double x = 0; x < size.width; x += safeGridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += safeGridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize;
  }
}
