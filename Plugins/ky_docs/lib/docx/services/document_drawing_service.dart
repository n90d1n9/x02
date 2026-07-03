import 'dart:typed_data';

import '../models/drawing_data.dart';

class DrawingInsertion {
  final DrawingData drawing;
  final List<DrawingData> drawings;

  const DrawingInsertion({required this.drawing, required this.drawings});

  String get reference => '\n[DRAWING:${drawing.id}]\n';
}

class DocumentDrawingService {
  const DocumentDrawingService();

  DrawingInsertion insertDrawing({
    required List<DrawingData> currentDrawings,
    required String id,
    required Uint8List imageBytes,
    required double width,
    required double height,
  }) {
    final drawing = DrawingData(
      id: id,
      imageBytes: Uint8List.fromList(imageBytes),
      width: width,
      height: height,
    );

    return DrawingInsertion(
      drawing: drawing,
      drawings: [...currentDrawings, drawing],
    );
  }

  List<DrawingData> deleteDrawing({
    required List<DrawingData> currentDrawings,
    required String drawingId,
  }) {
    return currentDrawings.where((drawing) => drawing.id != drawingId).toList();
  }
}
