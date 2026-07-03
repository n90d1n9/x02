import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/chart_data.dart';
import 'package:ky_docs/docx/models/chart_type.dart';
import 'package:ky_docs/docx/models/document_table.dart';
import 'package:ky_docs/docx/models/drawing_data.dart';
import 'package:ky_docs/docx/services/document_embedded_content_service.dart';
import 'package:ky_docs/docx/services/document_image_insertion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentEmbeddedContentService', () {
    const service = DocumentEmbeddedContentService();

    quill.QuillController controllerWithText(String text, {int? selection}) {
      final controller = quill.QuillController.basic();
      controller.document.insert(0, text);
      controller.updateSelection(
        TextSelection.collapsed(offset: selection ?? text.length),
        quill.ChangeSource.local,
      );
      addTearDown(controller.dispose);
      return controller;
    }

    test('inserts a table marker at the current selection', () {
      final controller = controllerWithText('Body text', selection: 4);

      final insertion = service.insertTable(
        controller: controller,
        currentTables: const [],
        id: 'table-1',
        rows: 2,
        columns: 3,
      );

      expect(insertion.table.id, 'table-1');
      expect(insertion.tables, [insertion.table]);
      expect(
        controller.document.toPlainText(),
        contains('Body\n[TABLE:table-1]\n'),
      );
    });

    test('updates table data without inserting extra document markers', () {
      const table = DocumentTable(
        id: 'table-1',
        rows: 1,
        columns: 1,
        data: [
          ['A1'],
        ],
      );
      final controller = controllerWithText('Body');

      final tables = service.updateTableCell(
        currentTables: const [table],
        tableId: 'table-1',
        row: 0,
        column: 0,
        value: 'Updated',
      );

      expect(tables.single.data, [
        ['Updated'],
      ]);
      expect(controller.document.toPlainText(), isNot(contains('[TABLE:')));
    });

    test('inserts a chart marker and copies incoming data', () {
      final labels = ['Q1'];
      final values = [10.0];
      final controller = controllerWithText('Report');

      final insertion = service.insertChart(
        controller: controller,
        currentCharts: const [],
        id: 'chart-1',
        type: ChartType.bar,
        title: 'Revenue',
        labels: labels,
        values: values,
      );
      labels[0] = 'Changed';
      values[0] = 99;

      expect(insertion.chart.labels, ['Q1']);
      expect(insertion.chart.values, [10]);
      expect(controller.document.toPlainText(), contains('[CHART:chart-1]'));
    });

    test('updates and deletes charts through the embedded API', () {
      const chart = ChartData(
        id: 'chart-1',
        type: ChartType.pie,
        title: 'Original',
        labels: ['A'],
        values: [1],
        color: Colors.green,
      );

      final updated = service.updateChart(
        currentCharts: const [chart],
        chartId: 'chart-1',
        title: 'Updated',
        labels: const ['B'],
        values: const [2],
      );
      final deleted = service.deleteChart(
        currentCharts: updated,
        chartId: 'chart-1',
      );

      expect(updated.single.type, ChartType.pie);
      expect(updated.single.color, Colors.green);
      expect(updated.single.title, 'Updated');
      expect(deleted, isEmpty);
    });

    test('inserts a drawing marker and protects image bytes', () {
      final imageBytes = Uint8List.fromList([1, 2, 3]);
      final controller = controllerWithText('Canvas');

      final insertion = service.insertDrawing(
        controller: controller,
        currentDrawings: const [],
        id: 'drawing-1',
        imageBytes: imageBytes,
        width: 320,
        height: 180,
      );
      imageBytes[0] = 99;

      expect(insertion.drawing.imageBytes, [1, 2, 3]);
      expect(
        controller.document.toPlainText(),
        contains('[DRAWING:drawing-1]'),
      );
    });

    test('deletes drawings through the embedded API', () {
      final drawing = DrawingData(
        id: 'drawing-1',
        imageBytes: Uint8List.fromList([1]),
        width: 100,
        height: 100,
      );

      final drawings = service.deleteDrawing(
        currentDrawings: [drawing],
        drawingId: 'drawing-1',
      );

      expect(drawings, isEmpty);
    });

    test(
      'inserts picked image placeholders at the current selection',
      () async {
        final controller = controllerWithText('Images', selection: 3);
        final service = DocumentEmbeddedContentService(
          imageInsertionService: DocumentImageInsertionService(
            imagePicker: () async => const PickedDocumentImage(
              name: 'photo.png',
              path: '/tmp/photo.png',
            ),
          ),
        );

        final insertion = await service.insertImage(controller: controller);

        expect(insertion?.name, 'photo.png');
        expect(insertion?.path, '/tmp/photo.png');
        expect(
          controller.document.toPlainText(),
          contains('[Image: photo.png]'),
        );
      },
    );

    test(
      'does not insert an image placeholder when picking is cancelled',
      () async {
        final controller = controllerWithText('Images');
        final service = DocumentEmbeddedContentService(
          imageInsertionService: DocumentImageInsertionService(
            imagePicker: () async => null,
          ),
        );

        final insertion = await service.insertImage(controller: controller);

        expect(insertion, isNull);
        expect(controller.document.toPlainText(), isNot(contains('[Image:')));
      },
    );

    test('renders shapes as drawings and inserts a drawing marker', () async {
      final controller = controllerWithText('Shapes');

      final insertion = await service.insertShape(
        controller: controller,
        currentDrawings: const [],
        createId: () => 'shape-1',
        shapeType: 'rectangle',
        size: 32,
      );

      expect(insertion?.drawing.id, 'shape-1');
      expect(insertion?.drawing.width, 32);
      expect(insertion?.drawing.height, 32);
      expect(insertion?.drawing.imageBytes.take(8).toList(), [
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
      ]);
      expect(controller.document.toPlainText(), contains('[DRAWING:shape-1]'));
    });

    test(
      'does not create shape drawings for unsupported shape types',
      () async {
        var createIdWasCalled = false;
        final controller = controllerWithText('Shapes');

        final insertion = await service.insertShape(
          controller: controller,
          currentDrawings: const [],
          createId: () {
            createIdWasCalled = true;
            return 'shape-1';
          },
          shapeType: 'hexagon',
        );

        expect(insertion, isNull);
        expect(createIdWasCalled, isFalse);
        expect(controller.document.toPlainText(), isNot(contains('[DRAWING:')));
      },
    );
  });
}
