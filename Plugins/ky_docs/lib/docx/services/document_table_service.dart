import '../models/document_table.dart';

class TableInsertion {
  final DocumentTable table;
  final List<DocumentTable> tables;

  const TableInsertion({required this.table, required this.tables});

  String get reference => '\n[TABLE:${table.id}]\n';
}

class DocumentTableService {
  const DocumentTableService();

  TableInsertion insertTable({
    required List<DocumentTable> currentTables,
    required String id,
    required int rows,
    required int columns,
  }) {
    final safeRows = _atLeastOne(rows);
    final safeColumns = _atLeastOne(columns);
    final table = DocumentTable(
      id: id,
      rows: safeRows,
      columns: safeColumns,
      data: List.generate(
        safeRows,
        (_) => List.generate(safeColumns, (_) => ''),
      ),
    );

    return TableInsertion(table: table, tables: [...currentTables, table]);
  }

  List<DocumentTable> updateCell({
    required List<DocumentTable> currentTables,
    required String tableId,
    required int row,
    required int column,
    required String value,
  }) {
    return _updateTable(currentTables, tableId, (table) {
      if (!_hasCell(table, row, column)) return table;

      final data = _copyData(table.data);
      data[row][column] = value;
      return table.copyWith(data: data);
    });
  }

  List<DocumentTable> addRow({
    required List<DocumentTable> currentTables,
    required String tableId,
  }) {
    return _updateTable(currentTables, tableId, (table) {
      final data = [
        ..._copyData(table.data),
        List<String>.filled(table.columns, ''),
      ];

      return table.copyWith(rows: table.rows + 1, data: data);
    });
  }

  List<DocumentTable> addColumn({
    required List<DocumentTable> currentTables,
    required String tableId,
  }) {
    return _updateTable(currentTables, tableId, (table) {
      final data = table.data.map((row) => [...row, '']).toList();
      return table.copyWith(columns: table.columns + 1, data: data);
    });
  }

  List<DocumentTable> deleteRow({
    required List<DocumentTable> currentTables,
    required String tableId,
    required int rowIndex,
  }) {
    return _updateTable(currentTables, tableId, (table) {
      if (table.rows <= 1 || rowIndex < 0 || rowIndex >= table.rows) {
        return table;
      }

      final data = _copyData(table.data)..removeAt(rowIndex);
      return table.copyWith(rows: table.rows - 1, data: data);
    });
  }

  List<DocumentTable> deleteColumn({
    required List<DocumentTable> currentTables,
    required String tableId,
    required int columnIndex,
  }) {
    return _updateTable(currentTables, tableId, (table) {
      if (table.columns <= 1 ||
          columnIndex < 0 ||
          columnIndex >= table.columns) {
        return table;
      }

      final data = table.data.map((row) {
        final nextRow = List<String>.from(row);
        if (columnIndex < nextRow.length) {
          nextRow.removeAt(columnIndex);
        }
        return nextRow;
      }).toList();

      return table.copyWith(columns: table.columns - 1, data: data);
    });
  }

  List<DocumentTable> deleteTable({
    required List<DocumentTable> currentTables,
    required String tableId,
  }) {
    return currentTables.where((table) => table.id != tableId).toList();
  }

  List<DocumentTable> _updateTable(
    List<DocumentTable> tables,
    String tableId,
    DocumentTable Function(DocumentTable table) update,
  ) {
    return tables.map((table) {
      if (table.id != tableId) return table;
      return update(table);
    }).toList();
  }

  bool _hasCell(DocumentTable table, int row, int column) {
    return row >= 0 &&
        row < table.rows &&
        column >= 0 &&
        column < table.columns &&
        row < table.data.length &&
        column < table.data[row].length;
  }

  List<List<String>> _copyData(List<List<String>> data) {
    return data.map((row) => List<String>.from(row)).toList();
  }

  int _atLeastOne(int value) {
    return value < 1 ? 1 : value;
  }
}
