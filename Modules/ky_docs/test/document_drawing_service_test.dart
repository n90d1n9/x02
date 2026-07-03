import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/drawing_data.dart';
import 'package:ky_docs/docx/services/document_drawing_service.dart';

void main() {
  group('DocumentDrawingService', () {
    const service = DocumentDrawingService();

    test('inserts a drawing with deterministic id and document reference', () {
      final insertion = service.insertDrawing(
        currentDrawings: const [],
        id: 'drawing-1',
        imageBytes: Uint8List.fromList([1, 2, 3]),
        width: 320,
        height: 180,
      );

      expect(insertion.reference, '\n[DRAWING:drawing-1]\n');
      expect(insertion.drawing.id, 'drawing-1');
      expect(insertion.drawing.imageBytes, [1, 2, 3]);
      expect(insertion.drawing.width, 320);
      expect(insertion.drawing.height, 180);
      expect(insertion.drawings, [insertion.drawing]);
    });

    test('copies incoming image bytes on insert', () {
      final imageBytes = Uint8List.fromList([1, 2, 3]);
      final insertion = service.insertDrawing(
        currentDrawings: const [],
        id: 'drawing-1',
        imageBytes: imageBytes,
        width: 100,
        height: 100,
      );

      imageBytes[0] = 99;

      expect(insertion.drawing.imageBytes, [1, 2, 3]);
    });

    test('deletes a drawing by id', () {
      final first = DrawingData(
        id: 'drawing-1',
        imageBytes: Uint8List.fromList([1]),
        width: 100,
        height: 100,
      );
      final second = DrawingData(
        id: 'drawing-2',
        imageBytes: Uint8List.fromList([2]),
        width: 120,
        height: 120,
      );

      final drawings = service.deleteDrawing(
        currentDrawings: [first, second],
        drawingId: 'drawing-1',
      );

      expect(drawings, [second]);
    });

    test('keeps drawings when delete id is missing', () {
      final drawing = DrawingData(
        id: 'drawing-1',
        imageBytes: Uint8List.fromList([1]),
        width: 100,
        height: 100,
      );

      final drawings = service.deleteDrawing(
        currentDrawings: [drawing],
        drawingId: 'missing',
      );

      expect(drawings, [drawing]);
    });
  });
}
