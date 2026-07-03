/// Handler for cell and range formatting operations

import 'package:ky_sheet/ky_sheet.dart';
import '../ky_sheet_mcp_server.dart';

class FormattingHandler {
  final KySheetMCPServer server;

  FormattingHandler(this.server);

  /// Apply formatting to a single cell
  Future<Map<String, dynamic>> formatCell(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final row = params['row'] as int?;
    final column = params['column'] as int?;
    final formatParams = params['format'] as Map<String, dynamic>?;

    if (sheetName == null || row == null || column == null || formatParams == null) {
      return {'success': false, 'error': 'sheet_name, row, column, and format are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      final cell = sheet.getCell(row, column) ?? sheet.createCell(row, column);
      
      final format = _parseFormat(formatParams);
      cell.format = format;

      return {
        'success': true,
        'address': '${_getColumnLetter(column)}$row',
        'format_applied': true,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to format cell: $e'};
    }
  }

  /// Apply formatting to a range of cells
  Future<Map<String, dynamic>> formatRange(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final startRow = params['start_row'] as int?;
    final startColumn = params['start_column'] as int?;
    final endRow = params['end_row'] as int?;
    final endColumn = params['end_column'] as int?;
    final formatParams = params['format'] as Map<String, dynamic>?;

    if (sheetName == null || startRow == null || startColumn == null ||
        endRow == null || endColumn == null || formatParams == null) {
      return {'success': false, 'error': 'All range and format parameters are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      final format = _parseFormat(formatParams);
      int cellsFormatted = 0;

      for (var r = startRow; r <= endRow; r++) {
        for (var c = startColumn; c <= endColumn; c++) {
          final cell = sheet.getCell(r, c) ?? sheet.createCell(r, c);
          cell.format = format.clone() as CellFormat?;
          cellsFormatted++;
        }
      }

      return {
        'success': true,
        'range': '${_getColumnLetter(startColumn)}$startRow:${_getColumnLetter(endColumn)}$endRow',
        'cells_formatted': cellsFormatted,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to format range: $e'};
    }
  }

  /// Merge a range of cells
  Future<Map<String, dynamic>> mergeCells(Map<String, dynamic> params) async {
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

      // Note: Actual merge implementation depends on ky_sheet API
      // This is a placeholder for the merge functionality
      final mergedRange = MergedRange(
        startRow: startRow,
        startColumn: startColumn,
        endRow: endRow,
        endColumn: endColumn,
      );
      
      sheet.mergedRanges.add(mergedRange);

      return {
        'success': true,
        'merged_range': '${_getColumnLetter(startColumn)}$startRow:${_getColumnLetter(endColumn)}$endRow',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to merge cells: $e'};
    }
  }

  /// Unmerge cells in a range
  Future<Map<String, dynamic>> unmergeCells(Map<String, dynamic> params) async {
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

      // Remove matching merged ranges
      sheet.mergedRanges.removeWhere((mr) =>
        mr.startRow == startRow &&
        mr.startColumn == startColumn &&
        mr.endRow == endRow &&
        mr.endColumn == endColumn
      );

      return {
        'success': true,
        'message': 'Cells unmerged successfully',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to unmerge cells: $e'};
    }
  }

  /// Set column width
  Future<Map<String, dynamic>> setColumnWidth(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final column = params['column'] as int?;
    final width = params['width'] as num?;

    if (sheetName == null || column == null || width == null) {
      return {'success': false, 'error': 'sheet_name, column, and width are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      sheet.setColumnWidth(column, width.toDouble());

      return {
        'success': true,
        'column': _getColumnLetter(column),
        'width': width,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to set column width: $e'};
    }
  }

  /// Set row height
  Future<Map<String, dynamic>> setRowHeight(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final row = params['row'] as int?;
    final height = params['height'] as num?;

    if (sheetName == null || row == null || height == null) {
      return {'success': false, 'error': 'sheet_name, row, and height are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      sheet.setRowHeight(row, height.toDouble());

      return {
        'success': true,
        'row': row,
        'height': height,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to set row height: $e'};
    }
  }

  /// Set border for a cell or range
  Future<Map<String, dynamic>> setBorder(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final startRow = params['start_row'] as int?;
    final startColumn = params['start_column'] as int?;
    final endRow = params['end_row'] as int?;
    final endColumn = params['end_column'] as int?;
    final borderParams = params['border'] as Map<String, dynamic>?;

    if (sheetName == null || startRow == null || startColumn == null ||
        borderParams == null) {
      return {'success': false, 'error': 'Required parameters missing'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      final actualEndRow = endRow ?? startRow;
      final actualEndColumn = endColumn ?? startColumn;

      final border = _parseBorder(borderParams);
      int cellsUpdated = 0;

      for (var r = startRow; r <= actualEndRow; r++) {
        for (var c = startColumn; c <= actualEndColumn; c++) {
          final cell = sheet.getCell(r, c) ?? sheet.createCell(r, c);
          final existingFormat = cell.format ?? CellFormat();
          cell.format = existingFormat.copyWith(border: border);
          cellsUpdated++;
        }
      }

      return {
        'success': true,
        'range': '${_getColumnLetter(startColumn)}$startRow:${_getColumnLetter(actualEndColumn)}$actualEndRow',
        'cells_updated': cellsUpdated,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to set border: $e'};
    }
  }

  /// Clear formatting from a cell or range
  Future<Map<String, dynamic>> clearFormatting(Map<String, dynamic> params) async {
    final workbook = server.getActiveWorkbook();
    if (workbook == null) {
      return {'success': false, 'error': 'No active workbook'};
    }

    final sheetName = params['sheet_name'] as String?;
    final row = params['row'] as int?;
    final column = params['column'] as int?;
    final endRow = params['end_row'] as int?;
    final endColumn = params['end_column'] as int?;

    if (sheetName == null || row == null || column == null) {
      return {'success': false, 'error': 'sheet_name, row, and column are required'};
    }

    try {
      final sheet = workbook.sheets.firstWhere(
        (s) => s.name == sheetName,
        orElse: () => throw Exception('Sheet not found'),
      );

      final actualEndRow = endRow ?? row;
      final actualEndColumn = endColumn ?? column;
      int cellsCleared = 0;

      for (var r = row; r <= actualEndRow; r++) {
        for (var c = column; c <= actualEndColumn; c++) {
          final cell = sheet.getCell(r, c);
          if (cell != null) {
            cell.format = null;
            cellsCleared++;
          }
        }
      }

      return {
        'success': true,
        'range': '${_getColumnLetter(column)}$row:${_getColumnLetter(actualEndColumn)}$actualEndRow',
        'cells_cleared': cellsCleared,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to clear formatting: $e'};
    }
  }

  // Helper methods
  CellFormat _parseFormat(Map<String, dynamic> params) {
    final format = CellFormat();

    if (params.containsKey('bold')) {
      format.bold = params['bold'] as bool? ?? false;
    }
    if (params.containsKey('italic')) {
      format.italic = params['italic'] as bool? ?? false;
    }
    if (params.containsKey('underline')) {
      format.underline = params['underline'] as bool? ?? false;
    }
    if (params.containsKey('font_size')) {
      format.fontSize = params['font_size'] as double?;
    }
    if (params.containsKey('font_family')) {
      format.fontFamily = params['font_family'] as String?;
    }
    if (params.containsKey('foreground_color')) {
      format.foregroundColor = _parseColor(params['foreground_color']);
    }
    if (params.containsKey('background_color')) {
      format.backgroundColor = _parseColor(params['background_color']);
    }
    if (params.containsKey('horizontal_alignment')) {
      format.horizontalAlignment = _parseHorizontalAlignment(params['horizontal_alignment']);
    }
    if (params.containsKey('vertical_alignment')) {
      format.verticalAlignment = _parseVerticalAlignment(params['vertical_alignment']);
    }
    if (params.containsKey('number_format')) {
      format.numberFormat = params['number_format'] as String?;
    }

    return format;
  }

  Border? _parseBorder(Map<String, dynamic> params) {
    if (params.isEmpty) return null;

    return Border(
      top: _parseBorderSide(params['top']),
      bottom: _parseBorderSide(params['bottom']),
      left: _parseBorderSide(params['left']),
      right: _parseBorderSide(params['right']),
    );
  }

  BorderSide? _parseBorderSide(dynamic param) {
    if (param == null) return null;
    
    if (param is Map<String, dynamic>) {
      return BorderSide(
        color: _parseColor(param['color']),
        width: (param['width'] as num?)?.toDouble() ?? 1.0,
        style: _parseBorderStyle(param['style']),
      );
    }
    
    return null;
  }

  Color? _parseColor(dynamic colorParam) {
    if (colorParam == null) return null;
    
    if (colorParam is String) {
      // Handle hex colors like "#FF0000" or "FF0000"
      if (colorParam.startsWith('#')) {
        colorParam = colorParam.substring(1);
      }
      if (colorParam.length == 6) {
        colorParam = 'FF' + colorParam;
      }
      return Color(int.parse(colorParam, radix: 16));
    }
    
    if (colorParam is int) {
      return Color(colorParam);
    }
    
    return null;
  }

  HorizontalAlignment? _parseHorizontalAlignment(String? value) {
    if (value == null) return null;
    
    switch (value.toLowerCase()) {
      case 'left': return HorizontalAlignment.left;
      case 'center': return HorizontalAlignment.center;
      case 'right': return HorizontalAlignment.right;
      case 'fill': return HorizontalAlignment.fill;
      case 'justify': return HorizontalAlignment.justify;
      case 'center_across_selection': return HorizontalAlignment.centerAcrossSelection;
      default: return null;
    }
  }

  VerticalAlignment? _parseVerticalAlignment(String? value) {
    if (value == null) return null;
    
    switch (value.toLowerCase()) {
      case 'top': return VerticalAlignment.top;
      case 'center': return VerticalAlignment.center;
      case 'bottom': return VerticalAlignment.bottom;
      case 'justify': return VerticalAlignment.justify;
      case 'distributed': return VerticalAlignment.distributed;
      default: return null;
    }
  }

  BorderStyle? _parseBorderStyle(String? value) {
    if (value == null) return null;
    
    switch (value.toLowerCase()) {
      case 'none': return BorderStyle.none;
      case 'thin': return BorderStyle.thin;
      case 'medium': return BorderStyle.medium;
      case 'thick': return BorderStyle.thick;
      case 'dotted': return BorderStyle.dotted;
      case 'dashed': return BorderStyle.dashed;
      case 'double': return BorderStyle.double;
      case 'hair': return BorderStyle.hair;
      case 'medium_dashed': return BorderStyle.mediumDashed;
      case 'dash_dot': return BorderStyle.dashDot;
      case 'medium_dash_dot': return BorderStyle.mediumDashDot;
      case 'dash_dot_dot': return BorderStyle.dashDotDot;
      case 'medium_dash_dot_dot': return BorderStyle.mediumDashDotDot;
      case 'slant_dash_dot': return BorderStyle.slantDashDot;
      default: return BorderStyle.thin;
    }
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
}
