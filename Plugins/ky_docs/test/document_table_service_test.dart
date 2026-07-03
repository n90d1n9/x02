import 'package:flutter_test/flutter_test.dart';
import 'package:ky_docs/docx/models/document_table.dart';
import 'package:ky_docs/docx/services/document_table_service.dart';

void main() {
  group('DocumentTableService', () {
    const service = DocumentTableService();

    test('inserts a table with deterministic id and document reference', () {
      final insertion = service.insertTable(
        currentTables: const [],
        id: 'table-1',
        rows: 2,
        columns: 3,
      );

      expect(insertion.reference, '\n[TABLE:table-1]\n');
      expect(insertion.table.rows, 2);
      expect(insertion.table.columns, 3);
      expect(insertion.table.data, [
        ['', '', ''],
        ['', '', ''],
      ]);
      expect(insertion.tables, [insertion.table]);
    });

    test('keeps inserted table dimensions at one or above', () {
      final insertion = service.insertTable(
        currentTables: const [],
        id: 'table-1',
        rows: 0,
        columns: -4,
      );

      expect(insertion.table.rows, 1);
      expect(insertion.table.columns, 1);
      expect(insertion.table.data, [
        [''],
      ]);
    });

    test('updates a single cell without mutating source table data', () {
      const table = DocumentTable(
        id: 'table-1',
        rows: 2,
        columns: 2,
        data: [
          ['A1', 'B1'],
          ['A2', 'B2'],
        ],
      );

      final tables = service.updateCell(
        currentTables: const [table],
        tableId: 'table-1',
        row: 1,
        column: 0,
        value: 'Updated',
      );

      expect(table.data[1][0], 'A2');
      expect(tables.single.data, [
        ['A1', 'B1'],
        ['Updated', 'B2'],
      ]);
    });

    test('adds rows and columns while preserving existing values', () {
      const table = DocumentTable(
        id: 'table-1',
        rows: 1,
        columns: 1,
        data: [
          ['A1'],
        ],
      );

      final withRow = service.addRow(
        currentTables: const [table],
        tableId: 'table-1',
      );
      final withColumn = service.addColumn(
        currentTables: withRow,
        tableId: 'table-1',
      );

      expect(withColumn.single.rows, 2);
      expect(withColumn.single.columns, 2);
      expect(withColumn.single.data, [
        ['A1', ''],
        ['', ''],
      ]);
    });

    test('deletes rows and columns with minimum-size guards', () {
      const table = DocumentTable(
        id: 'table-1',
        rows: 2,
        columns: 2,
        data: [
          ['A1', 'B1'],
          ['A2', 'B2'],
        ],
      );

      final withoutRow = service.deleteRow(
        currentTables: const [table],
        tableId: 'table-1',
        rowIndex: 0,
      );
      final withoutColumn = service.deleteColumn(
        currentTables: withoutRow,
        tableId: 'table-1',
        columnIndex: 0,
      );
      final guarded = service.deleteColumn(
        currentTables: withoutColumn,
        tableId: 'table-1',
        columnIndex: 0,
      );

      expect(guarded.single.rows, 1);
      expect(guarded.single.columns, 1);
      expect(guarded.single.data, [
        ['B2'],
      ]);
    });

    test('deletes a table by id', () {
      const first = DocumentTable(
        id: 'table-1',
        rows: 1,
        columns: 1,
        data: [
          ['A1'],
        ],
      );
      const second = DocumentTable(
        id: 'table-2',
        rows: 1,
        columns: 1,
        data: [
          ['B1'],
        ],
      );

      final tables = service.deleteTable(
        currentTables: const [first, second],
        tableId: 'table-1',
      );

      expect(tables, const [second]);
    });
  });
}
