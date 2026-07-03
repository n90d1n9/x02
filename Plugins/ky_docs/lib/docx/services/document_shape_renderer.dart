import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

class RenderedShape {
  final Uint8List imageBytes;
  final double width;
  final double height;

  const RenderedShape({
    required this.imageBytes,
    required this.width,
    required this.height,
  });
}

class DocumentShapeRenderer {
  static const defaultSize = 200.0;
  static const defaultColor = ui.Color(0xFF2196F3);
  static const supportedShapeTypes = {
    'rectangle',
    'circle',
    'triangle',
    'star',
  };

  const DocumentShapeRenderer();

  bool supports(String shapeType) => supportedShapeTypes.contains(shapeType);

  Future<RenderedShape?> renderPng(
    String shapeType, {
    double size = defaultSize,
    ui.Color color = defaultColor,
  }) async {
    if (!supports(shapeType) || size <= 0) return null;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill;

    _drawShape(canvas, paint, shapeType, size);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    return RenderedShape(
      imageBytes: byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
      width: size,
      height: size,
    );
  }

  void _drawShape(
    ui.Canvas canvas,
    ui.Paint paint,
    String shapeType,
    double size,
  ) {
    switch (shapeType) {
      case 'rectangle':
        canvas.drawRect(ui.Rect.fromLTWH(0, 0, size, size * 0.6), paint);
        break;
      case 'circle':
        canvas.drawCircle(ui.Offset(size / 2, size / 2), size / 2, paint);
        break;
      case 'triangle':
        _drawTriangle(canvas, paint, size);
        break;
      case 'star':
        _drawStar(canvas, paint, size);
        break;
    }
  }

  void _drawTriangle(ui.Canvas canvas, ui.Paint paint, double size) {
    final path = ui.Path()
      ..moveTo(size / 2, 0)
      ..lineTo(size, size)
      ..lineTo(0, size)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawStar(ui.Canvas canvas, ui.Paint paint, double size) {
    final path = ui.Path();
    final center = ui.Offset(size / 2, size / 2);
    final outerRadius = size / 2;
    final innerRadius = size / 4;
    const points = 5;

    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi) / points - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }
}
