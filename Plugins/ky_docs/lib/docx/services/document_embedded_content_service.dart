import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../models/chart_data.dart';
import '../models/chart_type.dart';
import '../models/document_table.dart';
import '../models/drawing_data.dart';
import 'document_chart_service.dart';
import 'document_drawing_service.dart';
import 'document_image_insertion_service.dart';
import 'document_reference_insertion_service.dart';
import 'document_shape_renderer.dart';
import 'document_table_service.dart';

class DocumentEmbeddedContentService {
  final DocumentTableService tableService;
  final DocumentChartService chartService;
  final DocumentDrawingService drawingService;
  final DocumentImageInsertionService imageInsertionService;
  final DocumentShapeRenderer shapeRenderer;
  final DocumentReferenceInsertionService referenceInsertionService;

  const DocumentEmbeddedContentService({
    this.tableService = const DocumentTableService(),
    this.chartService = const DocumentChartService(),
    this.drawingService = const DocumentDrawingService(),
    this.imageInsertionService = const DocumentImageInsertionService(),
    this.shapeRenderer = const DocumentShapeRenderer(),
    this.referenceInsertionService = const DocumentReferenceInsertionService(),
  });

  TableInsertion insertTable({
    required quill.QuillController controller,
    required List<DocumentTable> currentTables,
    required String id,
    required int rows,
    required int columns,
  }) {
    final insertion = tableService.insertTable(
      currentTables: currentTables,
      id: id,
      rows: rows,
      columns: columns,
    );
    _insertReference(controller: controller, reference: insertion.reference);
    return insertion;
  }

  List<DocumentTable> updateTableCell({
    required List<DocumentTable> currentTables,
    required String tableId,
    required int row,
    required int column,
    required String value,
  }) {
    return tableService.updateCell(
      currentTables: currentTables,
      tableId: tableId,
      row: row,
      column: column,
      value: value,
    );
  }

  List<DocumentTable> addTableRow({
    required List<DocumentTable> currentTables,
    required String tableId,
  }) {
    return tableService.addRow(currentTables: currentTables, tableId: tableId);
  }

  List<DocumentTable> addTableColumn({
    required List<DocumentTable> currentTables,
    required String tableId,
  }) {
    return tableService.addColumn(
      currentTables: currentTables,
      tableId: tableId,
    );
  }

  List<DocumentTable> deleteTableRow({
    required List<DocumentTable> currentTables,
    required String tableId,
    required int rowIndex,
  }) {
    return tableService.deleteRow(
      currentTables: currentTables,
      tableId: tableId,
      rowIndex: rowIndex,
    );
  }

  List<DocumentTable> deleteTableColumn({
    required List<DocumentTable> currentTables,
    required String tableId,
    required int columnIndex,
  }) {
    return tableService.deleteColumn(
      currentTables: currentTables,
      tableId: tableId,
      columnIndex: columnIndex,
    );
  }

  List<DocumentTable> deleteTable({
    required List<DocumentTable> currentTables,
    required String tableId,
  }) {
    return tableService.deleteTable(
      currentTables: currentTables,
      tableId: tableId,
    );
  }

  ChartInsertion insertChart({
    required quill.QuillController controller,
    required List<ChartData> currentCharts,
    required String id,
    required ChartType type,
    required String title,
    required List<String> labels,
    required List<double> values,
  }) {
    final insertion = chartService.insertChart(
      currentCharts: currentCharts,
      id: id,
      type: type,
      title: title,
      labels: labels,
      values: values,
    );
    _insertReference(controller: controller, reference: insertion.reference);
    return insertion;
  }

  List<ChartData> updateChart({
    required List<ChartData> currentCharts,
    required String chartId,
    required String title,
    required List<String> labels,
    required List<double> values,
  }) {
    return chartService.updateChart(
      currentCharts: currentCharts,
      chartId: chartId,
      title: title,
      labels: labels,
      values: values,
    );
  }

  List<ChartData> deleteChart({
    required List<ChartData> currentCharts,
    required String chartId,
  }) {
    return chartService.deleteChart(
      currentCharts: currentCharts,
      chartId: chartId,
    );
  }

  DrawingInsertion insertDrawing({
    required quill.QuillController controller,
    required List<DrawingData> currentDrawings,
    required String id,
    required Uint8List imageBytes,
    required double width,
    required double height,
  }) {
    final insertion = drawingService.insertDrawing(
      currentDrawings: currentDrawings,
      id: id,
      imageBytes: imageBytes,
      width: width,
      height: height,
    );
    _insertReference(controller: controller, reference: insertion.reference);
    return insertion;
  }

  List<DrawingData> deleteDrawing({
    required List<DrawingData> currentDrawings,
    required String drawingId,
  }) {
    return drawingService.deleteDrawing(
      currentDrawings: currentDrawings,
      drawingId: drawingId,
    );
  }

  Future<DocumentImageInsertion?> insertImage({
    required quill.QuillController controller,
  }) async {
    final insertion = await imageInsertionService.pickImage();
    if (insertion == null) return null;

    _insertReference(
      controller: controller,
      reference: insertion.referenceText,
    );
    return insertion;
  }

  Future<DrawingInsertion?> insertShape({
    required quill.QuillController controller,
    required List<DrawingData> currentDrawings,
    required String Function() createId,
    required String shapeType,
    double size = DocumentShapeRenderer.defaultSize,
    ui.Color color = DocumentShapeRenderer.defaultColor,
  }) async {
    final shape = await shapeRenderer.renderPng(
      shapeType,
      size: size,
      color: color,
    );
    if (shape == null) return null;

    return insertDrawing(
      controller: controller,
      currentDrawings: currentDrawings,
      id: createId(),
      imageBytes: shape.imageBytes,
      width: shape.width,
      height: shape.height,
    );
  }

  void _insertReference({
    required quill.QuillController controller,
    required String reference,
  }) {
    referenceInsertionService.insertAtSelection(
      controller: controller,
      reference: reference,
    );
  }
}
