/// Handler for spreadsheet operations (workbook, sheet, cell management)

import 'package:ky_sheet/ky_sheet.dart';
import '../ky_sheet_mcp_server.dart';

class SpreadsheetHandler {
  final KySheetMCPServer server;

  SpreadsheetHandler(this.server);

  /// Create a new workbook
  Future<Map<String, dynamic>> createWorkbook(Map<String, dynamic> params) async {
    final name = params['name'] as String? ?? 'Untitled';
    
    try {
      final workbook = Workbook();
      final id = server.generateWorkbookId();
      
      // Set initial sheet name if provided
      if (workbook.sheets.isNotEmpty) {
        workbook.sheets.first.name = name;
      }
      
      server.setActiveWorkbook(id, workbook);
      
      return {
        'success': true,
        'workbook_id': id,
        'name': name,
        'sheet_count': workbook.sheets.length,
        'message': 'Workbook created successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to create workbook: $e',
      };
    }
  }

  /// Create a new sheet in the active workbook
  Future<Map<String, dynamic>> createSheet(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final name = params['name'] as String? ?? 'Sheet${workbook.sheets.length + 1}';
    final index = params['index'] as int?;

    try {
      final sheet = Worksheet(name: name);
      
      if (index != null && index >= 0 && index <= workbook.sheets.length) {
        workbook.sheets.insert(index, sheet);
      } else {
        workbook.sheets.add(sheet);
      }

      return {
        'success': true,
        'sheet_name': name,
        'sheet_index': workbook.sheets.indexOf(sheet),
        'total_sheets': workbook.sheets.length,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to create sheet: $e'};
    }
  }

  /// Delete a sheet from the active workbook
  Future<Map<String, dynamic>> deleteSheet(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    if (sheetName == null) {
      return {'success': false, 'error': 'Sheet name is required'};
    }

    try {
      final sheetIndex = workbook.sheets.indexWhere((s) => s.name == sheetName);
      if (sheetIndex == -1) {
        return {'success': false, 'error': 'Sheet not found: $sheetName'};
      }

      if (workbook.sheets.length <= 1) {
        return {'success': false, 'error': 'Cannot delete the last sheet'};
      }

      workbook.sheets.removeAt(sheetIndex);

      return {
        'success': true,
        'message': 'Sheet deleted successfully',
        'remaining_sheets': workbook.sheets.length,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to delete sheet: $e'};
    }
  }

  /// Rename a sheet
  Future<Map<String, dynamic>> renameSheet(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final oldName = params['old_name'] as String?;
    final newName = params['new_name'] as String?;

    if (oldName == null || newName == null) {
      return {'success': false, 'error': 'Both old_name and new_name are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == oldName,
        orElse: () => throw Exception('Sheet not found'),
      );

      // Check if new name already exists
      if (workbook.sheets.any((s) => s.name == newName)) {
        return {'success': false, 'error': 'A sheet with this name already exists'};
      }

      sheet.name = newName;

      return {
        'success': true,
        'old_name': oldName,
        'new_name': newName,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to rename sheet: $e'};
    }
  }

  /// List all sheets in the active workbook
  Future<Map<String, dynamic>> listSheets(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheets = workbook.sheets.map((sheet) => {
      'name': sheet.name,
      'index': workbook.sheets.indexOf(sheet),
      'row_count': sheet.rowCount,
      'column_count': sheet.columnCount,
      'is_active': sheet == workbook.activeSheet,
    }).toList();

    return {
      'success': true,
      'sheets': sheets,
      'active_sheet': workbook.activeSheet?.name,
    };
  }

  /// Get the active sheet
  Future<Map<String, dynamic>> getActiveSheet(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheet = workbook.activeSheet;
    if (sheet == null) {
      return {'success': false, 'error': 'No active sheet'};
    }

    return {
      'success': true,
      'name': sheet.name,
      'index': workbook.sheets.indexOf(sheet),
      'row_count': sheet.rowCount,
      'column_count': sheet.columnCount,
    };
  }

  /// Set the active sheet
  Future<Map<String, dynamic>> setActiveSheet(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    if (sheetName == null) {
      return {'success': false, 'error': 'Sheet name is required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      workbook.activeSheet = sheet;

      return {
        'success': true,
        'active_sheet': sheet.name,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to set active sheet: $e'};
    }
  }

  /// Read value from a specific cell
  Future<Map<String, dynamic>> readCell(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final row = params['row'] as int?;
    final column = params['column'] as int?;

    if (sheetName == null || row == null || column == null) {
      return {'success': false, 'error': 'sheet_name, row, and column are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      final cell = sheet.getCell(row, column);
      final value = cell?.value;
      final formula = cell?.formula;
      final format = cell?.format;

      return {
        'success': true,
        'value': value,
        'formula': formula,
        'format': _serializeFormat(format),
        'row': row,
        'column': column,
        'address': _getColumnLetter(column) + row.toString(),
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to read cell: $e'};
    }
  }

  /// Write value to a specific cell
  Future<Map<String, dynamic>> writeCell(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final row = params['row'] as int?;
    final column = params['column'] as int?;
    final value = params['value'];
    final isFormula = params['is_formula'] as bool? ?? false;

    if (sheetName == null || row == null || column == null || value == null) {
      return {'success': false, 'error': 'sheet_name, row, column, and value are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      final cell = sheet.getCell(row, column) ?? sheet.createCell(row, column);
      
      if (isFormula) {
        cell.formula = value.toString();
      } else {
        cell.value = _parseValue(value);
      }

      return {
        'success': true,
        'address': _getColumnLetter(column) + row.toString(),
        'value': cell.value,
        'formula': cell.formula,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to write cell: $e'};
    }
  }

  /// Read values from a range of cells
  Future<Map<String, dynamic>> readRange(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final startRow = params['start_row'] as int?;
    final startColumn = params['start_column'] as int?;
    final endRow = params['end_row'] as int?;
    final endColumn = params['end_column'] as int?;

    if (sheetName == null || startRow == null || startColumn == null || 
        endRow == null || endColumn == null) {
      return {'success': false, 'error': 'All range parameters are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      final values = <List<dynamic>>[];
      for (var r = startRow; r <= endRow; r++) {
        final rowValues = <dynamic>[];
        for (var c = startColumn; c <= endColumn; c++) {
          final cell = sheet.getCell(r, c);
          rowValues.add(cell?.value);
        }
        values.add(rowValues);
      }

      return {
        'success': true,
        'range': '${_getColumnLetter(startColumn)}$startRow:${_getColumnLetter(endColumn)}$endRow',
        'rows': endRow - startRow + 1,
        'columns': endColumn - startColumn + 1,
        'values': values,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to read range: $e'};
    }
  }

  /// Write values to a range of cells
  Future<Map<String, dynamic>> writeRange(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final startRow = params['start_row'] as int?;
    final startColumn = params['start_column'] as int?;
    final values = params['values'] as List?;

    if (sheetName == null || startRow == null || startColumn == null || values == null) {
      return {'success': false, 'error': 'sheet_name, start_row, start_column, and values are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      int rowsWritten = 0;
      int colsWritten = 0;

      for (var i = 0; i < values.length; i++) {
        final rowValues = values[i];
        if (rowValues is List) {
          for (var j = 0; j < rowValues.length; j++) {
            final cell = sheet.getCell(startRow + i, startColumn + j) 
                ?? sheet.createCell(startRow + i, startColumn + j);
            cell.value = _parseValue(rowValues[j]);
          }
          if (rowValues.length > colsWritten) colsWritten = rowValues.length;
          rowsWritten++;
        }
      }

      return {
        'success': true,
        'range': '${_getColumnLetter(startColumn)}$startRow:${_getColumnLetter(startColumn + colsWritten - 1)}${startRow + rowsWritten - 1}',
        'rows_written': rowsWritten,
        'columns_written': colsWritten,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to write range: $e'};
    }
  }

  // Helper methods
  dynamic _parseValue(dynamic value) {
    if (value is String) {
      // Try to parse as number
      final numValue = num.tryParse(value);
      if (numValue != null) return numValue;
      
      // Try to parse as boolean
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return value;
  }

  String _getColumnLetter(int column) {
    if (column < 1) throw ArgumentError('Column must be >= 1');
    
    String result = '';
    int col = column - 1;
    
    while (col >= 0) {
      result = String.fromCharCode((col % 26) + 65) + result;
      col = (col ~/ 26) - 1;
    }
    
    return result;
  }

  Map<String, dynamic>? _serializeFormat(CellFormat? format) {
    if (format == null) return null;
    
    return {
      'bold': format.bold,
      'italic': format.italic,
      'underline': format.underline,
      'font_size': format.fontSize,
      'font_family': format.fontFamily,
      'foreground_color': format.foregroundColor?.toString(),
      'background_color': format.backgroundColor?.toString(),
      'horizontal_alignment': format.horizontalAlignment?.toString(),
      'vertical_alignment': format.verticalAlignment?.toString(),
      'number_format': format.numberFormat,
    };
  }
}
