import 'package:flutter_test/flutter_test.dart';
import '../services/table_service.dart';
import '../models/table_model.dart';

void main() {
  group('TableService Tests', () {
    late TableService tableService;

    setUp(() {
      tableService = TableService();
    });

    test('createTable creates a table with correct dimensions', () {
      final table = tableService.createTable(3, 4);
      
      expect(table.rows.length, 3);
      expect(table.rows.first.cells.length, 4);
      expect(table.widthPercent, 100.0);
      expect(table.alignment, TableAlignment.left);
      expect(table.borderStyle, isNotNull);
    });

    test('createTable throws error for invalid dimensions', () {
      expect(() => tableService.createTable(0, 3), throwsArgumentError);
      expect(() => tableService.createTable(3, 0), throwsArgumentError);
    });

    test('insertRow adds a row above the specified index', () {
      final table = tableService.createTable(2, 2);
      final initialRowCount = table.rows.length;
      
      tableService.insertRow(table, 0, position: 'above');
      
      expect(table.rows.length, initialRowCount + 1);
      expect(table.rows[0].cells.length, 2);
    });

    test('insertRow adds a row below the specified index', () {
      final table = tableService.createTable(2, 2);
      
      tableService.insertRow(table, 0, position: 'below');
      
      expect(table.rows.length, 3);
      expect(table.rows[1].cells.length, 2);
    });

    test('deleteRow removes the correct row', () {
      final table = tableService.createTable(3, 2);
      
      tableService.deleteRow(table, 1);
      
      expect(table.rows.length, 2);
    });

    test('deleteRow throws error when trying to delete last row', () {
      final table = tableService.createTable(1, 2);
      
      expect(() => tableService.deleteRow(table, 0), throwsStateError);
    });

    test('insertColumn adds a column to the left', () {
      final table = tableService.createTable(2, 2);
      
      tableService.insertColumn(table, 0, position: 'left');
      
      expect(table.rows.first.cells.length, 3);
    });

    test('insertColumn adds a column to the right', () {
      final table = tableService.createTable(2, 2);
      
      tableService.insertColumn(table, 0, position: 'right');
      
      expect(table.rows.first.cells.length, 3);
    });

    test('deleteColumn removes the correct column', () {
      final table = tableService.createTable(2, 3);
      
      tableService.deleteColumn(table, 1);
      
      expect(table.rows.first.cells.length, 2);
    });

    test('mergeCells combines cells correctly', () {
      final table = tableService.createTable(3, 3);
      
      tableService.mergeCells(table, 0, 0, 1, 1);
      
      final topLeftCell = table.rows[0].cells[0];
      expect(topLeftCell.colSpan, 2);
      expect(topLeftCell.rowSpan, 2);
      
      // Check that merged cells are marked
      expect(table.rows[0].cells[1].isMerged, true);
      expect(table.rows[1].cells[0].isMerged, true);
      expect(table.rows[1].cells[1].isMerged, true);
    });

    test('splitCell restores individual cells', () {
      final table = tableService.createTable(2, 2);
      
      // First merge
      tableService.mergeCells(table, 0, 0, 1, 1);
      
      // Then split
      tableService.splitCell(table, 0, 0);
      
      final topLeftCell = table.rows[0].cells[0];
      expect(topLeftCell.colSpan, 1);
      expect(topLeftCell.rowSpan, 1);
      expect(topLeftCell.isMerged, false);
    });

    test('updateCellStyle changes cell background and borders', () {
      final table = tableService.createTable(2, 2);
      final newColor = 0xFFFF0000; // Red
      final newBorderStyle = TableBorderStyle(
        top: BorderLine(width: 2.0, color: 0xFF0000FF),
        bottom: BorderLine(width: 2.0, color: 0xFF0000FF),
        left: BorderLine(width: 2.0, color: 0xFF0000FF),
        right: BorderLine(width: 2.0, color: 0xFF0000FF),
      );
      
      tableService.updateCellStyle(table, 0, 0, newColor, newBorderStyle);
      
      expect(table.rows[0].cells[0].backgroundColor, newColor);
      expect(table.rows[0].cells[0].borderStyle, equals(newBorderStyle));
    });

    test('table maintains content after operations', () {
      final table = tableService.createTable(2, 2);
      
      // Add some content to first cell (simulated)
      // In real scenario, this would be done through editor
      
      tableService.insertRow(table, 0, position: 'below');
      tableService.insertColumn(table, 0, position: 'right');
      
      // Verify structure integrity
      expect(table.rows.length, 3);
      expect(table.rows.first.cells.length, 3);
    });
  });

  group('TableModel Tests', () {
    test('TableModel serializes to JSON', () {
      final table = TableModel(
        id: 'test-1',
        rows: [
          TableRow(cells: [
            TableCell(content: [], colSpan: 1, rowSpan: 1),
          ]),
        ],
        widthPercent: 80.0,
        alignment: TableAlignment.center,
      );

      final json = table.toJson();
      
      expect(json['id'], 'test-1');
      expect(json['widthPercent'], 80.0);
      expect(json['alignment'], 'center');
    });

    test('TableModel deserializes from JSON', () {
      final json = {
        'id': 'test-2',
        'rows': [
          {
            'cells': [
              {
                'content': [],
                'colSpan': 1,
                'rowSpan': 1,
              }
            ]
          }
        ],
        'widthPercent': 90.0,
        'alignment': 'right',
      };

      final table = TableModel.fromJson(json);
      
      expect(table.id, 'test-2');
      expect(table.widthPercent, 90.0);
      expect(table.alignment, TableAlignment.right);
    });
  });
}
